import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HistorialScreen extends StatefulWidget {
  final String? loteName;
  final String? crop;

  const HistorialScreen({
    super.key,
    this.loteName,
    this.crop,
  });

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> _historyRecords = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryFromHive();
  }

  Future<void> _loadHistoryFromHive() async {
    try {
      final box = Hive.isBoxOpen('history')
          ? Hive.box('history')
          : await Hive.openBox('history');

      final allItems = box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
          .reversed
          .toList();

      setState(() {
        if (widget.loteName == null ||
            widget.loteName == 'General' ||
            widget.loteName == 'Consulta') {
          _historyRecords = allItems;
        } else {
          _historyRecords = allItems.where((item) {
            final itemLote = (item['lote'] ?? item['loteName'] ?? '').toString().toLowerCase();
            return itemLote == widget.loteName!.toLowerCase();
          }).toList();
        }
      });
    } catch (e) {
      debugPrint('Error cargando historial de Hive: $e');
    }
  }

  Future<void> _clearHistory() async {
    final box = Hive.isBoxOpen('history')
        ? Hive.box('history')
        : await Hive.openBox('history');
    await box.clear();
    _loadHistoryFromHive();
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.loteName != null &&
            widget.loteName != 'General' &&
            widget.loteName != 'Consulta')
        ? 'Historial de Lote: ${widget.loteName}'
        : 'Historial de Riegos';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_historyRecords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Limpiar historial',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.crop != null &&
                widget.crop != 'Personal' &&
                widget.crop != 'Vinculada') ...[
              Text(
                'Cultivo: ${widget.crop}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D6A4F),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _historyRecords.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay riegos registrados.\nCuando finalice un ciclo de riego, aparecerá aquí con su fecha y hora.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historyRecords.length,
                      itemBuilder: (context, index) {
                        final item = _historyRecords[index] as Map;
                        final cultivo = item['crop'] ?? item['cultivo'] ?? 'Cultivo';
                        final finca = item['finca'] ?? 'Finca';
                        final lote = item['lote'] ?? item['loteName'] ?? 'Lote';
                        final dateStr = item['date'] ?? '';
                        final duration = item['duration'] ?? '';
                        final finalHumidity = item['finalHumidity'] ?? '';
                        final mode = item['mode'] ?? 'Automático';
                        final summary = item['summary'] ??
                            'Se regó el cultivo de $cultivo el día $dateStr';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      summary.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4332),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ubicación: $finca • $lote',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4A5568),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (finalHumidity.toString().isNotEmpty)
                                          _buildBadge(
                                            'Humedad final: $finalHumidity',
                                            const Color(0xFFE3F2FD),
                                            const Color(0xFF1565C0),
                                          ),
                                        if (duration.toString().isNotEmpty)
                                          _buildBadge(
                                            'Duración: $duration',
                                            const Color(0xFFF3E5F5),
                                            const Color(0xFF6A1B9A),
                                          ),
                                        _buildBadge(
                                          mode.toString(),
                                          const Color(0xFFE8F5E9),
                                          const Color(0xFF2E7D32),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}