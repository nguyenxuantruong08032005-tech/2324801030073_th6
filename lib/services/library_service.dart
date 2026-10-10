import 'package:cloud_firestore/cloud_firestore.dart';

class MusicLibrary {
  final Set<String> favoriteIds;
  final Set<String> playlistIds;

  const MusicLibrary({
    required this.favoriteIds,
    required this.playlistIds,
  });

  factory MusicLibrary.empty() {
    return const MusicLibrary(
      favoriteIds: <String>{},
      playlistIds: <String>{},
    );
  }
}

class LibraryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _libraryDoc(
    String uid,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc('my_music');
  }

  // Nhận cập nhật Firestore theo thời gian thực
  Stream<MusicLibrary> watchLibrary(String uid) {
    return _libraryDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return MusicLibrary.empty();
      }

      final favorites =
          (data['favoriteSongIds'] as List<dynamic>?) ?? [];

      final playlist =
          (data['playlistSongIds'] as List<dynamic>?) ?? [];

      return MusicLibrary(
        favoriteIds: favorites.whereType<String>().toSet(),
        playlistIds: playlist.whereType<String>().toSet(),
      );
    });
  }

  // Lưu hoặc bỏ thích bài hát
  Future<void> setFavorite({
    required String uid,
    required String songId,
    required bool favorite,
  }) async {
    await _libraryDoc(uid).set(
      {
        'favoriteSongIds': favorite
            ? FieldValue.arrayUnion([songId])
            : FieldValue.arrayRemove([songId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Thêm hoặc xóa bài hát khỏi playlist
  Future<void> setPlaylistSong({
    required String uid,
    required String songId,
    required bool added,
  }) async {
    await _libraryDoc(uid).set(
      {
        'playlistSongIds': added
            ? FieldValue.arrayUnion([songId])
            : FieldValue.arrayRemove([songId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}