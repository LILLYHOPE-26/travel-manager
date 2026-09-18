import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/route_models.dart';
import '../providers/route_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/required_field_badge.dart';

const _transportOptions = ['도보', '대중교통', '렌터카'];

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final List<TextEditingController> _waypointControllers = [];
  String _transport = '대중교통';
  bool _submitted = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    for (final c in _waypointControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _originMissing => _submitted && _originController.text.trim().isEmpty;
  bool get _destinationMissing => _submitted && _destinationController.text.trim().isEmpty;

  void _addWaypoint() {
    setState(() => _waypointControllers.add(TextEditingController()));
  }

  void _removeWaypoint(int index) {
    setState(() => _waypointControllers.removeAt(index).dispose());
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_originController.text.trim().isEmpty || _destinationController.text.trim().isEmpty) return;

    final waypoints = _waypointControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    context.read<RouteProvider>().calculate(
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          waypoints: waypoints,
          transport: _transport,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _originController,
            decoration: const InputDecoration(labelText: '출발지 *'),
          ),
          RequiredFieldBadge(show: _originMissing),
          const SizedBox(height: 12),
          ..._waypointControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: '경유지 ${index + 1}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeWaypoint(index),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addWaypoint,
            icon: const Icon(Icons.add),
            label: const Text('경유지 추가'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            decoration: const InputDecoration(labelText: '목적지 *'),
          ),
          RequiredFieldBadge(show: _destinationMissing),
          const SizedBox(height: 12),
          const Text('이동수단'),
          Wrap(
            spacing: 8,
            children: _transportOptions
                .map((t) => ChoiceChip(
                      label: Text(t),
                      selected: _transport == t,
                      onSelected: (_) => setState(() => _transport = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: provider.loading ? null : _submit,
            child: const Text('경로 계산'),
          ),
          const SizedBox(height: 16),
          if (provider.loading) const LoadingView(),
          if (provider.error != null) ErrorView(message: provider.error!),
          if (provider.result != null) _RouteResultView(result: provider.result!),
        ],
      ),
    );
  }
}

class _RouteResultView extends StatelessWidget {
  final RouteResult result;
  const _RouteResultView({required this.result});

  String _fmtDistance(int m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)}km' : '${m}m';

  String _fmtDuration(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    return h > 0 ? '$h시간 $m분' : '$m분';
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final places = result.orderedPlaceNames;
    if (places.length < 2) return;

    const modeMap = {'도보': 'walking', '렌터카': 'driving', '대중교통': 'transit'};
    final waypoints = places.sublist(1, places.length - 1);

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': places.first,
      'destination': places.last,
      'travelmode': modeMap[result.transport] ?? 'driving',
      if (waypoints.isNotEmpty) 'waypoints': waypoints.join('|'),
    });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('확인 불가 (지도 앱을 열 수 없습니다)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '총 거리: ${_fmtDistance(result.totalDistanceM)} / 총 소요시간: ${_fmtDuration(result.totalDurationMin)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openInGoogleMaps(context),
          icon: const Icon(Icons.map_outlined),
          label: const Text('구글 지도에서 실제 경로 보기'),
        ),
        const SizedBox(height: 12),
        const Text('구간별 상세', style: TextStyle(fontWeight: FontWeight.bold)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('구간')),
              DataColumn(label: Text('거리')),
              DataColumn(label: Text('소요시간')),
              DataColumn(label: Text('근거')),
            ],
            rows: result.legs
                .map((leg) => DataRow(cells: [
                      DataCell(Text('${leg.from} → ${leg.to}')),
                      DataCell(Text(_fmtDistance(leg.distanceM))),
                      DataCell(Text(_fmtDuration(leg.durationMin))),
                      DataCell(Text(leg.source)),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }
}
