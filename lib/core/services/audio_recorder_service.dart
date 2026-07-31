import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Cross-platform audio recording abstraction.
/// Wraps the `record` package and provides amplitude streaming for waveform visualization.
/// Falls back gracefully on Web (no native filesystem access) by using in-memory bytes.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Amplitude stream for live waveform visualization
  StreamController<double>? _amplitudeController;
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;

  Timer? _amplitudeTimer;

  /// Start recording. Returns true if recording started successfully.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return false;

      _amplitudeController = StreamController<double>.broadcast();

      if (kIsWeb) {
        // Web: stream to memory
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        // Android / iOS: stream to temp file
        final path = '/tmp/interview_answer_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
      }

      _isRecording = true;

      // Poll amplitude every 100ms for waveform animation
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        try {
          final amp = await _recorder.getAmplitude();
          if (!(_amplitudeController?.isClosed ?? true)) {
            // Normalize dB to 0.0–1.0 range (typical range: -60dB to 0dB)
            final normalized = (amp.current + 60.0).clamp(0.0, 60.0) / 60.0;
            _amplitudeController?.add(normalized);
          }
        } catch (_) {}
      });

      return true;
    } catch (e) {
      debugPrint('[AudioRecorderService] startRecording error: $e');
      return false;
    }
  }

  /// Stop recording. Returns the file path (native) or null (web).
  Future<String?> stopRecording() async {
    try {
      _amplitudeTimer?.cancel();
      await _amplitudeController?.close();
      _amplitudeController = null;

      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('[AudioRecorderService] stopRecording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Check if the device microphone is available.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Cancel recording without saving.
  Future<void> cancelRecording() async {
    try {
      _amplitudeTimer?.cancel();
      await _amplitudeController?.close();
      _amplitudeController = null;
      await _recorder.stop();
      _isRecording = false;
    } catch (_) {}
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController?.close();
    _recorder.dispose();
  }
}
