import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://10.0.2.2:54321'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
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
        primaryColor: const Color(0xFF1B3F22),
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
      ),
      home: const ARCameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// SCREEN 1: AR Camera
// ==========================================
class ARCameraScreen extends StatelessWidget {
  const ARCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Center(child: Icon(Icons.circle, color: Colors.redAccent, size: 8)),
              ),
            ),
            Positioned(
              top: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Area: 14.5 m²', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('3 Points', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReviewPromptScreen())),
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 4)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tap to capture yard', style: TextStyle(color: Colors.white, fontSize: 12)),
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
// SCREEN 2: Review & Prompt (WITH CHECKBOX)
// ==========================================
class ReviewPromptScreen extends StatefulWidget {
  const ReviewPromptScreen({super.key});
  @override
  State<ReviewPromptScreen> createState() => _ReviewPromptScreenState();
}

class _ReviewPromptScreenState extends State<ReviewPromptScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isCreativeMode = false; // <-- The new Checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3F22)), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300, width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('[Captured Yard Image]', style: TextStyle(color: Colors.white54))),
            ),
            const SizedBox(height: 30),
            const Text('What is your vision?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController, maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., A modern zen garden.',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 10),

            // THE NEW CREATIVE MODE CHECKBOX
            Row(
              children: [
                Checkbox(
                  value: _isCreativeMode,
                  activeColor: const Color(0xFF1B3F22),
                  onChanged: (bool? value) {
                    setState(() {
                      _isCreativeMode = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Enable Creative Mode (Allows AI freedom to add complementary decor)',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductSelectionScreen(
                  userPrompt: _promptController.text,
                  isCreative: _isCreativeMode // <-- Pass it to the next screen
              ))),
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(color: const Color(0xFF1B3F22), borderRadius: BorderRadius.circular(28)),
                child: const Center(child: Text('Next: Choose Plants', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 3: Product Selection
// ==========================================
class ProductSelectionScreen extends StatefulWidget {
  final String userPrompt;
  final bool isCreative; // <-- Receive the Checkbox state

  const ProductSelectionScreen({super.key, required this.userPrompt, required this.isCreative});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  final Set<String> _selectedProductIds = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await Supabase.instance.client.from('products').select();
      setState(() { _allProducts = data; _filteredProducts = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final name = (p['name'] ?? '').toLowerCase();
        final desc = (p['description'] ?? '').toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  Future<void> _generateSimulation() async {
    if (_selectedProductIds.isEmpty) return;
    setState(() => _isGenerating = true);

    final selectedItems = _allProducts.where((p) => _selectedProductIds.contains(p['id'].toString())).toList();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:8000/generate-design'));
      final safePrompt = widget.userPrompt.trim().isEmpty ? 'A beautiful landscape design' : widget.userPrompt;
      request.fields['prompt'] = safePrompt;
      request.fields['selected_products'] = jsonEncode(selectedItems);
      request.fields['is_creative'] = widget.isCreative.toString();

      ByteData byteData = await rootBundle.load('assets/backyard.jpg');
      request.files.add(http.MultipartFile.fromBytes('image', byteData.buffer.asUint8List(), filename: 'yard.jpg'));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

      if (!mounted) return; // Ensure widget is still alive

      if (response.statusCode == 200 && result['status'] == 'success') {
        List<String> images = List<String>.from(result['result_image_urls'] ?? []);

        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SimulationResultScreen(
            imageUrls: images,
            summary: result['summary'] ?? "Design generated successfully.",
          ),
        ));
      } else {
        // ADDED ERROR POPUP: Stop silent failures in the app!
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Generation Failed: ${result['message'] ?? 'Unknown API Error'}'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            )
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent)
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Select Products', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))), backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3F22)), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search inventory...', prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.only(top: 12)))),
            const SizedBox(height: 20),
            Text('Available Inventory (${_filteredProducts.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 20), itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final String id = product['id'].toString();
                  final bool isSelected = _selectedProductIds.contains(id);
                  return GestureDetector(
                    onTap: () => setState(() => isSelected ? _selectedProductIds.remove(id) : _selectedProductIds.add(id)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300, width: isSelected ? 2 : 1)),
                      child: Row(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product['thumbnail_url'] ?? '', width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.local_florist, color: Color(0xFF4CAF50)))),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(product['description'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 2)])),
                        Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFF4CAF50) : Colors.grey, size: 28),
                      ]),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: _isGenerating ? null : _generateSimulation,
              child: Container(width: double.infinity, height: 56, margin: const EdgeInsets.only(bottom: 30), decoration: BoxDecoration(color: _isGenerating ? Colors.grey : const Color(0xFF1B3F22), borderRadius: BorderRadius.circular(28)), child: Center(child: _isGenerating ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Generate 3 Variations (${_selectedProductIds.length})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 4: The Final Simulation Result (SWIPEABLE GALLERY)
// ==========================================
class SimulationResultScreen extends StatefulWidget {
  final List<String> imageUrls;
  final String summary;

  const SimulationResultScreen({super.key, required this.imageUrls, required this.summary});

  @override
  State<SimulationResultScreen> createState() => _SimulationResultScreenState();
}

class _SimulationResultScreenState extends State<SimulationResultScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)), title: const Text('Your AI Designs', style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: widget.imageUrls.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      child: Image.network(
                        widget.imageUrls[index],
                        width: double.infinity, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, color: Colors.grey, size: 80), Text('Preview unavailable', style: TextStyle(color: Colors.grey))])),
                      ),
                    );
                  },
                ),
                if (widget.imageUrls.length > 1)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.imageUrls.length, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _currentIndex == index ? Colors.white : Colors.white54),
                      )),
                    ),
                  )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Quantities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3F22))),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(widget.summary, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: const Color(0xFF1B3F22), borderRadius: BorderRadius.circular(28)), child: const Center(child: Text('Add Items to Cart', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}