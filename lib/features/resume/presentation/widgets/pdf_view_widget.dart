import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'pdf_view_stub.dart'
    if (dart.library.html) 'pdf_view_web.dart';

class PdfViewWidget extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;

  const PdfViewWidget({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return buildPdfViewWidget(bytes, fileName);
  }
}
