import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/enums/login_status.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/repositories/company_repo.dart';
import 'package:smooflow/screens/create_join_organization_screen.dart';
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
      LoginService.isLoggedIn().then((IsLoggedInStatus isLoggedInStatus) async {
        await CompanyRepo.fetchCompanies();
        // await ProjectRepo().fetchProjects();

        // final status = await LoginService.relogin();

        // print("statu: ${status}");

        // return;

        final isLoggedIn =
            isLoggedInStatus.loginStatus == LoginStatus.success ||
            isLoggedInStatus.loginStatus == LoginStatus.noOrganization;

        final prefs = await SharedPreferences.getInstance();
        final orgId = prefs.getString(SharedStorageOptions.organizationId.name);

        if (isLoggedIn && orgId == null) {
          try {
            // orgId == null is taken care of, meaning set its value (Shard prefs key: SharedStorageOptions.organizationId.name) after re-logging in
            await LoginService.relogin();

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
            );
          } catch (e) {
            // Not linked to any organization

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder:
                    (context) => CreateJoinOrganizationScreen(
                      autoInviteOrganization:
                          isLoggedInStatus.autoInviteOrganization,
                    ),
              ),
              (Route<dynamic> route) => false,
            );
          }
          return;
        }

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
