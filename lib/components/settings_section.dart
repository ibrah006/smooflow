import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/constants.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<ListTileItem> items;

  const SettingsSection({super.key, required this.title, required this.items});

  Widget _getTileTrailingWidget(ListTileItem item) {
    try {
      item.switchState;

      return Platform.isIOS
          ? CupertinoSwitch(value: item.switchState, onChanged: (neVal) {})
          : Switch(onChanged: (newVal) {}, value: item.switchState);
    } catch (e) {
      if (item.selectedOption != null) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child:
              item.isLoading == true
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(),
                  )
                  : Text(
                    item.selectedOption!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 17),
                  ),
        );
      } else if (item.infoText != null) {
        return Text(
          item.infoText!,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        );
      } else {
        return Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 26,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account
        Text(title),
        SizedBox(height: 13),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFfefefe),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children:
                items.map((item) {
                  final isHead = items.indexOf(item) == 0;
                  final isTail = items.indexOf(item) == items.length - 1;

                  return MaterialButton(
                    splashColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: isHead ? Radius.circular(13) : Radius.zero,
                        bottom: isTail ? Radius.circular(13) : Radius.zero,
                      ),
                    ),
                    onPressed:
                        item.onPressed != null
                            ? () {
                              HapticFeedback.lightImpact();
                              item.onPressed!();
                            }
                            : null,
                    child: Ink(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border:
                            items.indexOf(item) < items.length - 1
                                ? Border(bottom: BorderSide(color: colorBorder))
                                : null,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, color: Colors.black),
                          SizedBox(width: 13),
                          Text(item.title, style: textTheme.titleMedium),
                          Spacer(),
                          _getTileTrailingWidget(item),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// Helper
class ListTileItem {
  // Priority Level:
  // Switch
  // |
  // Selected Option
  // |
  // Info Text
  // |
  // Navigation button

  final IconData icon;
  final String title;

  String? selectedOption;

  late bool switchState;

  void Function()? onPressed;

  final String? infoText;

  //// Will need to keep [selectedOption] != null
  bool? isLoading;

  ListTileItem({
    required this.icon,
    required this.title,
    final bool? initialSwitchState,
    this.selectedOption,
    this.onPressed,
    this.infoText,
    this.isLoading,
  }) {
    if (initialSwitchState != null) switchState = initialSwitchState;
  }
}
