import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final int? durationSeconds;

  const AudioMessageBubble({
    super.key,
    required this.url,
    required this.isMe,
    this.durationSeconds,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource(widget.url));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.durationSeconds ?? 0;
    final label = dur > 0 ? '${dur}s' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _toggle,
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }
}
