import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/data/settings_service.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:media_kit/media_kit.dart';

/// 播放器右侧配置面板（endDrawer）。
///
/// 所有状态由父级持有并通过回调回写，该 Widget 仅负责渲染。
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.controller,
    required this.player,
    required this.speed,
    required this.fit,
    required this.panelMessage,
    required this.onSpeedChanged,
    required this.onFitChanged,
    required this.onSubtitleChanged,
    required this.onAudioChanged,
    required this.onPlayNext,
    required this.onSeekIntervalChanged,
    required this.onPanelMessageChanged,
  });

  final AppController controller;
  final Player player;
  final double speed;
  final BoxFit fit;
  final String? panelMessage;

  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<BoxFit> onFitChanged;
  final ValueChanged<SubtitleTrack> onSubtitleChanged;
  final ValueChanged<AudioTrack> onAudioChanged;
  final VoidCallback onPlayNext;
  final ValueChanged<int> onSeekIntervalChanged;
  final ValueChanged<String?> onPanelMessageChanged;

  @override
  Widget build(BuildContext context) {
    final tracks = player.state.tracks;
    final currentSubtitle = player.state.track.subtitle.id;
    final currentAudio = player.state.track.audio.id;

    Widget section(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: Colors.white,
          ),
        ),
      );
    }

    Widget option(
      String label, {
      required bool selected,
      required VoidCallback onTap,
      String? detail,
    }) {
      return DpadFocusable(
        onLongSelect: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: Colors.white),
                ),
              ),
              if (detail != null)
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // —— 视频 Tab ——
    final videoTab = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          section('播放速度'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map(
                  (s) => LButton(
                    label: '${s}x',
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: speed == s ? 0.5 : 1),
                    onClick: () async {
                      await player.setRate(s);
                      onSpeedChanged(s);
                      onPanelMessageChanged('播放速度 ${s}x');
                      if (controller.settings.rememberPlaybackSpeed) {
                        await controller.setLastPlaybackSpeed(s);
                      }
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          section('快进 / 快退'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SettingsService.seekIntervalOptions
                .map(
                  (seconds) => LButton(
                    label: '$seconds秒',
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: controller.settings.seekIntervalSeconds == seconds
                          ? 0.5
                          : 1,
                    ),
                    onClick: () async {
                      await controller.setSeekIntervalSeconds(seconds);
                      onPanelMessageChanged('跳转步长已设为 $seconds 秒');
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          section('画面'),
          Row(
            children: [
              LButton(
                label: '适应画面',
                onClick: () {
                  onFitChanged(BoxFit.contain);
                  onPanelMessageChanged('已切换为适应画面');
                },
              ),
              const SizedBox(width: 8),
              LButton(
                label: '铺满屏幕',
                onClick: () {
                  onFitChanged(BoxFit.cover);
                  onPanelMessageChanged('已切换为铺满屏幕');
                },
              ),
            ],
          ),
          if (player.state.tracks.subtitle.isNotEmpty ||
              player.state.tracks.audio.isNotEmpty) ...[
            const SizedBox(height: 24),
            section('播放'),
            option('播放下一集', selected: false, onTap: onPlayNext),
          ],
        ],
      ),
    );

    // —— 字幕 Tab ——
    final subtitleWidgets = <Widget>[
      section('字幕'),
      option(
        '关闭字幕',
        selected: currentSubtitle == 'no',
        onTap: () {
          onSubtitleChanged(SubtitleTrack.no());
          onPanelMessageChanged('已关闭字幕');
        },
      ),
      option(
        '自动',
        selected: currentSubtitle == 'auto',
        onTap: () {
          onSubtitleChanged(SubtitleTrack.auto());
          onPanelMessageChanged('已切换字幕');
        },
      ),
    ];
    for (var i = 0; i < tracks.subtitle.length; i++) {
      final track = tracks.subtitle[i];
      if (track.id == 'auto' || track.id == 'no') continue;
      subtitleWidgets.add(
        option(
          track.title?.trim().isNotEmpty == true
              ? track.title!
              : (track.language ?? '字幕 ${i + 1}'),
          selected: currentSubtitle == track.id,
          detail: track.language,
          onTap: () {
            onSubtitleChanged(track);
            onPanelMessageChanged('已切换字幕');
          },
        ),
      );
    }
    final subtitleTab = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleWidgets,
      ),
    );

    // —— 音频 Tab ——
    final audioWidgets = <Widget>[section('音轨')];
    for (var i = 0; i < tracks.audio.length; i++) {
      final track = tracks.audio[i];
      audioWidgets.add(
        option(
          track.title?.trim().isNotEmpty == true
              ? track.title!
              : (track.language ?? '音轨 ${i + 1}'),
          selected: currentAudio == track.id,
          detail: track.language,
          onTap: () async {
            await player.setAudioTrack(track);
            onPanelMessageChanged('已切换音轨');
          },
        ),
      );
    }
    final audioTab = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: audioWidgets,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () {}, // Absorb taps inside the panel so they don't reach the scrim.
      child: FocusScope(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.70),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: false,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        indicatorColor: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.7),
                        indicatorWeight: 3,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: '视频'),
                          Tab(text: '字幕'),
                          Tab(text: '音频'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: TabBarView(
                          children: [videoTab, subtitleTab, audioTab],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (panelMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 20, right: 20),
                  child: Text(
                    panelMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
