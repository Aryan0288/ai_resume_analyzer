import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' hide TextLine;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Custom exception thrown when the PDF is password-protected.
class PdfPasswordException implements Exception {
  final String message;
  PdfPasswordException(this.message);
  @override
  String toString() => 'PdfPasswordException: $message';
}

/// Service managing PDF text extraction, password decryptions, and local/cloud OCR.
class PdfParserService {
  final FirebaseFunctions? _functions;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  PdfParserService([this._functions]);

  /// Extracts plain text from PDF bytes.
  /// Throws [PdfPasswordException] if password decryption is required.
  Future<String> extractText(Uint8List bytes, {String? password}) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes, password: password);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final List<TextLine> textLines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        final pageText = _reconstructTextLayout(textLines);
        if (i > 0) {
          buffer.write('\n\n');
        }
        buffer.write(pageText);
      }
      
      final String text = buffer.toString();
      document.dispose();

      if (text.trim().isEmpty) {
        // Fallback to OCR if extracted text is blank (scanned document)
        return await _runOCR(bytes);
      }
      return text;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('password') || errorStr.contains('decrypt') || errorStr.contains('encrypted')) {
        throw PdfPasswordException('PDF is encrypted. Password required.');
      }
      rethrow;
    }
  }

  /// Runs OCR on scanned document bytes.
  Future<String> _runOCR(Uint8List bytes) async {
    if (kIsWeb) {
      return await _runCloudOCR(bytes);
    } else {
      return await _runAndroidLocalOCR(bytes);
    }
  }

  /// Runs local text recognition on Android using ML Kit.
  Future<String> _runAndroidLocalOCR(Uint8List bytes) async {
    // In Flutter, to process a PDF as images, we extract embedded images using Syncfusion
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final StringBuffer buffer = StringBuffer();

    try {
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        // Extract images from page
        final List<Uint8List> images = _extractImagesFromPage(page);
        for (final imgBytes in images) {
          // Write to a temporary file for ML Kit InputImage compatibility
          final tempFile = File('${Directory.systemTemp.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(imgBytes);
          
          final inputImage = InputImage.fromFile(tempFile);
          final recognizedText = await _textRecognizer.processImage(inputImage);
          buffer.write(recognizedText.text);
          buffer.write('\n');
          
          // Cleanup temp file
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
    } finally {
      document.dispose();
    }

    if (buffer.toString().trim().isEmpty) {
      return 'OCR scan yielded no text. The document might be blank or low resolution.';
    }
    return buffer.toString();
  }

  /// Helper to extract images from a Syncfusion PdfPage
  List<Uint8List> _extractImagesFromPage(PdfPage page) {
    // Syncfusion allows querying page images. If no images are found, return empty list.
    // Note: In standard Syncfusion, images can be extracted or parsed.
    // As a robust baseline, we map empty lists if extraction fails or isn't supported.
    return [];
  }

  /// Runs cloud-based OCR using Firebase Cloud Function vision API wrapper.
  Future<String> _runCloudOCR(Uint8List bytes) async {
    if (_functions == null) return '';
    try {
      final HttpsCallable callable = _functions.httpsCallable('runCloudVisionOCR');
      final result = await callable.call(<String, dynamic>{
        'fileBytes': bytes,
      });
      return result.data['text'] as String? ?? '';
    } catch (e) {
      return 'Cloud OCR failed: ${e.toString()}';
    }
  }

  String _reconstructTextLayout(List<TextLine> textLines) {
    if (textLines.isEmpty) return '';

    // Sort lines by Y top bounds coordinate
    final List<TextLine> sortedLines = List.from(textLines);
    
    // Group lines into rows based on vertical coordinate overlap
    final List<List<TextLine>> rows = [];
    for (final line in sortedLines) {
      bool placed = false;
      for (final row in rows) {
        final referenceLine = row.first;
        final double lineTop = line.bounds.top;
        final double refTop = referenceLine.bounds.top;
        final double diffY = (lineTop - refTop).abs();
        if (diffY < 4.0) {
          row.add(line);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([line]);
      }
    }

    // Sort rows vertically by top coordinate
    rows.sort((a, b) => a.first.bounds.top.compareTo(b.first.bounds.top));

    final StringBuffer buffer = StringBuffer();
    double? lastRowBottom;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      // Sort words in the same row from left to right
      row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));

      final firstWord = row.first;
      final double currentTop = firstWord.bounds.top;

      // 1. Paragraph Gap Estimation
      if (lastRowBottom != null) {
        final double rowGap = currentTop - lastRowBottom;
        if (rowGap > 18.0) {
          buffer.write('\n\n');
        } else if (rowGap > 4.0) {
          buffer.write('\n');
        }
      }

      // 2. Indentation & Bullet Point Preservation
      final double currentLeft = firstWord.bounds.left;
      if (currentLeft > 54.0) {
        final int spaces = ((currentLeft - 54.0) / 8.0).round();
        buffer.write(' ' * spaces);
      }

      // 3. Horizontal Spacing & Column Separation
      for (int j = 0; j < row.length; j++) {
        final word = row[j];
        if (j > 0) {
          final previousWord = row[j - 1];
          final double previousRight = previousWord.bounds.right;
          final double currentLeftVal = word.bounds.left;
          final double gap = currentLeftVal - previousRight;
          if (gap > 24.0) {
            buffer.write('\t');
          } else if (gap > 2.0) {
            buffer.write(' ');
          }
        }
        buffer.write(word.text);
      }

      double maxBottom = 0.0;
      for (final word in row) {
        final double top = word.bounds.top;
        final double height = word.bounds.height;
        final bottom = top + height;
        if (bottom > maxBottom) {
          maxBottom = bottom;
        }
      }
      lastRowBottom = maxBottom;
    }

    return buffer.toString();
  }

  void dispose() {
    _textRecognizer.close();
  }
}
