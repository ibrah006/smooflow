import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/screens/home_screen.dart';
import 'package:smooflow/repositories/company_repo.dart';
import 'package:smooflow/repositories/project_repo.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await CompanyRepo.fetchCompanies();
  await ProjectRepo().fetchProjects();

  runApp(ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: colorPrimary,
        dividerTheme: DividerThemeData(color: colorLight),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(colorPrimary),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.all(18)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                fontSize: 17,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            foregroundColor: WidgetStatePropertyAll(Colors.grey.shade700),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colorPrimary),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
