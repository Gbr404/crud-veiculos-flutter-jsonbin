import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? id;

  const AddVehicleScreen({super.key, this.existingData, this.id});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = VehicleService();

  final tipoController = TextEditingController();
  final proprietarioController = TextEditingController();
  final marcaController = TextEditingController();
  final anoController = TextEditingController();
  final imagemUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      tipoController.text = widget.existingData!['tipoVeiculo'];
      proprietarioController.text = widget.existingData!['proprietario'];
      marcaController.text = widget.existingData!['marca'];
      anoController.text = widget.existingData!['ano'].toString();
      imagemUrlController.text = widget.existingData!['imagem'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'tipoVeiculo': tipoController.text,
        'proprietario': proprietarioController.text,
        'marca': marcaController.text,
        'ano': int.parse(anoController.text),
        'imagem': imagemUrlController.text.trim(),
      };

      try {
        if (widget.id == null) {
          await _service.addVehicle(data);
        } else {
          await _service.updateVehicle(widget.id!, data);
        }
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = imagemUrlController.text.trim();

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
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: tipoController,
                decoration: const InputDecoration(labelText: 'Tipo de Veículo'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: proprietarioController,
                decoration: const InputDecoration(labelText: 'Proprietário'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: anoController,
                decoration: const InputDecoration(labelText: 'Ano'),
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
