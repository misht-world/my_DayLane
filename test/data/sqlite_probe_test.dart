import 'package:drift/native.dart';
import 'package:daylane/data/db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('in-memory drift works in flutter test', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = await db.readSyncState();
    expect(state.aggregates, isEmpty);
    await db.close();
  });
}
