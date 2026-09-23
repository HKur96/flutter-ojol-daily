import 'package:flutter_test/flutter_test.dart';
import 'package:ojol_daily/services/backup_service.dart';

void main() {
  group('BackupService Unit Tests', () {
    late BackupService backupService;

    setUp(() {
      backupService = BackupService();
    });

    test(
      '1. Valid JSON string parses correctly and returns summary statistics',
      () {
        final validJson = '''
      {
        "appName": "ojol_daily",
        "version": 1,
        "exportedAt": "2026-09-22T19:25:00.000Z",
        "tables": {
          "income_transactions": [
            {"id": "inc_1", "amount": 150000}
          ],
          "expense_transactions": [
            {"id": "exp_1", "amount": 25000}
          ],
          "obligation_definitions": [],
          "wallets": [
            {"id": "w_cash", "name": "Tunai"}
          ]
        }
      }
      ''';

        final summary = backupService.parseAndValidateBackup(validJson);

        expect(summary['appName'], equals('ojol_daily'));
        expect(summary['version'], equals(1));
        expect(summary['exportedAt'], equals('2026-09-22T19:25:00.000Z'));
        expect(summary['totalIncome'], equals(1));
        expect(summary['totalExpense'], equals(1));
        expect(summary['totalObligations'], equals(0));
        expect(summary['totalWallets'], equals(1));
      },
    );

    test('2. Empty JSON string throws FormatException', () {
      expect(
        () => backupService.parseAndValidateBackup('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('3. Invalid JSON structure throws FormatException', () {
      final invalidJson = 'Not a JSON text';

      expect(
        () => backupService.parseAndValidateBackup(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('4. JSON missing "tables" attribute throws FormatException', () {
      final missingTablesJson = '{"appName": "ojol_daily", "version": 1}';

      expect(
        () => backupService.parseAndValidateBackup(missingTablesJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
