// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';
import 'package:flutter/material.dart';

Widget buildPdfViewWidget(Uint8List bytes, String fileName) {
  final String viewType = 'pdf-iframe-${bytes.length}-${bytes.hashCode}';
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Register iframe factory for Chrome native PDF renderer
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final element = html.IFrameElement()
        ..src = '$url#toolbar=0&navpanes=0&scrollbar=0&view=FitH'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..setAttribute('scrolling', 'no');
      return element;
    },
  );

  return HtmlElementView(viewType: viewType);
}
