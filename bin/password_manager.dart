import 'package:password_manager/data/repositories/password_repository.dart';
import 'package:password_manager/presentation/password_manager_cli.dart';

Future<void> main() async {
  final repository = PasswordRepositoryImpl();
  final cli = PasswordManagerCLI(repository);
  await cli.run(); // Now async
}
