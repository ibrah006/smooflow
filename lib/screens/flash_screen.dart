import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/components/ip_input_modal.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/create_join_organization_args.dart';
import 'package:smooflow/enums/login_status.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/core/repositories/company_repo.dart';
import 'package:smooflow/core/services/login_service.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {

  initialize() async {
    await LoginService.isLoggedIn().then((IsLoggedInStatus isLoggedInStatus) async {
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

          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.admin, predicate: (Route<dynamic> route) => false);
        } catch (e) {
          // Not linked to any organization

          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.createJoinOrg, arguments: CreateJoinOrganizationArgs(autoInviteOrganization:
                        isLoggedInStatus.autoInviteOrganization), predicate: (Route<dynamic> route) => false);
        }
        return;
      }

      // late final String route;
      // if (isLoggedIn) {
      //   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      //     final role = LoginService.currentUser!.role.toLowerCase();
      //     if (role == 'admin') {
      //       route = AppRoutes.adminDesktopDashboardScreen;
      //     } else if (role == 'production' || role == 'production-head') {
      //       route = AppRoutes.desktopMaterials;
      //     } else if (role == "design") {
      //       route = AppRoutes.designDashboard;
      //     }
      //   } else {
      //     // route = AppRoutes.admin;
      //     route = AppRoutes.productionDashboard;
      //   }
      // } else {
      //   route = AppRoutes.login;
      // }

      // AppRoutes.navigateAndRemoveUntil(context, route, predicate: (Route<dynamic> route) => false);

      AppRoutes.navigateAndRemoveUntil(context, AppRoutes.home, predicate: (Route<dynamic> route) => false);
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await initialize();
    });
  }

  void showIpInputModal(BuildContext context,
      {required Future<void> Function(String) onSave}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => IpInputModal(onSave: onSave),
    );
  }

  Future<void> onSave(String ip) async {
    ApiClient.localDevUrl = "http://$ip:3000";

    await initialize();
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            SizedBox(
              width: screenWidth < 340? screenWidth : 340,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Row(
                    spacing: 15,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(width: 60, "assets/icons/logo.svg"),
                      Text(
                        "smooflow",
                        style: textTheme.headlineLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 40,
                          fontFamily: "Plus Jakarta Sans",
                          letterSpacing: -1.5,
                          color: Color(0xFF0F172A)
                        ),
                      ),
                    ],
                  ),
                  Transform.rotate(
                    angle: pi/5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      child: Text("BETA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: "Plus Jakarta Sans", letterSpacing: 0, fontSize: 13)),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 13),
            Text(
              "Streamlining Large-Format Printing.",
              style: textTheme.bodyMedium!.copyWith(
                fontFamily: "Plus Jakarta Sans",
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 90, 96, 103)
              ),
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
