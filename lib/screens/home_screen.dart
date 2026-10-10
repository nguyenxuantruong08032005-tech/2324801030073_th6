import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/song_data.dart';
import '../models/song.dart';
import '../services/auth_service.dart';
import '../services/library_service.dart';
import '../services/music_service.dart';
import '../theme/melody_theme.dart';
import '../widgets/music_visuals.dart';
import '../widgets/song_art.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _music = MusicService();
  final LibraryService _libraryService = LibraryService();

  final TextEditingController _searchController = TextEditingController();

  late Stream<MusicLibrary> _libraryStream;

  final Set<String> _busyActions = {};

  int _selectedTab = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();

    _libraryStream = _libraryService.watchLibrary(widget.user.uid);
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Cập nhật Firestore với xử lý timeout
  Future<void> _updateLibrary({
    required String actionKey,
    required Future<void> Function() operation,
  }) async {
    if (_busyActions.contains(actionKey)) return;

    setState(() {
      _busyActions.add(actionKey);
    });

    try {
      await operation().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      _message('Đang chờ kết nối để đồng bộ dữ liệu với Firebase.');
    } catch (error) {
      debugPrint('Library update error: $error');

      _message(
        'Không thể cập nhật thư viện. '
        'Hãy kiểm tra kết nối và Firestore Rules.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyActions.remove(actionKey);
        });
      }
    }
  }

  Future<void> _toggleFavorite(Song song, MusicLibrary library) async {
    final shouldAdd = !library.favoriteIds.contains(song.id);

    await _updateLibrary(
      actionKey: 'favorite_${song.id}',
      operation: () => _libraryService.setFavorite(
        uid: widget.user.uid,
        songId: song.id,
        favorite: shouldAdd,
      ),
    );
  }

  Future<void> _togglePlaylist(Song song, MusicLibrary library) async {
    final shouldAdd = !library.playlistIds.contains(song.id);

    await _updateLibrary(
      actionKey: 'playlist_${song.id}',
      operation: () => _libraryService.setPlaylistSong(
        uid: widget.user.uid,
        songId: song.id,
        added: shouldAdd,
      ),
    );
  }

  List<Song> _visibleSongs(MusicLibrary library) {
    List<Song> songs;

    if (_selectedTab == 1) {
      songs = SongData.songs
          .where((song) => library.favoriteIds.contains(song.id))
          .toList();
    } else if (_selectedTab == 2) {
      songs = SongData.songs
          .where((song) => library.playlistIds.contains(song.id))
          .toList();
    } else {
      songs = SongData.songs;
    }

    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return songs;

    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
  }

  void _openPlayer() {
    if (_music.currentSong == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(music: _music)),
    );
  }

  void _selectSong(List<Song> songs, int index) {
    if (_music.isLoading) return;

    // Chỉ mở player nếu bài hiện tại đã được chọn
    if (_music.currentSong?.id != songs[index].id) {
      unawaited(_music.playFrom(songs, index));
    }

    _openPlayer();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi Melody không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _music.player.stop();
      await AuthService.instance.logout();
    } catch (error) {
      _message('Không thể đăng xuất. Hãy thử lại.');
    }
  }

  Widget _buildBanner() {
    final name = widget.user.displayName?.isNotEmpty == true
        ? widget.user.displayName!
        : widget.user.email ?? 'Người dùng';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF705098), MelodyColors.dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -32 : 18,
                top: compact ? 35 : -16,
                child: RecordIllustration(size: compact ? 150 : 220),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, compact ? 82 : 240, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DÀNH CHO BẠN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xFFD8C8F0),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Xin chào, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE8DFF3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hôm nay bạn\nmuốn nghe gì?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 25 : 30,
                        height: 1.2,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _search = value);
      },
      decoration: InputDecoration(
        hintText: 'Tìm bài hát, nghệ sĩ...',
        prefixIcon: const Icon(Icons.search_rounded, size: 23),
        fillColor: Colors.white,
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.close),
                tooltip: 'Xóa tìm kiếm',
              ),
      ),
    );
  }

  Widget _buildSongTile(
    Song song,
    List<Song> songs,
    int index,
    MusicLibrary library,
  ) {
    final favorite = library.favoriteIds.contains(song.id);
    final inPlaylist = library.playlistIds.contains(song.id);

    final favoriteBusy = _busyActions.contains('favorite_${song.id}');
    final playlistBusy = _busyActions.contains('playlist_${song.id}');

    return AnimatedBuilder(
      animation: _music,
      builder: (context, child) {
        final current = _music.currentSong?.id == song.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: current ? MelodyColors.lavender : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: current ? const Color(0xFFCDBBEA) : MelodyColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _selectSong(songs, index),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                child: Row(
                  children: [
                    SongArt(song: song, size: 54, borderRadius: 13),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: current
                                  ? MelodyColors.primary
                                  : MelodyColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MelodyColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: favorite ? 'Bỏ yêu thích' : 'Thêm yêu thích',
                      onPressed: favoriteBusy
                          ? null
                          : () => _toggleFavorite(song, library),
                      icon: Icon(
                        favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: favorite
                            ? MelodyColors.rose
                            : const Color(0xFFAAA1B6),
                        size: 21,
                      ),
                    ),

                    IconButton(
                      tooltip: inPlaylist
                          ? 'Xóa khỏi playlist'
                          : 'Thêm vào playlist',
                      onPressed: playlistBusy
                          ? null
                          : () => _togglePlaylist(song, library),
                      icon: Icon(
                        inPlaylist
                            ? Icons.playlist_add_check_rounded
                            : Icons.playlist_add_rounded,
                        color: inPlaylist
                            ? MelodyColors.primary
                            : const Color(0xFFAAA1B6),
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongList(MusicLibrary library) {
    final songs = _visibleSongs(library);

    if (songs.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: MelodyColors.lavender,
              child: Icon(
                Icons.library_music_outlined,
                size: 32,
                color: MelodyColors.primary,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Chưa có bài hát trong danh sách',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MelodyColors.muted,
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 20),
      sliver: SliverList.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return _buildSongTile(songs[index], songs, index, library);
        },
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return AnimatedBuilder(
      animation: _music,
      builder: (context, child) {
        final song = _music.currentSong;

        if (song == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Material(
            color: MelodyColors.dark,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openPlayer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<Duration>(
                    stream: _music.player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;

                      final duration = _music.duration;

                      final value = duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds)
                                .clamp(0.0, 1.0)
                                .toDouble()
                          : 0.0;

                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        color: const Color(0xFFC6ADEE),
                        backgroundColor: const Color(0xFF463559),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SongArt(song: song, size: 44, borderRadius: 12),

                        const SizedBox(width: 11),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFBEB0CE),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_music.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFC6ADEE),
                              ),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: _music.isPlaying
                                ? 'Tạm dừng'
                                : 'Phát nhạc',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF453454),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _music.togglePlayPause,
                            icon: Icon(
                              _music.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 28,
                            ),
                          ),

                        IconButton(
                          tooltip: 'Bài tiếp theo',
                          color: Colors.white,
                          onPressed: _music.next,
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(MusicLibrary library, bool loading, String? error) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildBanner(),
                    const SizedBox(height: 24),
                    _buildSearch(),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTab == 0
                                ? 'Khám phá bài hát'
                                : _selectedTab == 1
                                ? 'Bài hát yêu thích'
                                : 'Playlist của tôi',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: MelodyColors.lavender,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_visibleSongs(library).length} bài',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MelodyColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 36,
                            color: MelodyColors.muted,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: MelodyColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _buildSongList(library),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MusicLibrary>(
      stream: _libraryStream,
      builder: (context, snapshot) {
        final library = snapshot.data ?? MusicLibrary.empty();

        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        final error = snapshot.hasError
            ? 'Không thể tải thư viện nhạc từ Firestore. '
                  'Hãy kiểm tra Internet và Security Rules.'
            : null;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 76,
            titleSpacing: 20,
            title: const Row(
              children: [
                MelodyMark(size: 38),
                SizedBox(width: 11),
                Text('Melody'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: _logout,
                style: IconButton.styleFrom(
                  backgroundColor: MelodyColors.lavender,
                  foregroundColor: MelodyColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
              ),
              const SizedBox(width: 20),
            ],
          ),

          body: _buildContent(library, loading, error),

          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MelodyColors.border)),
            ),
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniPlayer(),

                    NavigationBar(
                      selectedIndex: _selectedTab,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedTab = index;
                          _search = '';
                          _searchController.clear();
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.explore_outlined),
                          selectedIcon: Icon(Icons.explore),
                          label: 'Khám phá',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.favorite_border),
                          selectedIcon: Icon(Icons.favorite),
                          label: 'Yêu thích',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.library_music_outlined),
                          selectedIcon: Icon(Icons.library_music),
                          label: 'Playlist',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
