import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  test('Placemark model sanity test', () {
    const placemark = Placemark(
      name: 'Panaji Church',
      street: 'Church Square',
      locality: 'Panaji',
    );
    expect(placemark.name, 'Panaji Church');
    expect(placemark.street, 'Church Square');
  });
}
