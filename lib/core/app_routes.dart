// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/args/claim_organization_args.dart';
import 'package:smooflow/core/args/materials_preview_args.dart';
import 'package:smooflow/core/args/project_args.dart';
import 'package:smooflow/core/args/schedule_print_job_args.dart';
import 'package:smooflow/models/printer.dart';
import 'package:smooflow/screens/login_screen.dart';
import 'package:smooflow/screens/printer_screen.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/screens/create_join_organization_help_screen.dart';
import 'package:smooflow/screens/create_organization_screen.dart';
import 'package:smooflow/screens/flash_screen.dart';
import 'package:smooflow/screens/home_screen.dart';
import 'package:smooflow/screens/invite_member_screen.dart';
import 'package:smooflow/screens/production_dashboard.dart';
import 'package:smooflow/screens/progress_log_screen.dart';
import 'package:smooflow/screens/project_progress_screen.dart';
import 'package:smooflow/screens/project_report_screen.dart';
import 'package:smooflow/screens/project_screen.dart';
import 'package:smooflow/screens/schedule_print_job_screen.dart';

// Auth & Onboarding
import '../screens/claim_organization_screen.dart';

// Materials & Stock
import '../screens/materials_preview_screen.dart';
import '../screens/material_stock_transactions_screen.dart';
import '../screens/stock_entry_screen.dart';
import '../screens/stock_entry_checkout_screen.dart';

// Barcode
import '../screens/barcode_scan_page.dart';
import '../screens/barcode_export_screen.dart';

// Projects & Tasks
import '../screens/production_project_screen.dart';
import '../screens/project_timeline_screen.dart';
import '../screens/create_task_screen.dart';
import '../screens/task_screen.dart';
import '../screens/tasks_screen.dart';

// Production / Scheduling
import '../screens/add_project_progress_screen.dart';

import '../screens/admin_screen.dart';

// Import all args
import 'package:smooflow/core/args/add_project_progress_args.dart';
import 'package:smooflow/core/args/barcode_scan_args.dart';
import 'package:smooflow/core/args/create_task_args.dart';
import 'package:smooflow/core/args/export_barcodes_args.dart';
import 'package:smooflow/core/args/material_stock_transaction_args.dart';
import 'package:smooflow/core/args/production_project_args.dart';
import 'package:smooflow/core/args/project_timeline_args.dart';
import 'package:smooflow/core/args/stock_details_args.dart';
import 'package:smooflow/core/args/stock_entry_args.dart';
import 'package:smooflow/core/args/task_args.dart';
import 'package:smooflow/core/args/tasks_args.dart';

class AppRoutes {
  // -------------------
  // Route Names
  // -------------------

  static const flash = '/';
  static const login = '/login';
  static const home = '/home';

  static const createOrganization = '/create-organization';
  static const joinOrganization = '/join-organization';
  static const claimOrganization = '/claim-organization';
  static const createJoinOrg = '/create-join-organization';
  static const createJoinOrgHelp = '/create-join-organization-help';
  static const inviteMember = '/invite-member';

  static const admin = '/admin';
  static const settings = '/settings';
  static const profileSettings = '/settings/profile';
  static const manageUsers = '/settings/manage-users';

  static const materials = '/materials';
  static const materialPreview = '/materials/preview';
  static const desktopMaterials = '/materials/desktop-list';
  static const desktopMaterialView = '/materials/desktop-details';
  static const materialsStock = '/materials/stock';
  static const materialTransactions = '/materials/transactions';

  static const stockInEntry = '/stock-in-entry';
  static const stockOutEntry = '/stock-out-entry';
  static const stockCheckout = '/stock-checkout';

  static const barcodeScanIn = '/barcode/scan/in';
  static const barcodeScanOut = '/barcode/scan/out';
  static const barcodeExport = '/barcode/export';

  static const projects = '/projects';
  static const projectProduction = '/projects/production';
  static const timeline = '/projects/timeline';
  static const addProject = '/projects/add';
  static const viewProject = '/projects/view';

  static const addProjectProgress = '/projects/add-progress';
  static const addProjectProgressView = '/projects/add-progress/view';

  static const createTask = '/tasks/create';
  static const task = '/task';
  static const tasks = '/tasks';

  static const productionDashboard = '/production';
  static const schedulePrint = '/print-schedule';
  static const schedulePrintView = '/print-schedule/view';

  static const addPrinter = '/printers/add';
  static const printerDetails = '/printers/details';

  static const createClient = '/clients/create';

  static const googleSheetViewer = '/google-sheet';

  static const projectProgress = '/project/progress';

  // Admin reports
  static const projectReport = '/admin/project-report';
  static const productionReport = '/admin/production-report';

  // -------------------
  // Route Map
  // -------------------

  // static final Map<String, WidgetBuilder> routes = {
  //   // Auth
  //   flash: (_) => const FlashScreen(),
  //   login: (_) => const LoginScreen(),

  //   // Home
  //   home: (_) => const HomeScreen(),

  //   // Organization
  //   createOrganization: (_) => CreateOrganizationScreen(),
  //   joinOrganization: (_) => JoinOrganizationScreen(),
  //   claimOrganization: (_) => const ClaimOrganizationScreen(),
  //   createJoinOrg: (_) => const CreateJoinOrganizationScreen(),
  //   createJoinOrgHelp: (_) => const CreateJoinOrganizationHelpScreen(),
  //   inviteMember: (_) => const InviteMemberScreen(),

  //   // Admin & Settings
  //   admin: (_) => const AdminDashboardScreen(),
  //   settings: (_) => const SettingsScreen(),
  //   profileSettings: (_) => SettingsProfileScreen(),
  //   manageUsers: (_) => const SettingsManageUsersScreen(),

  //   // Materials & Stock
  //   materials: (_) => const MaterialsScreen(),
  //   materialPreview: (_) => const MaterialsPreviewScreen(),
  //   desktopMaterials: (_) => const DesktopMaterialListScreen(),
  //   // desktopMaterialView: (_) => const DesktopMaterialDetailsScreen(),
  //   materialsStock: (_) => const MaterialsStockScreen(),
  //   materialTransactions: (_) => const MaterialStockTransactionsScreen(),

  //   stockInEntry: (_) => StockEntryScreen.stockin(),
  //   stockOutEntry: (_) => StockEntryScreen.stockOut(),
  //   stockCheckout: (_) => const StockEntryDetailsScreen(),

  //   // Barcode
  //   barcodeScanIn: (_) => BarcodeScanScreen.stockIn(),
  //   barcodeScanOut: (_) => BarcodeScanScreen.stockOut(),
  //   barcodeExport: (_) => const ExportBarcodesScreen(),

  //   // Projects
  //   projects: (_) => const ProjectsScreen(),
  //   projectProduction: (_) => const ProductionProjectScreen(),
  //   timeline: (_) => const ProjectTimelineScreen(),
  //   addProject: (_) => AddProjectScreen(),

  //   addProjectProgress: (_) => const AddProjectProgressScreen(),
  //   addProjectProgressView: (_) => const AddProjectProgressScreen.view(),

  //   // Tasks
  //   createTask: (_) => const CreateTaskScreen(),
  //   task: (_) => const TaskScreen(),
  //   tasks: (_) => const TasksScreen(),

  //   // Production
  //   productionDashboard: (_) => const ProductionDashboardScreen(),
  //   schedulePrint: (_) => const ScheduleJobScreen(),

  //   // Printer
  //   addPrinter: (_) => const AddPrinterScreen(),

  //   // Clients
  //   createClient: (_) => CreateClientScreen(),

  //   // Misc
  //   googleSheetViewer: (_) => const GoogleSheetViewer(),
  // };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Extract route name and arguments
    final routeName = settings.name;
    final args = settings.arguments;

    // Route builder helper
    Widget? screen;

    switch (routeName) {
      case flash:
        screen = const FlashScreen();
        break;
      // ===== Organization =====
      case claimOrganization:
        if (args is ClaimOrganizationArgs) {
          screen = ClaimOrganizationScreen(privateDomain: args.privateDomain);
        }
        break;
      case login:
        screen = LoginScreen();
        break;
      case createOrganization:
        screen = CreateOrganizationScreen();
        break;
      case joinOrganization:
        screen = CreateOrganizationScreen();
        break;
      case createJoinOrgHelp:
        screen = const CreateJoinOrganizationHelpScreen();
        break;

      // ===== Materials & Stock =====
      case materialPreview:
        if (args is MaterialsPreviewArgs) {
          screen = MaterialsPreviewScreen(materials: args.materials);
        }
        break;

      case materialTransactions:
        if (args is MaterialStockTransactionArgs) {
          screen = MaterialStockTransactionsScreen(materialId: args.materialId);
        }
        break;

      case stockInEntry:
        if (args is StockEntryArgs) {
          screen = StockEntryScreen.stockin(material: args.material);
        }
        break;
      case stockOutEntry:
        if (args is StockEntryArgs) {
          screen = StockEntryScreen.stockOut(
            material: args.material,
            transaction: args.transaction,
            projectId: args.projectId,
          );
        }
        break;

      case stockCheckout:
        if (args is StockDetailsArgs) {
          screen = StockEntryDetailsScreen(
            args.transaction,
            materialType: args.materialType,
            measureType: args.measureType,
            barcode: args.barcode,
          );
        }
        break;

      // ===== Barcode =====
      case barcodeScanIn:
        screen = BarcodeScanScreen.stockIn();
        break;

      case barcodeScanOut:
        if (args is BarcodeScanArgs) {
          screen = BarcodeScanScreen.stockOut(projectId: args.projectId);
        }
        break;

      case barcodeExport:
        if (args is ExportBarcodesArgs) {
          screen = ExportBarcodesScreen(barcodes: args.barcodes);
        }
        break;

      // ===== Projects =====
      case projectProduction:
        if (args is ProductionProjectArgs) {
          screen = ProductionProjectScreen(projectId: args.projectId);
        }
        break;

      case timeline:
        if (args is ProjectTimelineArgs) {
          screen = ProjectTimelineScreen(projectId: args.projectId);
        }
        break;

      case addProjectProgress:
        if (args is AddProjectProgressArgs) {
          screen = AddProjectProgressScreen(args.projectId);
        }
        break;

      // ===== Tasks =====
      case createTask:
        if (args is CreateTaskArgs) {
          screen = CreateTaskScreen(projectId: args.projectId);
        }
        break;

      case task:
        if (args is TaskArgs) {
          screen = TaskScreen(args.taskId);
        }
        break;

      case tasks:
        if (args is TasksArgs) {
          screen = TasksScreen(projectId: args.projectId);
        }
        break;
      case admin:
        screen  = const AdminDashboardScreen();
        break;
      case addProject:
        screen = AddProjectScreen();
        break;
      case viewProject:
        if (args is ProjectArgs) {
          // screen = AddProjectScreen.view(projectId: args.projectId);
          screen = ProjectScreen(projectId: args.projectId);
        }
        break;
      case inviteMember:
        screen = const InviteMemberScreen();
        break;
      case addPrinter:
        screen = const PrinterScreen.add();
        break;
      case home:
        screen = HomeScreen();
        break;
      case projectReport:
        screen = const ProjectReportsScreen();
        break;
      case productionDashboard:
        screen = const ProductionDashboardScreen();
        break;
      case printerDetails:
        if (args is Printer) {
          screen = PrinterScreen.details(printer: args);
        }
        break;
      case schedulePrintView:
        if (args is SchedulePrintJobArgs) {
          screen = ScheduleJobScreen.details(projectId: args.projectId, task: args.task);
        }
        break;
      case projectProgress:
        if (args is ProjectArgs) {
          screen = ProjectProgressLogScreen(projectId: args.projectId);
        }
        break;
      case addProjectProgressView:
        if (args is AddProjectProgressArgs) {
          screen = ProgressLogScreen(progressLog: args.progressLog, projectId: args.projectId);
        }
        break;
    }

    // If screen was determined, create the route
    if (screen != null) {
      return MaterialPageRoute(builder: (_) => screen!, settings: settings);
    }

    // Route not found - return null to trigger onUnknownRoute
    return null;
  }

  // -------------------
  // onUnknownRoute (404 handler)
  // -------------------
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder:
          (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '404 - Route Not Found',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Route: ${settings.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back or to home
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(home, (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
      settings: settings,
    );
  }

  // -------------------
  // Helper methods for navigation with arguments
  // -------------------

  // Navigate to a route with arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  // Navigate and replace current route
  static Future<T?> navigateReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // Navigate and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }
}
