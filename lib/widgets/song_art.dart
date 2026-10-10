import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/melody_theme.dart';

class SongArt extends StatelessWidget {
  final Song song;
  final double size;
  final double borderRadius;

  const SongArt({
    super.key,
    required this.song,
    this.size = 58,
    this.borderRadius = 14,
  });

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFAA8BCF), MelodyColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.43,
        color: const Color(0xFFEBDFF8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          song.imageUrl,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return frame != null || wasSynchronouslyLoaded
                ? child
                : _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      ),
    );
  }
}
