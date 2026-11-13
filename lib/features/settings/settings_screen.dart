import 'package:flutter/material.dart';
import 'package:luma_tv/core/common/log.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:luma_tv/features/settings/tv_setting.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i("build setttings");
    final controller = context.watch<AppController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 56, 54),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TSpace(
              [TH2("设置"), TSubTitle("扫描、刮削与播放偏好")],
              alighment: WrapCrossAlignment.center,
              space: 16,
            ),
            TDivider(height: 28),

            TTitle("外观"),
            TvUI(),
            TDivider(),

            TTitle("刮削与元数据"),
            TvMeta(controller),
            TDivider(),

            TTitle("扫描"),
            TvScan(controller),
            TDivider(),

            TTitle("播放"),
            TvPlayer(controller),
            TDivider(),

            TTitle("媒体来源"),
            TvMediaSource(controller),
            TDivider(),

            TTitle("数据"),
            TDivider(),
            TvData(controller),

            TDivider(),
            Center(
              child: Column(
                children: [
                  TSpace([
                    TSubTitle(
                      controller.appVersion.isNotEmpty
                          ? controller.appVersion
                          : 'Luma',
                    ),
                    TSubTitle(
                      '海报与元数据由 TMDB 提供。本产品使用 TMDB API，但未获得 TMDB 认可或认证。',
                    ),
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
