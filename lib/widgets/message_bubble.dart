import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String type; // text / image / video / file / audio ...
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final Timestamp createdAt;
  final bool isSeen;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.type,
    required this.createdAt,
    required this.isSeen,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        TimeOfDay.fromDateTime(createdAt.toDate()).format(context);

    final bubbleColor = isMe
        ? const Color(0xff2f80ed)
        : const Color(0xffe9edf7);

    final textColor = isMe ? Colors.white : Colors.black87;

    Widget content;

    if (type == 'text') {
      content = Text(
        text ?? '',
        style: TextStyle(color: textColor, fontSize: 15),
      );
    } else if (type == 'image') {
      content = Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl!,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          if ((text ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text!,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ],
        ],
      );
    } else if (type == 'video') {
      content = Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: 220,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.08),
            ),
            child: const Icon(Icons.play_circle_fill, size: 48),
          ),
          const SizedBox(height: 4),
          Text(
            'فيديو',
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ],
      );
    } else if (type == 'audio') {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_rounded, size: 18),
          const SizedBox(width: 8),
          Text(
            'رسالة صوتية',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName ?? 'ملف',
              style: TextStyle(color: textColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                content,
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isSeen
                            ? Icons.done_all_rounded
                            : Icons.check_rounded,
                        size: 14,
                        color: isSeen
                            ? Colors.lightBlueAccent
                            : textColor.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}