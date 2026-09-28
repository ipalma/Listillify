import 'package:flutter_test/flutter_test.dart';
import 'package:listillify/features/playlist/domain/entities/track_item.dart';

void main() {
  group('TrackItem Entity', () {
    test('formattedDuration formats mm:ss correctly', () {
      const track1 = TrackItem(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        uri: 'spotify:track:1',
        duration: Duration(minutes: 3, seconds: 45),
        rawQuery: 'Song',
      );

      const track2 = TrackItem(
        id: '2',
        title: 'Song 2',
        artist: 'Artist',
        uri: 'spotify:track:2',
        duration: null,
        rawQuery: 'Song 2',
      );

      expect(track1.formattedDuration, equals('03:45'));
      expect(track2.formattedDuration, equals('--:--'));
    });

    test('TrackItem.notFound creates un-found item representation', () {
      final notFound = TrackItem.notFound('Canción Desconocida');

      expect(notFound.isFound, isFalse);
      expect(notFound.title, equals('Canción Desconocida'));
      expect(notFound.uri, isEmpty);
      expect(notFound.rawQuery, equals('Canción Desconocida'));
    });

    test('copyWith updates properties properly', () {
      const original = TrackItem(
        id: '1',
        title: 'Title',
        artist: 'Artist',
        uri: 'spotify:track:1',
        rawQuery: 'Query',
      );

      final updated = original.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
      expect(updated.artist, equals('Artist'));
    });
  });
}
