import '../models/song.dart';

class SongData {
  static const List<Song> songs = [
    Song(
      id: 'song_1',
      title: 'SoundHelix Song 1',
      artist: 'SoundHelix',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600',
    ),
    Song(
      id: 'song_2',
      title: 'SoundHelix Song 2',
      artist: 'SoundHelix',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      imageUrl:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600',
    ),
    Song(
      id: 'song_3',
      title: 'SoundHelix Song 3',
      artist: 'SoundHelix',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      imageUrl:
          'https://images.unsplash.com/photo-1516280440614-37939d6bbacd?w=600',
    ),
    Song(
      id: 'song_4',
      title: 'SoundHelix Song 4',
      artist: 'SoundHelix',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      imageUrl:
          'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600',
    ),
    Song(
      id: 'song_5',
      title: 'SoundHelix Song 5',
      artist: 'SoundHelix',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      imageUrl:
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600',
    ),
  ];

  static Song? findById(String id) {
    for (final song in songs) {
      if (song.id == id) return song;
    }
    return null;
  }
}