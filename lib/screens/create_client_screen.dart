import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/company.dart';
import 'package:smooflow/repositories/company_repo.dart';

class CreateClientScreen extends StatelessWidget {
  CreateClientScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  InputDecoration _inputDecoration(String hint, {Color? backgroundColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: backgroundColor != null,
      fillColor: backgroundColor,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorError),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Wrap(
              // alignment: WrapAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorPrimary.withValues(alpha: 0.03),
                      ),
                      color: colorPrimary,
                      icon: Icon(
                        Platform.isIOS
                            ? Icons.chevron_left_rounded
                            : Icons.arrow_back_rounded,
                        size: 25,
                      ),
                    ),
                    Text(
                      "Create Client",
                      style: textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                // Project Name
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: const Text(
                    "Client Name*",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("Enter Client name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Client name is required";
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                //
                TextField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                    "Add description/note for client",
                  ),
                  maxLines: 3,
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 35),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      textStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final isValid =
                          _formKey.currentState?.validate() ?? false;
                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Make sure to fill in the required inputs",
                            ),
                          ),
                        );
                        return;
                      }

                      final errorMessage = await CompanyRepo.createCompany(
                        Company.create(
                          name: _nameController.text,
                          description: _descriptionController.text,
                        ),
                      );

                      if (errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "A Client with this name already exists",
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                    },

                    child: Text("Create"),
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
