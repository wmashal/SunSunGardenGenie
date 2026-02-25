import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import 'review_prompt_screen.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  // Points placed by user for area measurement
  final List<Offset> _placedPoints = [];
  double _calculatedArea = 0.0;

  // Test image mode
  bool _useTestImageMode = false;
  Uint8List? _testImageBytes;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _errorMessage = 'No cameras available');
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // Calculate polygon area from placed points (simplified - assumes flat ground)
  void _calculateArea() {
    if (_placedPoints.length < 3) {
      setState(() => _calculatedArea = 0.0);
      return;
    }

    // Shoelace formula for polygon area
    double area = 0.0;
    int n = _placedPoints.length;
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += _placedPoints[i].dx * _placedPoints[j].dy;
      area -= _placedPoints[j].dx * _placedPoints[i].dy;
    }
    area = area.abs() / 2.0;

    // Convert pixel area to approximate m² (rough estimation for POC)
    // This is a simplified calculation - real AR would use depth sensing
    double screenArea = MediaQuery.of(context).size.width * MediaQuery.of(context).size.height;
    double estimatedRealArea = (area / screenArea) * 50; // Assume screen covers ~50m² at typical distance

    setState(() => _calculatedArea = estimatedRealArea);
  }

  void _onTapToPlacePoint(TapDownDetails details) {
    if (_placedPoints.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 points allowed')),
      );
      return;
    }

    setState(() {
      _placedPoints.add(details.localPosition);
    });
    _calculateArea();
  }

  void _undoLastPoint() {
    if (_placedPoints.isNotEmpty) {
      setState(() {
        _placedPoints.removeLast();
      });
      _calculateArea();
    }
  }

  void _clearAllPoints() {
    setState(() {
      _placedPoints.clear();
      _calculatedArea = 0.0;
    });
  }

  Future<void> _captureAndProceed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPromptScreen(
            capturedImageBytes: imageBytes,
            capturedImagePath: imageFile.path,
            placedPoints: List.from(_placedPoints),
            calculatedArea: _calculatedArea,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // Use test image (backyard.jpg) for simulator/emulator testing
  Future<void> _useTestImage() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/backyard.jpg');
      final Uint8List imageBytes = byteData.buffer.asUint8List();

      setState(() {
        _testImageBytes = imageBytes;
        _useTestImageMode = true;
        _placedPoints.clear();
        _calculatedArea = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load test image: $e')),
      );
    }
  }

  // Switch back to camera mode
  void _switchToCamera() {
    setState(() {
      _useTestImageMode = false;
      _testImageBytes = null;
      _placedPoints.clear();
      _calculatedArea = 0.0;
    });
  }

  // Proceed to next screen with current image (camera capture or test image)
  Future<void> _proceedToReview() async {
    if (_useTestImageMode && _testImageBytes != null) {
      // Use test image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPromptScreen(
            capturedImageBytes: _testImageBytes!,
            capturedImagePath: 'assets/backyard.jpg',
            placedPoints: List.from(_placedPoints),
            calculatedArea: _calculatedArea > 0 ? _calculatedArea : 14.5,
          ),
        ),
      );
    } else {
      // Capture from camera
      await _captureAndProceed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview, Test Image, or Error/Loading State
            if (_useTestImageMode && _testImageBytes != null)
              _buildTestImagePreview()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (!_isCameraInitialized)
              _buildLoadingState()
            else
              _buildCameraPreview(),

            // Top info bar
            _buildTopInfoBar(),

            // Point controls (undo/clear)
            if (_placedPoints.isNotEmpty) _buildPointControls(),

            // Capture button
            _buildCaptureButton(),

            // Instructions
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 60),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onTapDown: _onTapToPlacePoint,
      child: Stack(
        children: [
          // Camera feed
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
          // Draw placed points and connecting lines
          CustomPaint(
            size: Size.infinite,
            painter: PointsPainter(points: _placedPoints),
          ),
          // Crosshair in center
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white54, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestImagePreview() {
    return GestureDetector(
      onTapDown: _onTapToPlacePoint,
      child: Stack(
        children: [
          // Test image as background (maintain aspect ratio)
          SizedBox.expand(
            child: Container(
              color: Colors.black,
              child: Image.memory(
                _testImageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Draw placed points and connecting lines
          CustomPaint(
            size: Size.infinite,
            painter: PointsPainter(points: _placedPoints),
          ),
          // Test mode indicator
          Positioned(
            top: 70,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Test Image Mode',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Area: ${_calculatedArea.toStringAsFixed(1)} m²',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${_placedPoints.length} Points',
              style: TextStyle(
                color: _placedPoints.length >= 3 ? AppColors.accent : Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointControls() {
    return Positioned(
      top: 90,
      right: 20,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.undo,
            onTap: _undoLastPoint,
            tooltip: 'Undo last point',
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: Icons.clear_all,
            onTap: _clearAllPoints,
            tooltip: 'Clear all points',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Toggle button: Use Test Image / Use Camera
              GestureDetector(
                onTap: _isCapturing ? null : (_useTestImageMode ? _switchToCamera : _useTestImage),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _useTestImageMode ? Colors.orange : Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _useTestImageMode ? Icons.videocam : Icons.image,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              // Main capture/proceed button
              GestureDetector(
                onTap: _isCapturing ? null : _proceedToReview,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isCapturing ? Colors.grey : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 4),
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      : Icon(
                          _useTestImageMode ? Icons.check : Icons.camera_alt,
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 80), // Balance spacing
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    String instruction;
    if (_placedPoints.isEmpty) {
      instruction = 'Tap on the ground to place corner points';
    } else if (_placedPoints.length < 3) {
      instruction = 'Place at least 3 points to define area';
    } else {
      instruction = _useTestImageMode ? 'Tap ✓ to continue' : 'Tap capture when ready';
    }

    String modeHint = _useTestImageMode
        ? '🎥 Tap to switch to camera'
        : '🖼️ Tap to use test image';

    return Positioned(
      bottom: 140,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Text(
            instruction,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            modeHint,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw points and connecting lines
class PointsPainter extends CustomPainter {
  final List<Offset> points;

  PointsPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final pointPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.accent.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw filled polygon if 3+ points
    if (points.length >= 3) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, linePaint);
    } else if (points.length == 2) {
      // Draw line between 2 points
      canvas.drawLine(points[0], points[1], linePaint);
    }

    // Draw points
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 8, pointPaint);
      // Draw point number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - 4, points[i].dy - 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PointsPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
