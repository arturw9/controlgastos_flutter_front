import 'package:controlgastos/provider/TemaProvider.dart';
import 'package:controlgastos/views/GraficoView.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'CriarTransacaoView.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeView extends StatefulWidget {
  final String userId; // Recebe o ID do usuário

  HomeView({required this.userId});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  List<String> _categories = ['Todas'];
  bool _isLoading = true;

  String? _selectedCategory = 'Todas';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'data'; // Valor padrão para ordenação

  // Resumo financeiro
  double _saldoTotal = 0.0;
  double _totalReceitas = 0.0;
  double _totalDespesas = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _fetchCategories();
  }

  Future<void> _fetchTransactions() async {
    final url = Uri.parse(
        'https://10.0.2.2:7010/Transações/Listar?idUsuario=${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _transactions = data.map((transaction) {
            return {
              'descricao': transaction['descricao'],
              'category': transaction['category'],
              'valor': transaction['valor'],
              'data': DateTime.parse(transaction['data']),
            };
          }).toList();
          _filteredTransactions = _transactions;
          _calculateFinancialSummary(); // Atualiza os totais
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar as transações.')),
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

  Future<void> _fetchCategories() async {
    final url = Uri.parse('https://10.0.2.2:7010/Categorias/Listar');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _categories.addAll(data.map<String>((category) {
            return category['name'];
          }).toList());
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar as categorias.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão com a API.')),
      );
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        final transactionDate = transaction['data'];

        final matchesCategory = _selectedCategory == 'Todas' ||
            transaction['category']['name'] == _selectedCategory;

        final withinDateRange =
            (_startDate == null || !transactionDate.isBefore(_startDate!)) &&
                (_endDate == null || !transactionDate.isAfter(_endDate!));

        return matchesCategory && withinDateRange;
      }).toList();

      // Ordenação
      if (_sortBy == 'data') {
        _filteredTransactions.sort((a, b) => a['data'].compareTo(b['data']));
      } else if (_sortBy == 'valor') {
        _filteredTransactions.sort((a, b) => a['valor'].compareTo(b['valor']));
      }

      _calculateFinancialSummary(); // Atualiza os totais após aplicar filtros
    });
  }

  void _calculateFinancialSummary() {
    _saldoTotal = 0.0;
    _totalReceitas = 0.0;
    _totalDespesas = 0.0;

    for (var transaction in _filteredTransactions) {
      final valor = transaction['valor'];
      if (valor > 0) {
        _totalReceitas += valor;
      } else {
        _totalDespesas += valor.abs();
      }
    }

    _saldoTotal = _totalReceitas - _totalDespesas;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Todas';
      _startDate = null;
      _endDate = null;
      _applyFiltersAndSort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo Financeiro'),
      ),
      body: Column(
        children: [
          _buildFinancialSummary(),
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(child: Text('Nenhuma transação encontrada.'))
                    : ListView.builder(
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                transaction['descricao'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Categoria: ${transaction['category']['name']}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              trailing: Text(
                                'R\$ ${transaction['valor'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: transaction['valor'] < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CriarTransacaoView(userId: widget.userId),
            ),
          );

          if (result == true) {
            _fetchTransactions();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Nova Transação',
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controle de gastos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Saldo Total: R\$ ${_saldoTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              color: _saldoTotal >= 0 ? Colors.green : Colors.red,
            ),
          ),
          Text(
            'Total de Receitas: R\$ ${_totalReceitas.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, color: Colors.green),
          ),
          Text(
            'Total de Despesas: R\$ ${_totalDespesas.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
          Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          DropdownButton<String>(
            value: _selectedCategory,
            hint: Text('Selecione uma categoria'),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _applyFiltersAndSort();
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                      _applyFiltersAndSort();
                    }
                  },
                  child: Text(_startDate == null
                      ? 'Data Inicial'
                      : 'Inicio: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                      _applyFiltersAndSort();
                    }
                  },
                  child: Text(_endDate == null
                      ? 'Data Final'
                      : 'Fim: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                ),
              )
            ],
          ),
          Column(
            children: [
              Row(
                children: [
                  Text('Ordenar por: '),
                  DropdownButton<String>(
                    value: _sortBy,
                    items: [
                      'data',
                      'valor',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value == 'data' ? 'Data' : 'Valor'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                  ElevatedButton(
                    onPressed: _resetFilters,
                    child: Text('Resetar Filtros'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GraficoView(userId: widget.userId),
                        ),
                      );
                    },
                    child: Text("Gráficos"),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                        alignment: Alignment.center,
                        child: SwitchListTile(
                          title: Text('Tema'),
                          value: Provider.of<TemaProvider>(context).themeMode ==
                              ThemeMode.dark, // Verifica se o tema atual é dark
                          onChanged: (value) {
                            // Alterna o tema entre dark e light
                            Provider.of<TemaProvider>(context, listen: false)
                                .toggleTheme();
                          },
                        )),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
