import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SimulationResultScreen extends StatefulWidget {
  final String imageUrl;
  final String summary;
  final List<Product> selectedProducts;
  final String originalPrompt;
  final List<int> imageBytes;
  final double yardArea;

  const SimulationResultScreen({
    super.key,
    required this.imageUrl,
    required this.summary,
    required this.selectedProducts,
    required this.originalPrompt,
    required this.imageBytes,
    this.yardArea = 0,
  });

  @override
  State<SimulationResultScreen> createState() => _SimulationResultScreenState();
}

class _SimulationResultScreenState extends State<SimulationResultScreen> {
  late String _currentImageUrl;
  late String _currentSummary;
  bool _isDownloading = false;
  bool _isRegenerating = false;
  final TextEditingController _suggestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
    _currentSummary = widget.summary;
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _downloadImage() async {
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(_currentImageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'garden_design_$timestamp.jpg';
        await File('${directory.path}/$fileName').writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Saved: $fileName')),
              ],
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _regenerate() async {
    final suggestion = _suggestionController.text.trim();
    if (suggestion.isEmpty) return;

    setState(() => _isRegenerating = true);
    FocusScope.of(context).unfocus();

    try {
      final result = await ApiService.regenerateDesign(
        imageBytes: Uint8List.fromList(widget.imageBytes),
        prompt: widget.originalPrompt,
        selectedProducts: widget.selectedProducts,
        suggestion: suggestion,
        yardArea: widget.yardArea,
      );

      if (!mounted) return;

      if (result.isSuccess && result.imageUrls.isNotEmpty) {
        setState(() {
          _currentImageUrl = result.imageUrls.first;
          _currentSummary = result.summary;
          _suggestionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Regeneration failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text('Your AI Design', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadImage,
            tooltip: 'Save image',
          ),
        ],
      ),
      body: Column(
        children: [
          // Design image
          Expanded(
            child: _buildImage(),
          ),
          // Bottom panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: Image.network(
              _currentImageUrl,
              fit: BoxFit.contain,
              key: ValueKey(_currentImageUrl),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 80),
                    SizedBox(height: 16),
                    Text('Preview unavailable', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Regenerating overlay
        if (_isRegenerating)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Applying changes...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantities summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Quantities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${widget.selectedProducts.length} products',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 72),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    _currentSummary,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Suggestion input
              const Text(
                'Suggest a change',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _suggestionController,
                      enabled: !_isRegenerating,
                      decoration: InputDecoration(
                        hintText: 'e.g. Move the sofa closer to the fence',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _regenerate(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isRegenerating ? null : _regenerate,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isRegenerating ? Colors.grey.shade300 : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isRegenerating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Add to cart
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart feature coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('Add to Cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
