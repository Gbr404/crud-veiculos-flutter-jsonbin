import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import 'add_vehicle_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _service = VehicleService();
  late Future<List<Map<String, dynamic>>> _vehicles;

  @override
  void initState() {
    super.initState();
    _vehicles = _service.getVehicles();
  }

  Future<void> _refresh() async {
    setState(() {
      _vehicles = _service.getVehicles();
    });
  }

  Future<void> _delete(String id) async {
    await _service.deleteVehicle(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículos'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _vehicles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar veículos.'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Nenhum veículo cadastrado.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, i) {
                final v = data[i];
                final imageUrl = v['imagem']; // Agora é uma URL

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: imageUrl != null && imageUrl.toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 30,
                                  child: Icon(Icons.broken_image, color: Colors.white),
                                );
                              },
                            ),
                          )
                        : const CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 30,
                            child: Icon(Icons.directions_car, color: Colors.white),
                          ),
                    title: Text('${v['tipoVeiculo']} - ${v['marca']}'),
                    subtitle: Text(
                      'Proprietário: ${v['proprietario']} | Ano: ${v['ano']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddVehicleScreen(
                                  id: v['id'].toString(),
                                  existingData: v,
                                ),
                              ),
                            );
                            if (result == true) _refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(v['id'].toString()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
