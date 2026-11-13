import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/widgets/space.dart';

void showNotice(
  BuildContext context,
  String content, {
  String type = "default",
  int duration = 2,
}) {
  Color? color = switch (type) {
    "success" => Theme.of(context).extension<SemanticColors>()!.success,
    "error" => Theme.of(context).extension<SemanticColors>()!.danger,
    _ => null,
  };
  IconData icon = switch (type) {
    "success" => Icons.check_circle_outline,
    "error" => Icons.error_outline,
    _ => Icons.info_outline,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: TSpace([Icon(icon, color: Colors.white), Text(content)]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating, // 悬浮样式
      duration: Duration(seconds: duration),
      shape: RoundedRectangleBorder(
        // 自定义圆角
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
