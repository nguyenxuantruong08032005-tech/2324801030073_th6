import 'dart:async';

import 'package:flutter/material.dart';

import '../services/music_service.dart';
import '../theme/melody_theme.dart';
import '../widgets/song_art.dart';

class PlayerScreen extends StatefulWidget {
  final MusicService music;

  const PlayerScreen({super.key, required this.music});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _dragPosition;

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildProgress() {
    return StreamBuilder<Duration?>(
      stream: widget.music.player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? widget.music.duration;

        return StreamBuilder<Duration>(
          stream: widget.music.player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            final maxMilliseconds = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;

            final value = (_dragPosition ?? position.inMilliseconds.toDouble())
                .clamp(0.0, maxMilliseconds)
                .toDouble();

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xFFD4BFF3),
                    inactiveTrackColor: const Color(0xFF574366),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayColor: const Color(0x22D4BFF3),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: maxMilliseconds,
                    onChanged: duration.inMilliseconds > 0
                        ? (nextValue) {
                            setState(() {
                              _dragPosition = nextValue;
                            });
                          }
                        : null,
                    onChangeEnd: duration.inMilliseconds > 0
                        ? (nextValue) {
                            unawaited(
                              widget.music.seek(
                                Duration(milliseconds: nextValue.round()),
                              ),
                            );

                            setState(() {
                              _dragPosition = null;
                            });
                          }
                        : null,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(Duration(milliseconds: value.round())),
                        style: const TextStyle(
                          color: Color(0xFFBEB0CE),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTime(duration),
                        style: const TextStyle(
                          color: Color(0xFFBEB0CE),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    final music = widget.music;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Bài trước',
          color: Colors.white,
          disabledColor: const Color(0xFF796789),
          onPressed: music.isLoading ? null : music.previous,
          icon: const Icon(Icons.skip_previous_rounded, size: 43),
        ),

        const SizedBox(width: 23),

        Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF2EAFB),
            boxShadow: [
              BoxShadow(
                color: Color(0x447E5DAB),
                blurRadius: 30,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: music.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: MelodyColors.primary,
                    strokeWidth: 3,
                  ),
                )
              : IconButton(
                  tooltip: music.isPlaying ? 'Tạm dừng' : 'Phát nhạc',
                  onPressed: music.togglePlayPause,
                  icon: Icon(
                    music.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: MelodyColors.dark,
                    size: 42,
                  ),
                ),
        ),

        const SizedBox(width: 23),

        IconButton(
          tooltip: 'Bài tiếp theo',
          color: Colors.white,
          disabledColor: const Color(0xFF796789),
          onPressed: music.isLoading ? null : music.next,
          icon: const Icon(Icons.skip_next_rounded, size: 43),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.music,
      builder: (context, child) {
        final song = widget.music.currentSong;

        return Scaffold(
          backgroundColor: MelodyColors.dark,
          appBar: AppBar(
            backgroundColor: MelodyColors.dark,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 72,
            title: const Text(
              'Đang phát',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DFF3),
              ),
            ),
            centerTitle: true,
          ),

          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.1,
                colors: [Color(0xFF59426C), MelodyColors.dark],
              ),
            ),
            child: song == null
                ? const Center(
                    child: Text(
                      'Chưa chọn bài hát.',
                      style: TextStyle(color: Color(0xFFBEB0CE)),
                    ),
                  )
                : SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 35),
                          child: Column(
                            children: [
                              const Text(
                                'MELODY • NOW PLAYING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: Color(0xFFC6ADEE),
                                ),
                              ),

                              const SizedBox(height: 28),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final size = (constraints.maxWidth - 20)
                                      .clamp(100.0, 310.0)
                                      .toDouble();

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0x18FFFFFF),
                                      border: Border.all(
                                        color: const Color(0x26FFFFFF),
                                      ),
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x550E0817),
                                          blurRadius: 40,
                                          offset: Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: SongArt(
                                      song: song,
                                      size: size,
                                      borderRadius: 25,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              Text(
                                song.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFBEB0CE),
                                ),
                              ),

                              const SizedBox(height: 29),

                              _buildProgress(),

                              const SizedBox(height: 19),

                              _buildControls(),

                              const SizedBox(height: 23),

                              if (widget.music.error != null)
                                Column(
                                  children: [
                                    Text(
                                      widget.music.error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFFAFBF),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFD4BFF3,
                                        ),
                                      ),
                                      onPressed: widget.music.isLoading
                                          ? null
                                          : widget.music.retry,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Thử phát lại'),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x0DFFFFFF),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0x12FFFFFF),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.wifi_rounded,
                                        size: 17,
                                        color: Color(0xFFC6ADEE),
                                      ),
                                      SizedBox(width: 7),
                                      Flexible(
                                        child: Text(
                                          'Đang sử dụng nguồn nhạc online',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFBEB0CE),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
