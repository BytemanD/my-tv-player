import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';

enum NoticeType { success, error }

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MessageController {
  Color? successColor;
  Color? errorColor;
  Color? infoColor;

  void init(BuildContext context) {
    successColor = Theme.of(context)
        .extension<SemanticColors>()
        ?.success
        .withValues(alpha: 0.7);
    errorColor = Theme.of(context)
        .extension<SemanticColors>()
        ?.danger
        .withValues(alpha: 0.7);
  }

  void _showSnapBar(String content, {NoticeType? type, int duration = 2}) {
    Color? color = switch (type) {
      NoticeType.success => successColor,
      NoticeType.error => errorColor,
      _ => null,
    };
    IconData icon = switch (type) {
      NoticeType.success => Icons.check_circle_outline,
      NoticeType.error => Icons.error_outline,
      _ => Icons.info_outline,
    };

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: TSpace([
          Icon(icon, color: Colors.white),
          TText(content, color: Colors.white),
        ]),
        width: 500,
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // 悬浮样式
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(
          // 自定义圆角
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  void success(String content, {int duration = 2}) {
    _showSnapBar(content, duration: duration, type: NoticeType.success);
  }

  void error(String content, {int duration = 2}) {
    _showSnapBar(content, duration: duration, type: NoticeType.success);
  }
}

final messageController = MessageController();
