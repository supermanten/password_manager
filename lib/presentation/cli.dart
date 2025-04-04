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
      print('3. Delete Password');
      print('4. Exit');

      final choice = ask('Select an option (1-4): ');

      try {
        switch (choice) {
          case '1':
            _addPassword();
            break;
          case '2':
            await _showPasswords();
            break;
          case '3':
            _deletePassword();
            break;
          case '4':
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

  void _addPassword() {
    final website = ask('Enter website: ');
    final username = ask('Enter username: ');
    final password = ask('Enter password: ', hidden: true);

    if (website.isEmpty || username.isEmpty || password.isEmpty) {
      print(red('All fields are required'));
      return;
    }

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

  void _deletePassword() {
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
}
