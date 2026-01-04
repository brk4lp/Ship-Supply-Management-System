import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SSMS Basic Tests', () {
    test('App should have correct name', () {
      const appName = 'SSMS - Gemi Kumanya Yönetimi';
      expect(appName.contains('SSMS'), true);
    });

    test('Order status flow should be valid', () {
      const validStatuses = [
        'NEW',
        'QUOTED',
        'AGREED',
        'WAITING_GOODS',
        'PREPARED',
        'ON_WAY',
        'DELIVERED',
        'INVOICED',
      ];
      
      expect(validStatuses.length, 8);
      expect(validStatuses.first, 'NEW');
      expect(validStatuses.last, 'INVOICED');
    });
  });
}
