import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class BrandService {
  final String binId = '690a299c43b1c97be9988fb9';
  final String apiKey =
      r"$2a$10$vxGWPb.pwKeZe4bv/Sydz.FUZV7xiYrVyDL58CymR9WwbrjJ.8K3C";
  final String baseUrl = 'https://api.jsonbin.io/v3/b';

  Future<List<Map<String, dynamic>>> getBrands() async {
    final url = Uri.parse('$baseUrl/$binId/latest');
    final response = await http.get(
      url,
      headers: {'X-Master-Key': apiKey, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      var record = decoded['record'];

      if (record == null) return [];

      if (record is Map && record.containsKey('brands')) {
        final brands = record['brands'];
        if (brands is List) {
          return brands.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      return [];
    } else {
      throw Exception('Erro ao buscar marcas: ${response.statusCode}');
    }
  }

  Future<void> addBrand(Map<String, dynamic> newBrand) async {
    final brands = await getBrands();

    final nextId = brands.isEmpty
        ? 1
        : brands
                .map((b) => int.tryParse(b['id'].toString()) ?? 0)
                .fold(0, max) +
            1;

    final nome = (newBrand['name'] ?? '').toString().trim().toLowerCase();
    final exists = brands.any(
      (b) => (b['name'] ?? '').toString().trim().toLowerCase() == nome,
    );
    if (exists) throw Exception('Marca já cadastrada.');

    newBrand['id'] = nextId;
    brands.add(newBrand);

    await _updateRecord({'brands': brands});
  }

  Future<void> updateBrand(String id, Map<String, dynamic> updatedBrand) async {
    final brands = await getBrands();
    final index = brands.indexWhere((b) => b['id'].toString() == id);
    if (index == -1) throw Exception('Marca não encontrada');
    brands[index] = {...brands[index], ...updatedBrand};
    await _updateRecord({'brands': brands});
  }

  Future<void> deleteBrand(String id) async {
    final brands = await getBrands();
    brands.removeWhere((b) => b['id'].toString() == id);
    await _updateRecord({'brands': brands});
  }

  Future<void> _updateRecord(Map<String, dynamic> newData) async {
    final url = Uri.parse('$baseUrl/$binId');
    final response = await http.put(
      url,
      headers: {
        'X-Master-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode(newData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao atualizar bin: ${response.statusCode}');
    }
  }
}
