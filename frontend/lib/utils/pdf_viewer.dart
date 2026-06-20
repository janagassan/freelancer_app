// frontend/lib/utils/pdf_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:fluttertoast/fluttertoast.dart';

class PDFViewer {
  static const String baseUrl = 'https://freelancer-app-h6os.onrender.com';

  static Future<void> openPDF(String pdfPath) async {
    try {
      final fullUrl = pdfPath.startsWith('http') ? pdfPath : '$baseUrl$pdfPath';

      if (kIsWeb) {
        await launchUrl(
          Uri.parse(fullUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        final uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Fluttertoast.showToast(msg: 'Cannot open PDF file');
        }
      } else {
        await launchUrl(
          Uri.parse(fullUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error opening PDF: $e');
    }
  }

  static Future<void> downloadPDF(String pdfPath, String fileName) async {
    try {
      final fullUrl = pdfPath.startsWith('http') ? pdfPath : '$baseUrl$pdfPath';

      Fluttertoast.showToast(msg: 'Download started: $fileName');

      await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading PDF: $e');
    }
  }
}
