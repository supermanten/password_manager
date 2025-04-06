import 'dart:math';

import 'package:dcli/dcli.dart';
import '../data/repositories/password_repository.dart';
import '../domain/entities/password_entity.dart';

class PasswordManagerCLI {
  final PasswordRepositoryImpl _repository;

  PasswordManagerCLI(this._repository);

  Future<void> run() async {
    while (true) {
      print(green('Password Manager'));
      print('1. Add Password');
      print('2. List Passwords');
      print('3. Update Password');
      print('4. Search Passwords');
      print('5. Delete Password');
      print('6. Exit');

      final choice = ask('Select an option (1-4): ');

      try {
        switch (choice) {
          case '1':
            await _addPassword();
            break;
          case '2':
            await _showPasswords();
            break;
          case '3':
            await _updatePassword();
            break;
          case '4':
            await _searchByWebsite();
          case '5':
            await _deletePassword();
            break;
          case '6':
            _repository.dispose();
            print(green('Goodbye!'));
            return;
          default:
            print(red('Invalid option'));
        }
      } catch (e) {
        print(red('Error: $e'));
      }
    }
  }

  String _generatePassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String _checkPasswordStrength(String password) {
    if (password.length < 8) return 'Weak';
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$%^&*]'))) return 'Strong';
    return 'Medium';
  }

  void _printPasswordStrength(String password) {
    final stenght = _checkPasswordStrength(password);

    if (stenght == 'Weak') {
      print(red(
          'Password strength is weak. Please consider using a stronger password.'));
    } else if (stenght == 'Medium') {
      print(yellow(
          'Password strength is medium. Please consider using a stronger password.'));
    } else if (stenght == 'Strong') {
      print(green(
          'Password strength is strong. You can proceed with the password.'));
    }
  }

  Future<void> _addPassword() async {
    final website = ask('Enter website: ');
    final username = ask('Enter username: ');
    final passwordInput =
        ask('Enter password: ', hidden: true, required: false);
    final password =
        passwordInput.isEmpty ? _generatePassword(12) : passwordInput;

    final existing = await _repository.searchByWebsite(website);
    if (existing.any((e) => e.website == website && e.username == username)) {
      final choice = ask(yellow(
          'Warning: An entry for $website/$username already exists. Continue? (y/n): '));
      if ((choice).toLowerCase() != 'y') return;
    }

    _printPasswordStrength(password);
    _repository.addPassword(PasswordEntity(
      website: website,
      username: username,
      password: password,
    ));
    print(green('Password saved successfully'));
  }

  Future<void> _showPasswords() async {
    final passwords = await _repository.getAllPasswords();
    if (passwords.isEmpty) {
      print(yellow('No passwords stored'));
    } else {
      print(green('Stored Passwords:'));
      for (var entry in passwords) {
        print(blue('ID: ${entry.id}'));
        print('Website: ${entry.website}');
        print('Username: ${entry.username}');
        print('Password: ${entry.password}');
        print('---');
      }
    }
  }

  Future<void> _deletePassword() async {
    final passwords = await _repository.getAllPasswords();
    if (passwords.isEmpty) {
      print(red('No passwords stored'));
      return;
    }
    final idStr = ask(red('Enter password ID to delete: '));
    final id = int.tryParse(idStr);

    if (id == null) {
      print(red('Invalid ID'));
      return;
    }

    try {
      _repository.deletePassword(id);
      print(green('Password deleted successfully'));
    } catch (e) {
      print(red('Delete failed: $e'));
    }
  }

  Future<void> _updatePassword() async {
    final passwords = await _repository.getAllPasswords();
    if (passwords.isEmpty) {
      print(red('No passwords stored'));
      return;
    }
    final idStr = ask(orange('Enter password ID to update: '));
    final id = int.tryParse(idStr);

    // Show current entry (optional, for user reference)
    final entryToUpdate = passwords.firstWhere(
      (entry) => entry.id == id,
      orElse: () =>
          PasswordEntity(id: null, website: '', username: '', password: ''),
    );
    if (entryToUpdate.id == null) {
      print(red('No password found with ID $id'));
      return;
    }

    print(green('Current entry:'));
    print(blue('Website: ${entryToUpdate.website}'));
    print(blue('Username: ${entryToUpdate.username}'));
    print(blue('Password: ${entryToUpdate.password}'));
    print(orange('Leave blank to keep current value.'));

    final website = ask(green('Enter new website: '), required: false);
    final username = ask(green('Enter new username: '), required: false);
    final password = ask(green('Enter new password: '), required: false);

    final updatedEntry = PasswordEntity(
      id: id,
      website: website.isEmpty ? entryToUpdate.website : website,
      username: username.isEmpty ? entryToUpdate.username : username,
      password: password.isEmpty ? entryToUpdate.password : password,
    );

    _printPasswordStrength(password);

    await _repository.updatePassword(updatedEntry);
    print(red('Password updated successfully'));
  }

  Future<void> _searchByWebsite() async {
    final passwords = await _repository.getAllPasswords();
    if (passwords.isEmpty) {
      print(red('No passwords stored'));
      return;
    }
    final searchTerm = ask(green('Enter website name to search: '));

    final matches = await _repository.searchByWebsite(searchTerm);
    if (matches.isEmpty) {
      print(red('No matching records found for website "$searchTerm"'));
    } else {
      print(green('Matching Records:'));
      for (var entry in matches) {
        print(blue('ID: ${entry.id}'));
        print(blue('Website: ${entry.website}'));
        print(blue('Username: ${entry.username}'));
        print(blue('Password: ${entry.password}'));
        print(blue('---'));
      }
    }
  }
}
