import 'package:flutter/material.dart';
import 'package:smooflow/screens/create_join_organization_help_screen.dart';

class CreateJoinOrganizationScreen extends StatelessWidget {
  const CreateJoinOrganizationScreen({super.key});

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
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
                Text("Create or Join", style: textTheme.headlineLarge),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      iconSize: 28,
                      foregroundColor: Colors.black,
                      side: BorderSide(width: 1, color: Colors.grey.shade200),
                      textStyle: textTheme.titleMedium,
                      padding: EdgeInsets.symmetric(
                        vertical: 17,
                      ).copyWith(left: 25),
                      alignment: Alignment.centerLeft,
                    ),
                    label: Text("Create Organization"),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.add_circle_rounded),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      iconSize: 28,
                      foregroundColor: Colors.black,
                      side: BorderSide(width: 1, color: Colors.grey.shade200),
                      textStyle: textTheme.titleMedium,
                      padding: EdgeInsets.symmetric(
                        vertical: 17,
                      ).copyWith(left: 25),
                      alignment: Alignment.centerLeft,
                    ),
                    label: Text("Join Organization"),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.people_rounded),
                    ),
                  ),
                ),
                SizedBox(height: 70),
                Text("Need help with this?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreateJoinOrganizationHelpScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text("Learn More"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
