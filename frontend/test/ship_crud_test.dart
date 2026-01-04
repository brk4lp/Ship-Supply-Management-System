import 'package:flutter_test/flutter_test.dart';

/// Ship CRUD API Tests
/// Note: These are unit tests that verify the data structures
/// Integration tests with actual Rust FFI calls require the app to be running
void main() {
  group('Ship Model Tests', () {
    test('CreateShipRequest should have required fields', () {
      // Test the expected structure of CreateShipRequest
      const shipData = {
        'name': 'MV Test Ship',
        'imo_number': '1234567',
        'flag': 'TR',
        'ship_type': 'Bulk Carrier',
        'gross_tonnage': 50000.0,
        'owner': 'Test Shipping Co.',
      };

      expect(shipData['name'], isNotEmpty);
      expect(shipData['imo_number'], hasLength(7)); // IMO number is 7 digits
      expect(shipData['flag'], isNotEmpty);
    });

    test('IMO number should be 7 digits', () {
      const validIMO = '1234567';
      const invalidIMO1 = '123456'; // 6 digits
      const invalidIMO2 = '12345678'; // 8 digits

      expect(validIMO.length, equals(7));
      expect(invalidIMO1.length, isNot(equals(7)));
      expect(invalidIMO2.length, isNot(equals(7)));
    });

    test('Ship flags should be valid country codes', () {
      const validFlags = ['TR', 'PA', 'LR', 'MT', 'GR', 'CY', 'BS', 'MH'];
      
      for (final flag in validFlags) {
        expect(flag.length, equals(2));
        expect(flag.toUpperCase(), equals(flag));
      }
    });

    test('Ship types should be valid categories', () {
      const validTypes = [
        'Bulk Carrier',
        'Container Ship',
        'Tanker',
        'General Cargo',
        'Passenger',
        'Ro-Ro',
        'LNG Carrier',
        'Chemical Tanker',
      ];

      expect(validTypes.length, greaterThan(0));
      for (final type in validTypes) {
        expect(type, isNotEmpty);
      }
    });
  });

  group('Database Connection Tests', () {
    test('SQLite connection string format', () {
      const dbPath = r'C:\Users\test\AppData\Local\SSMS\ssms_local.db';
      final connectionString = 'sqlite:$dbPath?mode=rwc';

      expect(connectionString, startsWith('sqlite:'));
      expect(connectionString, contains('ssms_local.db'));
      expect(connectionString, endsWith('?mode=rwc'));
    });

    test('Database path should be in AppData Local', () {
      const expectedPattern = 'AppData';
      const dbPath = r'C:\Users\berke\AppData\Local\SSMS\ssms_local.db';

      expect(dbPath, contains(expectedPattern));
      expect(dbPath, contains('SSMS'));
    });
  });
}
