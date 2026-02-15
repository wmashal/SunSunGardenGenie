import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase.
  await Supabase.initialize(
    url: 'http://10.0.2.2:54321',
    anonKey: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  runApp(const SunSunGardenApp());
}

class SunSunGardenApp extends StatelessWidget {
  const SunSunGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SunSun Garden Genie',
      theme: ThemeData(
        primaryColor: const Color(0xFF1B3F22), // Deep Green
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
      ),
      // We now start the app at the Camera Screen
      home: const ARCameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// SCREEN 1: AR Camera (Measurement)
// ==========================================
class ARCameraScreen extends StatelessWidget {
  const ARCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D), // Dark background mimicking camera
      body: SafeArea(
        child: Stack(
          children: [
            // Fake Camera Reticle
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid), // In a real app, use dashed border
                ),
                child: const Center(
                  child: Icon(Icons.circle, color: Colors.redAccent, size: 8),
                ),
              ),
            ),

            // Top HUD (Measurement Overlay)
            Positioned(
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
                  children: const [
                    Text('Area: 14.5 m²', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('3 Points', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14)),
                  ],
                ),
              ),
            ),

            // Bottom Capture Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to Screen 2
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReviewPromptScreen()),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tap to add point', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 2: Review & Prompt
// ==========================================
class ReviewPromptScreen extends StatefulWidget {
  const ReviewPromptScreen({super.key});

  @override
  State<ReviewPromptScreen> createState() => _ReviewPromptScreenState();
}

class _ReviewPromptScreenState extends State<ReviewPromptScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3F22)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Captured Image View
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(child: Text('[Captured Yard Image]', style: TextStyle(color: Colors.white54))),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Area: 14.5 m²', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context), // Go back to camera
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                        child: const Text('⟲ Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Prompt Box
            const Text(
              'What is your vision?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., A modern zen garden with lavender...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Next Button
            GestureDetector(
              onTap: () {
                // Navigate to Screen 3
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3F22),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text('Next: Choose Plants', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 3: Product Selection (From Database)
// ==========================================
class ProductSelectionScreen extends StatefulWidget {
  // In a full app, you would pass the image and prompt from the previous screen here.
  // For the POC, we will accept them as optional parameters.
  final String userPrompt;
  const ProductSelectionScreen({super.key, this.userPrompt = "A beautiful modern garden"});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isGenerating = false; // Tracks the AI processing state

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client.from('products').select().order('created_at');
      setState(() {
        _products = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => _isLoading = false);
    }
  }

  // --- THE SENIOR MIDDLEWARE CONNECTION ---
  Future<void> _generateSimulation() async {
    setState(() => _isGenerating = true);

    try {
      var uri = Uri.parse('http://10.0.2.2:8000/generate-design');
      var request = http.MultipartRequest('POST', uri);

      request.fields['prompt'] = widget.userPrompt;
      request.fields['selected_products'] = jsonEncode(_products);

      // --- THE NEW IMAGE LOGIC ---
      // Load the real backyard photo from assets and convert to bytes
      ByteData byteData = await rootBundle.load('assets/backyard.jpg');
      List<int> imageData = byteData.buffer.asUint8List();

      // Attach the real image bytes to the request
      request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: 'yard_photo.jpg'
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResult = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonResult['status'] == 'success') {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SimulationResultScreen(imageUrl: jsonResult['result_image_url']),
        ));
      } else {
        debugPrint("API Error: $responseData");
      }
    } catch (e) {
      debugPrint("Network Error: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Products', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3F22)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: const TextField(
                decoration: InputDecoration(hintText: 'Search inventory...', prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.only(top: 12)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Available Inventory (${_products.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildProductCard(product);
                },
              ),
            ),

            // The Generation Button
            GestureDetector(
              onTap: _isGenerating ? null : _generateSimulation,
              child: Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                    color: _isGenerating ? Colors.grey : const Color(0xFF1B3F22),
                    borderRadius: BorderRadius.circular(28)
                ),
                child: Center(
                  child: _isGenerating
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Generate AI Simulation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4CAF50))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFE8F5E9),
              child: Image.network(
                product['thumbnail_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_florist, color: Color(0xFF4CAF50), size: 30),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Size: ${product['dimensions']} | Color: ${product['color']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(product['description'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 4: The Final Simulation Result
// ==========================================
class SimulationResultScreen extends StatelessWidget {
  final String imageUrl;

  const SimulationResultScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), // Returns to Camera
        ),
        title: const Text('Your AI Design', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                // The Senior Fix: Never let a bad network link crash the app
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey, size: 80),
                      SizedBox(height: 10),
                      Text('Image generation preview unavailable.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stunning, right?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
                  const SizedBox(height: 10),
                  const Text('This design features your Granite Pavers and Japanese Maple perfectly integrated into the space.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(color: const Color(0xFF1B3F22), borderRadius: BorderRadius.circular(28)),
                    child: const Center(child: Text('Add Items to Cart', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}