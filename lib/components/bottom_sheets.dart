import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/models/material_log.dart';
import 'package:smooflow/providers/material_log_provider.dart';

void showMaterialLogSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) {
  final textTheme = Theme.of(context).textTheme;

  bool _isLogLoading = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController descriptionController = TextEditingController(),
      quantityController = TextEditingController(),
      widthController = TextEditingController(),
      heightController = TextEditingController();

  final content = StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return LoadingOverlay(
        isLoading: _isLogLoading,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isLogLoading ? null : () => Navigator.pop(context),
              ),
            ),
            BottomSheet(
              backgroundColor: Colors.grey.shade50,
              enableDrag: false,
              onClosing: () {},
              builder:
                  (context) => Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                "assets/images/box_open.png",
                                width: 40,
                              ),
                              SizedBox(width: 10),
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
                          TextFormField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Description',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD7DBE3),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD7DBE3),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Description is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Text("Quantity", style: textTheme.titleMedium),
                          TextFormField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Quantity',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD7DBE3),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD7DBE3),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              final num? parsed = num.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid number > 0';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Text("Size", style: textTheme.titleMedium),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: widthController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Width',
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFFD7DBE3),
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFFD7DBE3),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Width required';
                                    }
                                    final num? parsed = num.tryParse(value);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid width';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Height',
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFFD7DBE3),
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFFD7DBE3),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Height required';
                                    }
                                    final num? parsed = num.tryParse(value);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid height';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 50),
                          FilledButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) {
                                print('Form has errors.');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Please make sure to fill in all the inputs with valid data",
                                    ),
                                  ),
                                );
                              }

                              setState(() {
                                _isLogLoading = true;
                              });

                              await ref
                                  .watch(materialLogNotifierProvider.notifier)
                                  .addMaterialLog(
                                    MaterialLog.create(
                                      description: descriptionController.text,
                                      quantity: int.parse(
                                        quantityController.text,
                                      ),
                                      width: double.parse(widthController.text),
                                      height: double.parse(
                                        heightController.text,
                                      ),
                                      projectId: projectId,
                                    ),
                                  );

                              setState(() {
                                _isLogLoading = false;
                              });
                            },
                            child: Text("Save"),
                          ),
                          SizedBox(height: 100),
                        ],
                      ),
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
