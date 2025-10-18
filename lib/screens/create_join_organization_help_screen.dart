import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';

class CreateJoinOrganizationHelpScreen extends StatelessWidget {
  const CreateJoinOrganizationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final height = screenSize.height;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            spacing: 30,
            children: [
              SizedBox(height: height / 30),
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
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Icon(Icons.apartment_rounded, size: 42, color: colorPrimary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Text(
                          "Create An Organization",
                          style: textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Create an organization and invite your team members to collaborate on projects",
                          style: textTheme.bodyMedium!.copyWith(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Icon(Icons.people_alt_rounded, size: 42, color: colorPrimary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        SizedBox(),
                        Text(
                          "Join An Organization",
                          style: textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Join an existing organization using an invitation link or code",
                          style: textTheme.bodyMedium!.copyWith(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: height / 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: Colors.grey.shade200,
                  ),
                  child: Text("Get Started"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
