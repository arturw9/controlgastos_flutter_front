import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CriarTransacaoView extends StatefulWidget {
  final String userId;

  CriarTransacaoView({required this.userId});

  @override
  _CriarTransacaoViewState createState() => _CriarTransacaoViewState();
}

class _CriarTransacaoViewState extends State<CriarTransacaoView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Função para buscar as categorias da API
  Future<void> _fetchCategories() async {
    final url = Uri.parse('https://10.0.2.2:7010/Categorias/Listar');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _categories = data.map((category) {
            return {
              'id': category['id'],
              'name': category['name'],
            };
          }).toList();
          _isCategoriesLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão com a API.')),
      );
    }
  }

  // Função para buscar o nome da categoria pelo id
  String? _getCategoryNameById(String id) {
    final category = _categories.firstWhere(
      (category) => category['id'] == id,
      orElse: () => {},
    );
    return category['name'];
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://10.0.2.2:7010/Transações/Inserir');

    final transactionData = {
      'descricao': _descriptionController.text,
      'idCategoria': _selectedCategory ?? '',
      'valor': double.parse(_valueController.text),
      'data': _dateController.text,
      'idUsuario': widget.userId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação criada com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar transação.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão com a API.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para abrir o DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        // Formatar a data para o formato desejado
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Criar Transação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descrição'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a descrição';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Valor'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor';
                  }

                  final val = double.tryParse(value);
                  if (val == null) {
                    return 'Informe um valor válido';
                  }

                  // Obter o nome da categoria selecionada
                  final categoryName = _getCategoryNameById(_selectedCategory!);

                  // Verificar se o valor é negativo para receitas
                  if (val < 0 &&
                      categoryName != null &&
                      categoryName.toLowerCase() == 'receita') {
                    return 'Valor não pode ser negativo para receitas';
                  }

                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Data',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () =>
                    _selectDate(context), // Abre o DatePicker ao clicar
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a data';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _isCategoriesLoading
                  ? CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: Text('Selecione a Categoria'),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione uma categoria';
                        }
                        return null;
                      },
                    ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitTransaction,
                      child: Text('Salvar Transação'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
