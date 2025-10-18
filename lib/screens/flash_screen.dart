import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooflow/repositories/company_repo.dart';
import 'package:smooflow/repositories/project_repo.dart';
import 'package:smooflow/screens/home_screen.dart';
import 'package:smooflow/screens/login_screen.dart';
import 'package:smooflow/services/login_service.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      LoginService.isLoggedIn().then((isLoggedIn) async {
        await CompanyRepo.fetchCompanies();
        // await ProjectRepo().fetchProjects();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => isLoggedIn ? HomeScreen() : LoginScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(width: 60, "assets/icons/app_icon.png"),
                Text(
                  "Smooflow",
                  style: textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
              ],
            ),
            Lottie.asset(
              'assets/animations/loading.json',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}
