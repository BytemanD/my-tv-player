import 'package:flutter/material.dart';
import 'package:luma_tv/core/common/log.dart';
import 'package:luma_tv/widgets/luma_widgets/divider.dart';
import 'package:luma_tv/widgets/luma_widgets/space.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';
import 'package:luma_tv/features/settings/tv_setting.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i("build setttings");
    final controller = context.read<AppController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 56, 54),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LStrong("外观"),
            TvUI(),
            TDivider(),

            LStrong("刮削与元数据"),
            TvMeta(controller),
            TDivider(),

            LStrong("扫描"),
            TvScan(),
            TDivider(),

            LStrong("播放"),
            TvPlayer(),
            TDivider(),

            LStrong("媒体来源"),
            TvMediaSource(),
            TDivider(),

            LStrong("数据"),
            TvData(),

            TDivider(),
            Center(
              child: Column(
                children: [
                  LSpace([
                    LSubTitle(
                      controller.appVersion.isNotEmpty
                          ? controller.appVersion
                          : 'Luma',
                    ),
                    LSubTitle('海报与元数据由 TMDB和豆瓣 提供。'),
                  ], vertical: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
