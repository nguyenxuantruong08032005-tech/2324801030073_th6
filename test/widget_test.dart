import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:th6_2324801030073_nguyenxuantruong/data/song_data.dart';
import 'package:th6_2324801030073_nguyenxuantruong/models/song.dart';
import 'package:th6_2324801030073_nguyenxuantruong/screens/auth_screen.dart';
import 'package:th6_2324801030073_nguyenxuantruong/screens/player_screen.dart';
import 'package:th6_2324801030073_nguyenxuantruong/services/music_service.dart';
import 'package:th6_2324801030073_nguyenxuantruong/theme/melody_theme.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(640, 360),
    const Size(1280, 900),
  ]) {
    testWidgets('Auth and player fit ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_app(const AuthScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Tiếp tục với Google'), findsOneWidget);

      final music = _TestMusic();
      await tester.pumpWidget(_app(PlayerScreen(music: music)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(SongData.songs.first.title), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      music.dispose();
    });
  }

  testWidgets('Registration keeps its fields and validation', (tester) async {
    await tester.pumpWidget(_app(const AuthScreen()));
    final switchMode = find.text('Chưa có tài khoản? Đăng ký ngay');
    await tester.ensureVisible(switchMode);
    await tester.tap(switchMode);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));

    final submit = find.widgetWithText(FilledButton, 'Đăng ký tài khoản');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auth stays scrollable with the keyboard and larger text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: MelodyTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final google = find.text('Tiếp tục với Google');
    await tester.ensureVisible(google);
    await tester.pumpAndSettle();
    expect(google.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Player controls keep their existing actions', (tester) async {
    final music = _TestMusic();
    await tester.pumpWidget(_app(PlayerScreen(music: music)));
    await tester.pumpAndSettle();
    for (final tooltip in ['Bài trước', 'Phát nhạc', 'Bài tiếp theo']) {
      final control = find.byTooltip(tooltip);
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
    }
    expect(music.previousCalls, 1);
    expect(music.playPauseCalls, 1);
    expect(music.nextCalls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    music.dispose();
  });
}

Widget _app(Widget screen) =>
    MaterialApp(theme: MelodyTheme.light, home: screen);

class _TestPlayer extends Fake implements AudioPlayer {
  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();
}

class _TestMusic extends ChangeNotifier implements MusicService {
  int previousCalls = 0;
  int playPauseCalls = 0;
  int nextCalls = 0;

  @override
  final AudioPlayer player = _TestPlayer();

  @override
  Song get currentSong => SongData.songs.first;

  @override
  Duration get duration => const Duration(minutes: 3, seconds: 42);

  @override
  bool get isLoading => false;

  @override
  bool get isPlaying => false;

  @override
  String? get error => null;

  @override
  Future<void> previous() async => previousCalls++;

  @override
  Future<void> togglePlayPause() async => playPauseCalls++;

  @override
  Future<void> next() async => nextCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
