import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/screens/home_screen.dart';

class ClaimOrganizationScreen extends ConsumerStatefulWidget {
  final String privateDomain;
  const ClaimOrganizationScreen({super.key, required this.privateDomain});

  @override
  ConsumerState<ClaimOrganizationScreen> createState() =>
      _ClaimOrganizationScreenState();
}

class _ClaimOrganizationScreenState
    extends ConsumerState<ClaimOrganizationScreen> {
  bool hasAgreedToTerms = false;

  bool _isLoading = false;

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
                      text: '@${widget.privateDomain}',
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
                    widget.privateDomain,
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
                  onPressed: () {
                    final content = StatefulBuilder(
                      builder: (context, setState) {
                        onAgreeTermsToggled(bool? newValue) {
                          setState(() {
                            hasAgreedToTerms = newValue ?? false;
                          });
                        }

                        void acceptAndClaimDomainOwnership() async {
                          late final message;

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await ref
                                .read(organizationNotifierProvider.notifier)
                                .claimDomainOwnership();

                            message =
                                "Successfully claimed ownership to this domain";
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          } catch (e) {
                            Navigator.pop(context);

                            message = e.toString();

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          }

                          setState(() {
                            _isLoading = false;
                          });
                        }

                        return LoadingOverlay(
                          isLoading: _isLoading,
                          child: AlertDialog(
                            content: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    width: 42,
                                    "assets/icons/app_icon.png",
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    "Domain Ownership Guideline",
                                    style: textTheme.headlineSmall!.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "By accepting ownership of this company domain, you agree that if an authorized representative or official owner of this domain submits a verified claim, our team will review and transfer domain ownership accordingly.",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    "In such a case, your organization will no longer be registered under this private domain, and automatic onboarding for new members into this organization will be disabled.",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      if (Platform.isIOS)
                                        CupertinoCheckbox(
                                          value: hasAgreedToTerms,
                                          onChanged: onAgreeTermsToggled,
                                        )
                                      else
                                        Checkbox(
                                          value: hasAgreedToTerms,
                                          onChanged: onAgreeTermsToggled,
                                        ),
                                      Expanded(
                                        child: Text(
                                          "I agree to the above terms",
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        disabledBackgroundColor:
                                            Colors.grey.shade200,
                                      ),
                                      onPressed:
                                          !hasAgreedToTerms
                                              ? null
                                              : acceptAndClaimDomainOwnership,
                                      child: Text("Accept & Continue"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    if (Platform.isIOS) {
                      showCupertinoDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return content;
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return content;
                        },
                      );
                    }
                  },
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
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
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
