import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/itinerary_models.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/required_field_badge.dart';

const _styleOptions = ['관광 중심', '휴양 중심', '맛집 중심', '쇼핑 중심'];
const _transportOptions = ['도보', '대중교통', '렌터카'];

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _destinationController = TextEditingController();
  final _cityController = TextEditingController();
  final _specialController = TextEditingController();
  DateTimeRange? _dateRange;
  final Set<String> _styles = {};
  String? _transport;
  bool _submitted = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _cityController.dispose();
    _specialController.dispose();
    super.dispose();
  }

  bool get _destinationMissing => _submitted && _destinationController.text.trim().isEmpty;
  bool get _dateMissing => _submitted && _dateRange == null;
  bool get _transportMissing => _submitted && _transport == null;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _submit() {
    setState(() => _submitted = true);
    if (_destinationController.text.trim().isEmpty || _dateRange == null || _transport == null) return;

    final totalDays = _dateRange!.end.difference(_dateRange!.start).inDays + 1;

    final request = ItineraryRequest(
      destination: _destinationController.text.trim(),
      city: _cityController.text.trim(),
      totalDays: totalDays,
      startDate: _fmt(_dateRange!.start),
      endDate: _fmt(_dateRange!.end),
      styles: _styles.toList(),
      transport: _transport!,
      specialRequests: _specialController.text.trim(),
    );

    context.read<ItineraryProvider>().generate(request);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItineraryProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(labelText: '여행지 (국가) *'),
          ),
          RequiredFieldBadge(show: _destinationMissing),
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: '도시'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickDateRange,
            child: Text(_dateRange == null
                ? '여행 기간 선택 *'
                : '${_fmt(_dateRange!.start)} ~ ${_fmt(_dateRange!.end)}'),
          ),
          RequiredFieldBadge(show: _dateMissing),
          const SizedBox(height: 12),
          const Text('여행 스타일 (복수 선택)'),
          Wrap(
            spacing: 8,
            children: _styleOptions
                .map((s) => FilterChip(
                      label: Text(s),
                      selected: _styles.contains(s),
                      onSelected: (v) => setState(() => v ? _styles.add(s) : _styles.remove(s)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('이동수단 *'),
          ..._transportOptions.map((t) => RadioListTile<String>(
                title: Text(t),
                value: t,
                groupValue: _transport,
                onChanged: (v) => setState(() => _transport = v),
              )),
          RequiredFieldBadge(show: _transportMissing),
          const SizedBox(height: 8),
          TextField(
            controller: _specialController,
            decoration: const InputDecoration(labelText: '특별 요청사항 (아이 동반, 노약자, 체력 수준 등)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: provider.loading ? null : _submit,
            child: const Text('일정표 생성'),
          ),
          const SizedBox(height: 16),
          if (provider.loading) const LoadingView(),
          if (provider.error != null) ErrorView(message: provider.error!),
          if (provider.result != null) _ItineraryResultView(result: provider.result!),
        ],
      ),
    );
  }
}

class _ItineraryResultView extends StatelessWidget {
  final ItineraryResult result;
  const _ItineraryResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result.days.map((day) {
        final summary = result.dailySummary.firstWhere(
          (s) => s.day == day.day,
          orElse: () => DailySummary(day: day.day, totalTransportMin: 0, estimatedCost: '확인 불가'),
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('Day ${day.day}'),
            initiallyExpanded: true,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('시간')),
                    DataColumn(label: Text('활동/장소')),
                    DataColumn(label: Text('소요시간')),
                    DataColumn(label: Text('이동수단')),
                    DataColumn(label: Text('메모')),
                  ],
                  rows: day.activities
                      .map((a) => DataRow(cells: [
                            DataCell(Text(a.time)),
                            DataCell(Text('${a.activity}\n${a.place}')),
                            DataCell(Text('${a.durationMin}분')),
                            DataCell(Text(a.transport)),
                            DataCell(Text(a.memo)),
                          ]))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '당일 예상 총 이동시간: ${summary.totalTransportMin}분 / 예상 지출: ${summary.estimatedCost}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
