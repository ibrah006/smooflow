import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:smooflow/constants.dart';

class GoogleSheetViewer extends StatefulWidget {
  const GoogleSheetViewer({super.key});

  @override
  State<GoogleSheetViewer> createState() => _GoogleSheetViewerState();
}

class _GoogleSheetViewerState extends State<GoogleSheetViewer> {
  List<List<String>> _sheetValues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSheetData();
  }

  Future<void> _fetchSheetData() async {
    try {
      // Load service account credentials from assets
      final credentialsJson = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/credentials.json');

      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        jsonDecode(credentialsJson),
      );

      const scopes = [sheets.SheetsApi.spreadsheetsReadonlyScope];

      // Authorize and create client
      final client = await clientViaServiceAccount(accountCredentials, scopes);

      // Access the Sheets API
      final sheetsApi = sheets.SheetsApi(client);

      // Replace with your own spreadsheet ID and sheet name
      const spreadsheetId = '19lJBe3MTVHA1UaejBL1TKTbEy3a-IGuUvlPA9HcyGW8';
      const range = 'Sheet1!A1:Z100'; // adjust as needed

      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        range,
      );

      final values = response.values;

      setState(() {
        _sheetValues =
            values
                ?.map((row) => row.map((cell) => cell.toString()).toList())
                .toList() ??
            [];
        _loading = false;
      });

      client.close();
    } catch (e) {
      debugPrint('Error loading sheet: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheet Viewer'),
        foregroundColor: Colors.white,
        backgroundColor: colorPrimary,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _sheetValues.isEmpty
              ? const Center(child: Text('No data found.'))
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => colorPrimary.withValues(alpha: 0.1),
                    ),
                    border: TableBorder.all(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    columns:
                        _sheetValues.first
                            .map(
                              (header) => DataColumn(
                                label: Text(
                                  header,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    rows:
                        _sheetValues
                            .skip(1)
                            .map(
                              (row) => DataRow(
                                cells:
                                    row
                                        .map((cell) => DataCell(Text(cell)))
                                        .toList(),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
    );
  }
}
