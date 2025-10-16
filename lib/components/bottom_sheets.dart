import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';

void showMaterialLogSheet(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  bool _isLogUpdateLoading = false;

  final content = StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return LoadingOverlay(
        isLoading: _isLogUpdateLoading,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    _isLogUpdateLoading ? null : () => Navigator.pop(context),
              ),
            ),
            BottomSheet(
              backgroundColor: Colors.grey.shade50,
              enableDrag: false,
              onClosing: () {},
              builder:
                  (context) => Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            Image.asset(
                              "assets/images/box_open.png",
                              width: 40,
                            ),
                            Text(
                              "Add Estimated Material",
                              style: textTheme.titleLarge,
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Material Description",
                          style: textTheme.titleMedium,
                        ),
                        TextField(
                          decoration: InputDecoration(
                            // suffix: Icon(
                            //   obscurePassword
                            //       ? Icons.visibility_off_outlined
                            //       : Icons.visibility_outlined,
                            // ),
                            hintText: 'Description',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 215, 219, 227),
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 215, 219, 227),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text("Quantity", style: textTheme.titleMedium),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            // suffix: Icon(
                            //   obscurePassword
                            //       ? Icons.visibility_off_outlined
                            //       : Icons.visibility_outlined,
                            // ),
                            hintText: 'Quantity',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 215, 219, 227),
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 215, 219, 227),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text("Size", style: textTheme.titleMedium),
                        Row(
                          spacing: 10,
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  // suffix: Icon(
                                  //   obscurePassword
                                  //       ? Icons.visibility_off_outlined
                                  //       : Icons.visibility_outlined,
                                  // ),
                                  hintText: 'Width',
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 215, 219, 227),
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 215, 219, 227),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  // suffix: Icon(
                                  //   obscurePassword
                                  //       ? Icons.visibility_off_outlined
                                  //       : Icons.visibility_outlined,
                                  // ),
                                  hintText: 'Height',
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 215, 219, 227),
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 215, 219, 227),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 50),
                        FilledButton(onPressed: () {}, child: Text("Save")),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      );
    },
  );

  if (Platform.isIOS) {
    showCupertinoSheet(context: context, pageBuilder: (context) => content);
  } else {
    showModalBottomSheet(context: context, builder: (context) => content);
  }
}
