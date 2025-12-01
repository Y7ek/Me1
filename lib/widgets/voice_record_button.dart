import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordButton extends StatefulWidget {
  final Future<void> Function(File file, int durationSeconds) onRecorded;

  const VoiceRecordButton({
    super.key,
    required this.onRecorded,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startTime;

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _startTime = DateTime.now();
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      final file = File(path);
      final durationSec = _startTime == null
          ? 0
          : DateTime.now().difference(_startTime!).inSeconds;
      await widget.onRecorded(file, durationSec == 0 ? 1 : durationSec);
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startRecording,
      onLongPressUp: _stopRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isRecording
              ? Colors.redAccent.withOpacity(0.15)
              : Theme.of(context).colorScheme.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          color: _isRecording
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
