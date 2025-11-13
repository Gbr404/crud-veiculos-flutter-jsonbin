import 'package:flutter/material.dart';
import '../services/brand_service.dart';
import 'dart:math';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final _service = BrandService();
  late Future<List<Map<String, dynamic>>> _brands;
  final TextEditingController _nameController = TextEditingController();
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _brands = _service.getBrands();
  }

  Future<void> _refresh() async {
    setState(() {
      _brands = _service.getBrands();
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    try {
      final currentBrands = await _service.getBrands();
      final nextId = currentBrands.isEmpty
          ? 1
          : currentBrands
                  .map((b) => int.tryParse(b['id'].toString()) ?? 0)
                  .fold(0, max) +
              1;

      final data = {
        'id': _editingId ?? nextId.toString(),
        'nome': _nameController.text.trim(),
      };

      if (_editingId == null) {
        await _service.addBrand(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marca adicionada com sucesso!')),
        );
      } else {
        await _service.updateBrand(_editingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marca atualizada com sucesso!')),
        );
      }

      _nameController.clear();
      _editingId = null;
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar marca: $e')),
      );
    }
  }

  void _editBrand(Map<String, dynamic> brand) {
    setState(() {
      _editingId = brand['id'].toString();
      _nameController.text = brand['nome'] ?? '';
    });
  }

  Future<void> _deleteBrand(String id) async {
    try {
      await _service.deleteBrand(id);
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marca excluída com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir marca: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Marcas'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    _editingId == null ? 'Adicionar' : 'Salvar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _brands,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar marcas: ${snapshot.error}'),
                    );
                  }

                  final brands = snapshot.data ?? [];
                  if (brands.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma marca cadastrada.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      itemCount: brands.length,
                      itemBuilder: (context, i) {
                        final b = brands[i];
                        return Card(
                          child: ListTile(
                            title: Text(b['nome'] ?? 'Sem nome'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editBrand(b),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteBrand(b['id'].toString()),
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
            ),
          ],
        ),
      ),
    );
  }
}
