import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/components/discussion_forms.concept.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

const colorPrimary = Color(0xFF2563eb);
const colorLight = Color(0xFFf0f2fe);
const colorPositiveStatus = Color(0xFF19a74e);
const colorPurple = Color(0xFF9333ea);
const colorBorder = Color(0xFFf3f4f6);
const colorBorderDark = Color(0xFFe9e9ed);
const backgroundDarker2 = Color(0xFFf9fafc);
const backgroundDarker = Color(0xFFf8fafc);
const colorPending = Color(0xFFf59e0b);
const colorError = Color(0xFFd53d3c);
const colorErrorBackground = Color(0xFFfbebec);

const timelineRefreshIntervalSecs = 60;

const kOverallProgressHeroKey = "overall_progress";

final GlobalKey<ScaffoldMessengerState> kRootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final kNavigatorKey = GlobalKey<NavigatorState>();

final sampleMessages = [
  DiscussionMessage(
    id: '1',
    authorName: 'Alice Johnson',
    authorInitials: 'AJ',
    authorColor: Colors.blue,
    body: 'Hey everyone! Has anyone reviewed the latest design updates?',
    sentAt: DateTime.now().subtract(const Duration(minutes: 45)),
    isOwn: false,
  ),
  DiscussionMessage(
    id: '2',
    authorName: 'You',
    authorInitials: 'YO',
    authorColor: Colors.green,
    body: 'Yes, I checked them this morning. Looks much cleaner now.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 40)),
    isOwn: true,
  ),
  DiscussionMessage(
    id: '3',
    authorName: 'Michael Chen',
    authorInitials: 'MC',
    authorColor: Colors.orange,
    body: 'I agree. The new layout improves usability a lot.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 35)),
    isOwn: false,
  ),
  DiscussionMessage(
    id: '4',
    authorName: 'Sara Ahmed',
    authorInitials: 'SA',
    authorColor: Colors.purple,
    body: 'Did anyone notice the issue with the mobile view?',
    sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
    isOwn: false,
  ),
  DiscussionMessage(
    id: '5',
    authorName: 'You',
    authorInitials: 'YO',
    authorColor: Colors.green,
    body: 'Not yet, I’ll take a look and get back to you.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 25)),
    isOwn: true,
  ),
  DiscussionMessage(
    id: '6',
    authorName: 'Omar Khalid',
    authorInitials: 'OK',
    authorColor: Colors.red,
    body: 'I can help test it on Android devices.',
    sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
    isOwn: false,
  ),
];
