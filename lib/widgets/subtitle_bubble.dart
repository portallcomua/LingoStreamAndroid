import 'package:flutter/material.dart';

class SubtitleBubble extends StatelessWidget {
  final String original;
  final String translated;
  final bool compact;

  const SubtitleBubble({
    super.key,
    required this.original,
    required this.translated,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (translated.trim().isEmpty && original.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact && original.isNotEmpty && original != translated)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                original,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            translated.isNotEmpty ? translated : original,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
