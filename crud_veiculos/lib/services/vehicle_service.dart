import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class VehicleService {
  // 🔑 Configurações principais
  final String binId = '690a299c43b1c97be9988fb9'; // <-- preencha com o seu ID do JSONBin
  final String apiKey = r"$2a$10$vxGWPb.pwKeZe4bv/Sydz.FUZV7xiYrVyDL58CymR9WwbrjJ.8K3C"; 
  final String baseUrl = 'https://api.jsonbin.io/v3/b';


  // ✅ GET - Lista todos os veículos
  Future<List<Map<String, dynamic>>> getVehicles() async {
    final url = Uri.parse('$baseUrl/$binId/latest');
    final response = await http.get(
      url,
      headers: {
        'X-Master-Key': apiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      var record = decoded['record'];

      // 🔹 Trata caso de aninhamento indevido
      if (record is Map && record.containsKey('record')) {
        record = record['record'];
      }

      if (record == null) return [];

      if (record is List) {
        return record
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (record is Map) {
        return [Map<String, dynamic>.from(record)];
      }

      return [];
    } else {
      throw Exception('Erro ao buscar veículos: ${response.statusCode}');
    }
  }

  // ✅ POST - Adiciona um novo veículo
  Future<void> addVehicle(Map<String, dynamic> newVehicle) async {
    final vehicles = await getVehicles();

    // 🔹 Calcula o próximo ID de forma segura
    final nextId = vehicles.isEmpty
        ? 1
        : vehicles
                .map((v) => v['id'])
                .whereType<int>()
                .fold(0, max) +
            1;

    newVehicle['id'] = nextId;
    vehicles.add(newVehicle);

    await _updateVehicles(vehicles);
  }

  // ✅ PUT - Atualiza um veículo existente
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    final vehicles = await getVehicles();
    final index = vehicles.indexWhere((v) => v['id'].toString() == id);

    if (index == -1) throw Exception('Veículo não encontrado');

    vehicles[index] = {...vehicles[index], ...data};

    await _updateVehicles(vehicles);
  }

  // ✅ DELETE - Remove um veículo pelo ID
  Future<void> deleteVehicle(String id) async {
    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v['id'].toString() == id);

    await _updateVehicles(vehicles);
  }

  // 🔧 Função interna - Envia a lista atualizada ao JSONBin
  Future<void> _updateVehicles(List<Map<String, dynamic>> vehicles) async {
    final url = Uri.parse('$baseUrl/$binId');
    final response = await http.put(
      url,
      headers: {
        'X-Master-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({'record': vehicles}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao atualizar dados: ${response.statusCode}');
    }
  }
}
