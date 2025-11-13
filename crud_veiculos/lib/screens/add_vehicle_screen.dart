import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../services/brand_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? id;

  const AddVehicleScreen({super.key, this.existingData, this.id});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _brandService = BrandService();

  final tipoController = TextEditingController();
  final proprietarioController = TextEditingController();
  final anoController = TextEditingController();
  final imagemUrlController = TextEditingController();

  List<Map<String, dynamic>> brands = [];
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadBrands();

    if (widget.existingData != null) {
      tipoController.text = widget.existingData!['tipoVeiculo'] ?? '';
      proprietarioController.text = widget.existingData!['proprietario'] ?? '';
      selectedBrand = widget.existingData!['marca'];
      anoController.text = widget.existingData!['ano']?.toString() ?? '';
      imagemUrlController.text = widget.existingData!['imagem'] ?? '';
    }
  }

  Future<void> _loadBrands() async {
    try {
      final list = await _brandService.getBrands();
      setState(() {
        brands = List<Map<String, dynamic>>.from(list);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar marcas: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'tipoVeiculo': tipoController.text.trim(),
        'proprietario': proprietarioController.text.trim(),
        'marca': selectedBrand,
        'ano': int.tryParse(anoController.text.trim()) ?? 0,
        'imagem': imagemUrlController.text.trim(),
      };

      try {
        if (widget.id == null) {
          await _vehicleService.addVehicle(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veículo adicionado com sucesso!')),
          );
        } else {
          await _vehicleService.updateVehicle(widget.id!, data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veículo atualizado com sucesso!')),
          );
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar veículo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = imagemUrlController.text.trim();

    // 🔹 Converte a lista de marcas em nomes únicos
    final brandNames = brands.map((b) => b['name'] ?? 'Sem nome').toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Adicionar Veículo' : 'Editar Veículo'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 Pré-visualização da imagem via URL
              if (imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
                  ),
                ),

              // 🔹 Campo de URL da imagem
              TextFormField(
                controller: imagemUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL da Imagem (opcional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Veículo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: proprietarioController,
                decoration: const InputDecoration(
                  labelText: 'Proprietário',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 20),

              // 🔹 Dropdown de Marcas (corrigido)
              DropdownButtonFormField<String>(
                value: brandNames.contains(selectedBrand) ? selectedBrand : null,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
                items: brandNames.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    selectedBrand = valor;
                  });
                },
                validator: (v) => v == null ? 'Selecione uma marca' : null,
              ),

              const SizedBox(height: 10),

              // 🔹 Botão para adicionar nova marca
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar nova marca'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () async {
                  final controller = TextEditingController();

                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nova Marca'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Digite o nome da marca',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              try {
                                await _brandService.addBrand({
                                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                  'name': name,
                                });
                                Navigator.pop(context);
                                await _loadBrands(); // recarrega lista
                                setState(() {
                                  selectedBrand = name;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Marca "$name" adicionada com sucesso!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro ao adicionar marca: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: anoController,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
