import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GraficoView extends StatefulWidget {
  final String userId;

  GraficoView({required this.userId});

  @override
  _GraficoViewState createState() => _GraficoViewState();
}

class _GraficoViewState extends State<GraficoView> {
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
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
          _calculateFinancialSummary();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar as transações.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro de conexão com a API.')));
    }
  }

  void _calculateFinancialSummary() {
    double _totalReceitas = 0.0;
    double _totalDespesas = 0.0;

    for (var transaction in _transactions) {
      final valor = transaction['valor'];
      if (valor > 0) {
        _totalReceitas += valor;
      } else {
        _totalDespesas += valor.abs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráficos de Gastos'),
      ),
      body: _transactions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Despesas por Categoria',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  height: 250,
                  padding: EdgeInsets.all(16.0),
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Evolução dos Gastos ao Longo do Tempo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  height: 250,
                  padding: EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 8),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 16,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < _transactions.length) {
                                final dateKey = DateFormat('yyyy-MM-dd')
                                    .format(_transactions[index]['data']);
                                return Text(
                                  dateKey,
                                  style: TextStyle(fontSize: 10),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: _generateBarChartData(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Gera as seções do gráfico de pizza com base nas transações e cores aleatórias para cada categoria
  List<PieChartSectionData> _generatePieChartSections() {
    Map<String, double> categoryTotals = {};
    List<Color> categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.brown,
      Colors.cyan
    ];

    for (var transaction in _transactions) {
      final category = transaction['category']['name'];
      final valor = transaction['valor'];

      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + valor;
      } else {
        categoryTotals[category] = valor;
      }
    }

    // Ordena as categorias para garantir uma distribuição das cores de forma consistente
    List<MapEntry<String, double>> sortedEntries = categoryTotals.entries
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries.asMap().entries.map((entry) {
      final category = entry.value.key;
      final total = entry.value.value;
      final color = categoryColors[entry.key % categoryColors.length];

      return PieChartSectionData(
        value: total,
        title: '$category: R\$ ${total.toStringAsFixed(2)}',
        color: color,
        radius: 50,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  // Gera os dados do gráfico de barras com base nas transações ao longo do tempo (datas)
  List<BarChartGroupData> _generateBarChartData() {
    // Agrupa os totais diários para cada transação com base na data
    Map<String, double> dailyTotals = {};

    for (var transaction in _transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction['data']);
      final valor = transaction['valor'];

      // Verifica se a chave (data) já existe no mapa, se sim, soma o valor, caso contrário, cria uma nova entrada
      if (dailyTotals.containsKey(dateKey)) {
        dailyTotals[dateKey] = dailyTotals[dateKey]! + valor;
      } else {
        dailyTotals[dateKey] = valor;
      }
    }

    List<BarChartGroupData> barGroups = [];
    int index = 0;

    // Adiciona as barras ao gráfico
    dailyTotals.forEach((date, total) {
      print('Data: $date, Total: $total'); // Verifica os valores agregados
      barGroups.add(BarChartGroupData(
        x: index++, // Atribui um índice para cada barra
        barRods: [
          BarChartRodData(toY: total, color: Colors.blue, width: 20),
        ],
        showingTooltipIndicators: [0],
      ));
    });

    return barGroups;
  }
}
