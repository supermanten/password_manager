import 'dart:io';
import '../data/repositories/password_repository.dart';
import '../domain/entities/password_entity.dart';

class PasswordManagerCLI {
  final PasswordRepositoryImpl _repository;

  PasswordManagerCLI(this._repository);

  Future<void> run() async {
    // Now async
    while (true) {
      stdout.writeln('Password Manager');
      stdout.writeln('1. Add Password');
      stdout.writeln('2. List Passwords');
      stdout.writeln('3. Delete Password');
      stdout.writeln('4. Exit');

      stdout.write('Select an option (1-4): ');
      final choice = stdin.readLineSync() ?? '';

      try {
        switch (choice) {
          case '1':
            _addPassword();
            break;
          case '2':
            await _showPasswords(); // Await the async method
            break;
          case '3':
            _deletePassword();
            break;
          case '4':
            _repository.dispose();
            stdout.writeln('Goodbye!');
            return;
          default:
            stdout.writeln('Invalid option');
        }
      } catch (e) {
        stdout.writeln('Error: $e');
      }
    }
  }

  void _addPassword() {
    stdout.write('Enter website: ');
    final website = stdin.readLineSync() ?? '';
    stdout.write('Enter username: ');
    final username = stdin.readLineSync() ?? '';
    stdout.write('Enter password: ');
    final password = stdin.readLineSync() ?? '';

    if (website.isEmpty || username.isEmpty || password.isEmpty) {
      stdout.writeln('All fields are required');
      return;
    }

    _repository.addPassword(PasswordEntity(
      website: website,
      username: username,
      password: password,
    ));
    stdout.writeln('Password saved successfully');
  }

  Future<void> _showPasswords() async {
    // Now async
    final passwords = await _repository.getAllPasswords();
    if (passwords.isEmpty) {
      stdout.writeln('No passwords stored');
    } else {
      stdout.writeln('Stored Passwords:');
      for (var entry in passwords) {
        stdout.writeln('ID: ${entry.id}');
        stdout.writeln('Website: ${entry.website}');
        stdout.writeln('Username: ${entry.username}');
        stdout.writeln('Password: ${entry.password}');
        stdout.writeln('---');
      }
    }
  }

  void _deletePassword() {
    stdout.write('Enter password ID to delete: ');
    final idStr = stdin.readLineSync() ?? '';
    final id = int.tryParse(idStr);

    if (id == null) {
      stdout.writeln('Invalid ID');
      return;
    }

    try {
      _repository.deletePassword(id);
      stdout.writeln('Password deleted successfully');
    } catch (e) {
      stdout.writeln('Delete failed: $e');
    }
  }
}
