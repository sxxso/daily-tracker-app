import 'package:flutter/material.dart';

/// 区块标题，可带右侧的补充信息
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
