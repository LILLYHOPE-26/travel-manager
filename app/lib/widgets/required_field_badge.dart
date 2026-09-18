import 'package:flutter/material.dart';

class RequiredFieldBadge extends StatelessWidget {
  final bool show;
  const RequiredFieldBadge({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Text('필수 입력 항목입니다', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }
}
