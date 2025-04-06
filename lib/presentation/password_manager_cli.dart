import 'package:dart_console/dart_console.dart';
import 'commands.dart';
import '../data/repositories/password_repository.dart';

class PasswordManagerCLI {
  final PasswordRepositoryImpl _repository;
  final Console console = Console();
  final List<Command> commands = [
    AddPasswordCommand(),
    ListPasswordsCommand(),
    UpdatePasswordCommand(),
    SearchPasswordsCommand(),
    DeletePasswordCommand(),
  ];
  final List<String> menuOptions = [
    '1. Add Password',
    '2. List Passwords',
    '3. Update Password',
    '4. Search Passwords',
    '5. Delete Password',
    '6. Exit'
  ];

  PasswordManagerCLI(this._repository);

  Future<void> run() async {
    int selectedIndex = 0;
    bool exit = false;

    while (!exit) {
      _displayMenu(selectedIndex);
      final key = console.readKey();
      if (key.char == 'q') {
        exit = true;
      } else if (key.isControl && key.controlChar == ControlCharacter.enter) {
        if (selectedIndex == 5) {
          // Exit
          exit = true;
        } else {
          await commands[selectedIndex].execute(console, _repository);
        }
      } else if (key.isControl) {
        if (key.controlChar == ControlCharacter.arrowUp && selectedIndex > 0)
          selectedIndex--;
        if (key.controlChar == ControlCharacter.arrowDown &&
            selectedIndex < menuOptions.length - 1) selectedIndex++;
      }
    }
    _repository.dispose();
    console.setForegroundColor(ConsoleColor.green);
    console.writeLine('Goodbye!', TextAlignment.center);
    console.resetColorAttributes();
  }

  void _displayMenu(int selectedIndex) {
    console.clearScreen();
    console.setForegroundColor(ConsoleColor.green);
    console.writeLine('Password Manager', TextAlignment.center);
    console.resetColorAttributes();

    for (int i = 0; i < menuOptions.length; i++) {
      if (i == selectedIndex) {
        console.setBackgroundColor(ConsoleColor.blue);
        console.writeLine(menuOptions[i], TextAlignment.center);
        console.resetColorAttributes();
      } else {
        console.writeLine(menuOptions[i], TextAlignment.center);
      }
    }
    console.writeLine(
        'Use ↑↓ to navigate, Enter to select, q to quit', TextAlignment.center);
  }
}
