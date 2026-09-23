import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ojol_daily/services/google_drive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleDriveService Unit Tests', () {
    late GoogleDriveService googleDriveService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      googleDriveService = GoogleDriveService();
    });

    test('1. Initial Google Sign-In state is empty/null', () async {
      final user = await googleDriveService.init();
      expect(user, isNull);
    });

    test('2. Uploading backup without active user returns false', () async {
      final mockJson = '{"appName": "ojol_daily", "version": 1, "tables": {}}';
      final success = await googleDriveService.uploadBackupToDrive(mockJson);
      expect(success, isFalse);
    });

    test('3. Sign out clears current user', () async {
      await googleDriveService.signOut();
      expect(googleDriveService.currentUser, isNull);
    });
  });
}
