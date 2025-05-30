import '../entities/password_entity.dart';

abstract class PasswordRepository {
  Future<void> addPassword(PasswordEntity entry);
  Future<List<PasswordEntity>> getAllPasswords();
  Future<void> deletePassword(int id);
  Future<void> updatePassword(PasswordEntity entry);
  Future<List<PasswordEntity>> searchByWebsite(String website);
  void dispose();
}
