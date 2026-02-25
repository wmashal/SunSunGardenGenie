import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/design_result.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<DesignResult> generateDesign({
    required Uint8List imageBytes,
    required String prompt,
    required List<Product> selectedProducts,
    required bool isCreative,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.generateDesignUrl),
      );

      // Add form fields
      final safePrompt = prompt.trim().isEmpty
          ? 'A beautiful landscape design'
          : prompt;
      request.fields['prompt'] = safePrompt;
      request.fields['selected_products'] = jsonEncode(
        selectedProducts.map((p) => p.toJson()).toList(),
      );
      request.fields['is_creative'] = isCreative.toString();

      // Add image file
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'yard.jpg',
      ));

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

      return DesignResult.fromJson(result);
    } catch (e) {
      return DesignResult(
        status: 'error',
        imageUrls: [],
        summary: '',
        errorMessage: 'Network error: $e',
      );
    }
  }
}
