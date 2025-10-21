import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ClaimOrganizationScreen extends StatelessWidget {
  final String privateDomain;
  const ClaimOrganizationScreen({super.key, required this.privateDomain});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;

    final paddingValue = width / 14.2909;

    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: paddingValue),
          padding: EdgeInsets.all(paddingValue),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.02),
                spreadRadius: 5,
                blurRadius: 10,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(width: 42, "assets/icons/app_icon.png"),
                  Text(
                    "Smooflow",
                    style: textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "Do you own this Company?",
                style: textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  text: 'We noticed your email domain ',
                  style: TextStyle(fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(
                      text: '@${privateDomain}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          " hasn't been registered yet. If you're the owner or authorized representative, you can claim it to automatically onboard your team members when they sign up using the same domain.",
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
              SizedBox(height: 45),
              Row(
                spacing: 20,
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFf0f2f4),
                    child: Icon(
                      Icons.domain_outlined,
                      size: 23,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    privateDomain,
                    style: textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFf0f2f4),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.02),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Text("Unclaimed"),
                ),
              ),

              SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    "Accept & Claim Domain",
                    style: textTheme.titleMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    "Ignore / Decline",
                    style: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
