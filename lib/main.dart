import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/screens/admin_screen.dart';
import 'package:smooflow/screens/flash_screen.dart';
import 'package:smooflow/screens/production_dashboard.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main(List<String> args) async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch(settings.name) {
      case AppRoutes.: return ;
    }
    if (settings.name == '/detail') {
      final args = settings.arguments as DetailArgs;
      return MaterialPageRoute(
        builder: (_) => DetailScreen(args: args),
      );
    }
    throw Exception('Route not found');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme(
          brightness: Brightness.light, // You can choose light or dark here
          // primary: Colors.indigo, // Main button color
          primary: colorPrimary,
          onPrimary:
              Colors
                  .white, // Text/icons on primary color (White text for buttons)
          secondary: Color(0xFF00bcd4), // Secondary color, you can adjust this
          onSecondary: Colors.black, // Text/icons on secondary color
          error: Colors.red, // Error color, can use red or any color you prefer
          onError:
              Colors.white, // Text/icons on error color (White text for error)
          surface: Colors.white, // Surface background color (e.g., cards)
          onSurface:
              Colors.black, // Text/icons on surface background (Black text)
          background: Colors.grey[50]!, // Background color (light grey)
          onBackground:
              Colors.black, // Text/icons on background color (Black text)
        ),
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
      onGenerateRoute: ,
      home: AdminDashboardScreen(),
    );
  }
}
