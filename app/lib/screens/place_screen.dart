import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place_models.dart';
import '../providers/place_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key});

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  final _regionController = TextEditingController();
  bool _dialogShownForResult = false;

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _showCandidateDialog(List<PlaceCandidate> candidates) async {
    final selected = await showDialog<PlaceCandidate>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('동명 지역이 여러 곳입니다. 선택해주세요.'),
        children: candidates
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, c),
                  child: Text(c.name),
                ))
            .toList(),
      ),
    );
    if (selected != null && mounted) {
      context.read<PlaceProvider>().searchByCandidate(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final result = provider.result;

    if (result != null && result.ambiguous && result.candidates.isNotEmpty && !_dialogShownForResult) {
      _dialogShownForResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCandidateDialog(result.candidates));
    } else if (result == null || !result.ambiguous) {
      _dialogShownForResult = false;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regionController,
                  decoration: const InputDecoration(labelText: '지역명 (도시/동네/랜드마크)'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: provider.loading
                    ? null
                    : () => context.read<PlaceProvider>().search(_regionController.text.trim()),
                child: const Text('검색'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.loading) const LoadingView(),
          if (provider.error != null) ErrorView(message: provider.error!),
          if (result != null && !result.ambiguous) ...[
            const Text('관광지 추천', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('이름')),
                  DataColumn(label: Text('특징')),
                  DataColumn(label: Text('거리')),
                  DataColumn(label: Text('소요시간')),
                ],
                rows: result.attractions
                    .map((a) => DataRow(cells: [
                          DataCell(Text(a.name)),
                          DataCell(Text(a.feature)),
                          DataCell(Text('${a.distanceM}m')),
                          DataCell(Text('${a.walkMin}분 (추정)')),
                        ]))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('맛집 추천 Top 5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('순위')),
                  DataColumn(label: Text('상호명')),
                  DataColumn(label: Text('특징')),
                  DataColumn(label: Text('거리')),
                  DataColumn(label: Text('추천이유')),
                ],
                rows: result.restaurants
                    .map((r) => DataRow(cells: [
                          DataCell(Text('${r.rank}')),
                          DataCell(Text(r.name)),
                          DataCell(Text(r.mainMenu)),
                          DataCell(Text('${r.distanceM}m')),
                          DataCell(Text(r.reason)),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
