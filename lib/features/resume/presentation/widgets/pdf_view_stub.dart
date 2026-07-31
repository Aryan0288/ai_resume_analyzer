import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Widget buildPdfViewWidget(Uint8List bytes, String fileName) {
  return SfPdfViewer.memory(
    bytes,
    enableDoubleTapZooming: true,
  );
}
