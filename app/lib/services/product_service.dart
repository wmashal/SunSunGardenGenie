import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final _client = Supabase.instance.client;

  static Future<List<Product>> fetchProducts() async {
    try {
      final data = await _client.from('products').select();
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      final data = await _client
          .from('products')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%');
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
}
