import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/screens/home_screen.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final nameController = TextEditingController(),
      descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;

    final paddingValue = width / 14.2909;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
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
                  Text("Create Organization", style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      'Please enter your organization name to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name',
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
                  SizedBox(height: 25),
                  Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.description_outlined),
                      Text("Description", style: textTheme.titleMedium),
                    ],
                  ),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter description about your Organization',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();

                        if (name.length > 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Please ensure the organization name consists of at least 4 characters",
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                        });

                        await ref
                            .watch(organizationNotifierProvider.notifier)
                            .createOrganization(name);

                        setState(() {
                          _isLoading = false;
                        });

                        await Future.delayed(Duration(milliseconds: 5));

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                      child: Text("Create"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
