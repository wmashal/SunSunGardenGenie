import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'product_selection_screen.dart';

class ReviewPromptScreen extends StatefulWidget {
  final Uint8List capturedImageBytes;
  final String capturedImagePath;
  final List<Offset> placedPoints;
  final double calculatedArea;

  const ReviewPromptScreen({
    super.key,
    required this.capturedImageBytes,
    required this.capturedImagePath,
    required this.placedPoints,
    required this.calculatedArea,
  });

  @override
  State<ReviewPromptScreen> createState() => _ReviewPromptScreenState();
}

class _ReviewPromptScreenState extends State<ReviewPromptScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isCreativeMode = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _navigateToProductSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelectionScreen(
          userPrompt: _promptController.text,
          isCreative: _isCreativeMode,
          capturedImageBytes: widget.capturedImageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review & Vision',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Captured image preview
            _buildImagePreview(),
            const SizedBox(height: 10),

            // Area info
            _buildAreaInfo(),
            const SizedBox(height: 30),

            // Vision prompt
            _buildVisionInput(),
            const SizedBox(height: 15),

            // Creative mode toggle
            _buildCreativeModeToggle(),
            const SizedBox(height: 30),

            // Next button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.memory(
            widget.capturedImageBytes,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.placedPoints.length} points marked',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.square_foot, color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Area',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                '${widget.calculatedArea.toStringAsFixed(1)} m²',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your vision?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _promptController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g., A modern zen garden with minimalist design...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeModeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isCreativeMode ? AppColors.accent.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCreativeMode ? AppColors.accent : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isCreativeMode,
            activeColor: AppColors.primary,
            onChanged: (bool? value) {
              setState(() => _isCreativeMode = value ?? false);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Creative Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isCreativeMode
                      ? 'AI can add complementary elements (lighting, pathways, plants)'
                      : 'AI will strictly use only selected products',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _isCreativeMode ? Icons.auto_awesome : Icons.lock,
            color: _isCreativeMode ? AppColors.accent : Colors.grey,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _navigateToProductSelection,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next: Choose Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
