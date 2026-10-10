import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class MusicService extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();

  late final StreamSubscription<int?> _indexSubscription;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<PlayerException> _errorSubscription;

  List<Song> _queue = [];
  int _currentIndex = -1;

  bool _loading = false;
  bool _disposed = false;
  String? _error;

  MusicService() {
    _indexSubscription =
        player.currentIndexStream.listen((index) {
      if (index != null &&
          index >= 0 &&
          index < _queue.length) {
        _currentIndex = index;
        _notify();
      }
    });

    _stateSubscription = player.playerStateStream.listen(
      (state) {
        _notify();
      },
    );

    _errorSubscription = player.errorStream.listen(
      (error) {
        debugPrint('Audio error: ${error.message}');
        _error = 'Không thể phát bài hát từ URL.';
        _notify();
      },
    );
  }

  Song? get currentSong {
    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length) {
      return null;
    }

    return _queue[_currentIndex];
  }

  bool get isPlaying => player.playing;
  bool get isLoading => _loading;

  String? get error => _error;

  Duration get duration => player.duration ?? Duration.zero;
  Duration get position => player.position;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _startPlaying() {
    if (_disposed) return;

    // Không await: play() có thể chỉ hoàn thành khi
    // phiên phát nhạc dừng lại.
    unawaited(
      player.play().catchError((Object error) {
        if (_disposed) return;

        debugPrint('Play error: $error');
        _error = 'Không thể tiếp tục phát nhạc.';
        _notify();
      }),
    );
  }

  // Phát danh sách từ bài hát được chọn
  Future<void> playFrom(
    List<Song> songs,
    int index,
  ) async {
    if (_loading ||
        songs.isEmpty ||
        index < 0 ||
        index >= songs.length) {
      return;
    }

    _loading = true;
    _error = null;
    _queue = List<Song>.from(songs);
    _currentIndex = index;
    _notify();

    try {
      final sources = songs.map((song) {
        return AudioSource.uri(
          Uri.parse(song.audioUrl),
        );
      }).toList();

      // Tạo hàng đợi phát trực tuyến
      await player.setAudioSources(
        sources,
        initialIndex: index,
        initialPosition: Duration.zero,
        
      );

      // Phát lặp lại danh sách khi tới bài cuối
      await player.setLoopMode(LoopMode.all);

      if (_disposed) return;

      _loading = false;
      _notify();

      _startPlaying();
    } on PlayerInterruptedException {
      if (_disposed) return;

      _loading = false;
      _notify();
    } catch (error) {
      if (_disposed) return;

      debugPrint('Load audio error: $error');

      _error =
          'Không thể tải nhạc. Kiểm tra Internet hoặc URL MP3.';

      _loading = false;
      _notify();
    }
  }

  Future<void> togglePlayPause() async {
    if (_loading || currentSong == null) return;

    try {
      if (player.playing) {
        await player.pause();
      } else {
        _error = null;

        if (player.processingState ==
            ProcessingState.completed) {
          await player.seek(Duration.zero);
        }

        _startPlaying();
      }

      _notify();
    } catch (error) {
      debugPrint('Play/Pause error: $error');
      _error = 'Không thể điều khiển phát nhạc.';
      _notify();
    }
  }

  Future<void> next() async {
    if (_loading || _queue.isEmpty) return;

    try {
      _error = null;
      await player.seekToNext();
      _notify();
    } catch (error) {
      debugPrint('Next error: $error');
    }
  }

  Future<void> previous() async {
    if (_loading || _queue.isEmpty) return;

    try {
      if (player.position.inSeconds > 3) {
        await player.seek(Duration.zero);
      } else {
        await player.seekToPrevious();
      }

      _notify();
    } catch (error) {
      debugPrint('Previous error: $error');
    }
  }

  Future<void> seek(Duration position) async {
    if (_loading) return;

    try {
      await player.seek(position);
    } catch (error) {
      debugPrint('Seek error: $error');
    }
  }

  Future<void> retry() async {
    if (_queue.isEmpty || _currentIndex < 0) return;

    final songs = List<Song>.from(_queue);
    final index = _currentIndex;

    await playFrom(songs, index);
  }

  @override
  void dispose() {
    _disposed = true;

    unawaited(_indexSubscription.cancel());
    unawaited(_stateSubscription.cancel());
    unawaited(_errorSubscription.cancel());
    unawaited(player.dispose());

    super.dispose();
  }
}