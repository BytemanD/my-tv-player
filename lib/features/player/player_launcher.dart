import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../data/models.dart';
import 'player_screen.dart';

Future<void> openPlayer(
  BuildContext context,
  AppController controller,
  MediaItem media, {
  List<MediaItem>? queue,
}) async {
  final resolvedQueue = queue ?? controller.queueFor(media);
  var index = resolvedQueue.indexWhere((item) => item.id == media.id);
  if (index < 0) {
    // The item may not be present in a stale queue; fall back to a single item.
    resolvedQueue
      ..clear()
      ..add(media);
    index = 0;
  }
  await Navigator.of(context).push(
    PlayerScreen.route(
      controller: controller,
      queue: resolvedQueue,
      initialIndex: index,
    ),
  );
  await controller.refreshLibrary();
}
