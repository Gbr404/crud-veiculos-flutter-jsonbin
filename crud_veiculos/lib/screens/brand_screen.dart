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
  String? _editingId; // Armazena o ID da marca em edição

  @override
  void initState() {
    super.initState();
    _brands = _service.getBrands();
  }

  // Recarrega a lista de marcas
  Future<void> _refresh() async {
    setState(() {
      _brands = _service.getBrands();
    });
  }

  // Abre a caixa de diálogo para Adicionar ou Editar
  void _openSaveDialog({Map<String, dynamic>? brand}) {
    // Se for edição, pré-preenche os campos
    _editingId = brand?['id']?.toString();
    _nameController.text = brand?['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingId == null ? 'Adicionar Nova Marca' : 'Editar Marca'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome da Marca',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _editingId = null;
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _save(),
            child: Text(_editingId == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  // Lógica de Salvar (Adicionar ou Atualizar)
  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da marca não pode ser vazio.')),
      );
      return;
    }

    try {
      final name = _nameController.text.trim();
      final data = {
        // Usamos 'name' conforme a sua estrutura JSON
        'name': name,
      };

      if (_editingId == null) {
        // Se estiver adicionando, o BrandService cuida do ID sequencial.
        await _service.addBrand(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marca "$name" adicionada com sucesso!')),
        );
      } else {
        // Se estiver editando, envia o ID para o service
        await _service.updateBrand(_editingId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marca "$name" atualizada com sucesso!')),
        );
      }

      Navigator.pop(context); // Fecha o Dialog
      _nameController.clear();
      _editingId = null;
      await _refresh(); // Recarrega a lista após salvar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar marca: $e')),
      );
    }
  }

  // Lógica de Deletar
  Future<void> _deleteBrand(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a marca "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteBrand(id);
        await _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marca "$name" excluída com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir marca: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏷️ Gerenciar Marcas'),
        backgroundColor: Colors.green,
        // Adiciona um botão para atualizar a lista manualmente, se necessário
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _brands,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Erro ao carregar marcas: ${snapshot.error}'),
              ),
            );
          }

          final brands = snapshot.data ?? [];
          if (brands.isEmpty) {
            return const Center(
              child: Text('Nenhuma marca cadastrada. Use o "+" para adicionar.'),
            );
          }

          // REQUISITO 3: Lista de marcas com opções de Alterar e Excluir
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: brands.length,
              itemBuilder: (context, i) {
                final b = brands[i];
                final id = b['id']?.toString() ?? '';
                final name = b['name'] ?? 'Marca sem nome'; // CHAVE CORRIGIDA
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(id),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ID: $id'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão de Alterar (EDIT)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _openSaveDialog(brand: b),
                        ),
                        // Botão de Excluir (DELETE)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBrand(id, name),
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
      // REQUISITO 2: FloatingActionButton para Inserir Marca
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSaveDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}