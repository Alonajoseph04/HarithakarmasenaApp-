import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WasteInsightsScreen extends StatefulWidget {
  const WasteInsightsScreen({super.key});
  @override
  State<WasteInsightsScreen> createState() => _WasteInsightsScreenState();
}

class _WasteInsightsScreenState extends State<WasteInsightsScreen> {
  final _api = ApiService();
  List<dynamic> _collections = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await _api.getHouseholdMe();
      final cols = await _api.getCollections(householdId: h['id'] as int);
      setState(() { _collections = cols; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Map<String, double> get _wasteByType {
    final m = <String, double>{};
    for (final c in _collections) {
      final t = c['waste_type'] as String;
      m[t] = (m[t] ?? 0) + (double.tryParse(c['weight']?.toString() ?? '0') ?? 0.0);
    }
    return m;
  }

  Map<String, double> get _monthlyWeight {
    final m = <String, double>{};
    for (final c in _collections) {
      final month = c['date'].toString().substring(0, 7);
      m[month] = (m[month] ?? 0) + (double.tryParse(c['weight']?.toString() ?? '0') ?? 0.0);
    }
    return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  static const _colors = [AppTheme.primary, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red, Colors.pink];

  @override
  Widget build(BuildContext context) {
    final byType = _wasteByType;
    final monthly = _monthlyWeight;

    return Scaffold(
      appBar: AppBar(title: const Text('Waste Insights')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Waste type pie chart
                Text('Waste Type Breakdown', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (byType.isNotEmpty)
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: PieChart(PieChartData(
                          sections: byType.entries.map((e) {
                            final idx = byType.keys.toList().indexOf(e.key);
                            return PieChartSectionData(
                              value: e.value,
                              color: _colors[idx % _colors.length],
                              title: '${e.value.toStringAsFixed(1)}kg',
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                              radius: 72,
                            );
                          }).toList(),
                          centerSpaceRadius: 28,
                          sectionsSpace: 2,
                        )),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: byType.entries.map((e) {
                          final idx = byType.keys.toList().indexOf(e.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              Container(width: 12, height: 12,
                                  decoration: BoxDecoration(color: _colors[idx % _colors.length], shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('${e.key[0].toUpperCase()}${e.key.substring(1)}',
                                  style: GoogleFonts.poppins(fontSize: 11)),
                            ]),
                          );
                        }).toList(),
                      ),
                    ]),
                  ),

                const SizedBox(height: 24),

                // Monthly weight bar chart
                Text('Monthly Waste Collected (kg)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (monthly.isNotEmpty)
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    ),
                    child: BarChart(BarChartData(
                      maxY: monthly.values.fold(0.0, (a, b) => a > b ? a : b) * 1.3 + 1,
                      barGroups: monthly.entries.toList().asMap().entries.map((e) {
                        return BarChartGroupData(x: e.key, barRods: [
                          BarChartRodData(
                            toY: e.value.value,
                            color: AppTheme.primary,
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ]);
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final keys = monthly.keys.toList();
                            final idx = val.toInt();
                            if (idx >= 0 && idx < keys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(keys[idx].substring(5),
                                    style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.textLight)),
                              );
                            }
                            return const SizedBox();
                          },
                        )),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                    )),
                  ),

                const SizedBox(height: 24),

                // Type breakdown table
                Text('By Waste Type', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...byType.entries.map((e) {
                  final idx = byType.keys.toList().indexOf(e.key);
                  final pct = byType.values.fold(0.0, (a, b) => a + b);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(width: 10, height: 10,
                                decoration: BoxDecoration(color: _colors[idx % _colors.length], shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('${e.key[0].toUpperCase()}${e.key.substring(1)}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ]),
                          Text('${e.value.toStringAsFixed(2)} kg',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: pct > 0 ? e.value / pct : 0,
                        backgroundColor: Colors.grey.shade100,
                        color: _colors[idx % _colors.length],
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                  );
                }),
              ],
            ),
    );
  }
}
