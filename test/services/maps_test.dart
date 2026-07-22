import 'package:daylane/services/maps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coordsFromUrl', () {
    test('формат /maps/search/lat,+lng (развёрнутая короткая ссылка)', () {
      expect(
        coordsFromUrl('https://www.google.com/maps/search/5.811698,+-55.118891'
            '?entry=tts&g_ep=EgoyMDI1MDEyOS4xIPu8ASoASAFQAw%3D%3D'),
        '5.811698,-55.118891',
      );
    });

    test('формат @lat,lng', () {
      expect(
        coordsFromUrl(
            'https://www.google.com/maps/place/X/@59.934280,30.335098,17z'),
        '59.934280,30.335098',
      );
    });

    test('формат !3d!4d (точный пин) важнее @', () {
      expect(
        coordsFromUrl('https://www.google.com/maps/place/X/@59.9,30.3,17z/'
            'data=!3m1!4b1!4m6!3m5!8m2!3d59.934280!4d30.335098'),
        '59.934280,30.335098',
      );
    });

    test('q=lat,lng', () {
      expect(coordsFromUrl('https://maps.google.com/?q=59.934,30.335'),
          '59.934,30.335');
    });

    test('короткая ссылка без координат — null', () {
      expect(coordsFromUrl('https://maps.app.goo.gl/TvPZdQo9HRmnfb4d8'), null);
    });
  });

  group('placeNameFromUrl', () {
    test('/maps/place/<name>/', () {
      expect(
        placeNameFromUrl(
            'https://www.google.com/maps/place/%D0%AD%D1%80%D0%BC%D0%B8%D1%82%D0%B0%D0%B6/@59.9,30.3,17z'),
        'Эрмитаж',
      );
    });

    test('координатное «название» отбрасывается', () {
      expect(
          placeNameFromUrl(
              'https://www.google.com/maps/place/59.93,30.33/@59.9,30.3'),
          null);
    });
  });

  group('isShortMapsLink', () {
    test('короткие', () {
      expect(isShortMapsLink('https://maps.app.goo.gl/TvPZdQo9HRmnfb4d8'),
          isTrue);
    });
    test('полные — нет', () {
      expect(isShortMapsLink('https://www.google.com/maps/place/X'), isFalse);
    });
  });
}
