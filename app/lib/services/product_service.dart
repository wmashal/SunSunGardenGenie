import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../utils/constants.dart';

class ProductService {
  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.productsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      final uri = Uri.parse(ApiConfig.productsUrl)
          .replace(queryParameters: {'search': query});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
}
