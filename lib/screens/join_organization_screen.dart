import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinOrganizationScreen extends ConsumerWidget {
  JoinOrganizationScreen({super.key});

  final invitationIdController = TextEditingController();

  @override
  Widget build(BuildContext context, ref) {
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
                Text("Join your Organization", style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Join Organization and Collaborate on projects',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: invitationIdController,
                  decoration: InputDecoration(
                    hintText: 'Enter invitation ID',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                    ),
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      // final name = nameController.text;

                      // await ref
                      //     .watch(organizationNotifierProvider.notifier)
                      //     .createOrganization(name);
                    },
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: Text("Join"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
