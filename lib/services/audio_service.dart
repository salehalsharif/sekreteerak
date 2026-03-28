import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service to handle audio recording for voice input
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('لم يتم منح صلاحية الميكروفون');
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'voice_${const Uuid().v4()}.m4a';
    _currentPath = '${dir.path}/$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );

    _isRecording = true;
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    return path;
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;

    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentPath = null;
  }

  /// Get recording amplitude for visualizing waveform
  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  /// Dispose the recorder
  void dispose() {
    _recorder.dispose();
  }
}
