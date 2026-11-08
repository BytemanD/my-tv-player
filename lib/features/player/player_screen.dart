import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../controllers/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/settings_service.dart';
import '../../widgets/tv_focusable.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    required this.queue,
    required this.initialIndex,
  });

  final AppController controller;
  final List<MediaItem> queue;
  final int initialIndex;

  static Route<void> route({
    required AppController controller,
    required List<MediaItem> queue,
    required int initialIndex,
  }) {
    return PageRouteBuilder<void>(
      opaque: true,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => PlayerScreen(
        controller: controller,
        queue: queue,
        initialIndex: initialIndex.clamp(0, queue.length - 1),
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

enum _DoubleTapZone { left, center, right }

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _videoController;
  final FocusNode _playerFocus = FocusNode(debugLabel: 'player');
  final FocusScopeNode _panelFocus = FocusScopeNode(debugLabel: 'player-panel');
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  late int _index;
  MediaItem get _media => widget.queue[_index];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _playing = false;
  bool _buffering = false;
  bool _completed = false;
  bool _seeking = false;
  bool _exiting = false;
  bool _canPop = false;
  bool _controlsVisible = true;
  bool _panelOpen = false;
  bool _loading = true;
  _DoubleTapZone _doubleTapZone = _DoubleTapZone.center;
  String? _error;
  String? _seekFlash;
  String? _panelMessage;

  double _speed = 1.0;

  /// 当前音量（0~100），可空。首次打开视频时不覆盖系统默认音量，
  /// 只有用户开始滑动调节时才初始化并开始追踪。
  double? _currentVolume;
  BoxFit _fit = BoxFit.contain;
  Timer? _hideTimer;
  Timer? _saveTimer;
  Timer? _flashTimer;
  Timer? _nextTimer;
  DateTime _lastPositionPaint = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _lastSaved = Duration.zero;

  Timer? _tapSuppressTimer;
  DateTime? _lastInteractionAt;
  DateTime? _tapDownAt;
  Offset? _tapDownAtPosition;

  /// 长按判定定时器：按住超过阈值后进入 2.0x 倍速，放开还原。
  Timer? _holdTimer;

  /// 长按前的播放速度，用于放开时还原。
  double _speedBeforeHold = 1.0;

  /// 长按倍速是否已生效（仅在 600ms 定时器真正触发后置为 true，单击不会误触）。
  bool _isSpeedHoldActive = false;

  /// 垂直拖动：起始位置，用于计算位移。
  Offset? _dragStartPosition;

  /// 拖动开始时的音量（0.0~1.0）。
  double _dragStartVolume = 1.0;

  /// 是否为右侧拖动（调音量）。
  bool _dragIsVolume = false;

  String? _volumeFlash;
  Timer? _volumeFlashTimer;

  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;

  bool get _panelVisible =>
      _panelOpen || _panelController.isAnimating || _panelController.value != 0;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _panelController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _index = widget.initialIndex.clamp(0, widget.queue.length - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _initPlayer();
  }

  void _markInteraction() {
    // Timestamp the click on a control so the tap-through logic on the video
    // surface knows to ignore it (the same tap reaches both).
    _lastInteractionAt = DateTime.now();
  }

  bool get _interactionRecentlyMarked {
    final at = _lastInteractionAt;
    return at != null &&
        DateTime.now().difference(at) < const Duration(milliseconds: 220);
  }

  void _tapForwardToggle() {
    if (_panelOpen) return;
    if (_interactionRecentlyMarked) return;
    if (_tapSuppressTimer?.isActive ?? false) {
      // Second half of a double-tap; don't toggle controls again.
      _tapSuppressTimer?.cancel();
      _tapSuppressTimer = null;
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
    _tapSuppressTimer = Timer(const Duration(milliseconds: 260), () {
      _tapSuppressTimer = null;
    });
  }

  void _initPlayer() {
    _player = Player(
      configuration: const PlayerConfiguration(
        title: 'Luma',
        logLevel: MPVLogLevel.error,
        bufferSize: 64 * 1024 * 1024,
      ),
    );
    _videoController = VideoController(_player);

    _subscriptions.add(
      _player.stream.position.listen((value) {
        final now = DateTime.now();
        if (now.difference(_lastPositionPaint) <
            const Duration(milliseconds: 220)) {
          return;
        }
        _lastPositionPaint = now;
        if (mounted) setState(() => _position = value);
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((value) {
        if (mounted) setState(() => _duration = value);
      }),
    );
    _subscriptions.add(
      _player.stream.buffer.listen((value) {
        if (mounted) setState(() => _buffered = value);
      }),
    );
    _subscriptions.add(
      _player.stream.playing.listen((value) {
        if (mounted) {
          setState(() => _playing = value);
          if (value) {
            _scheduleHide();
          } else {
            _hideTimer?.cancel();
            setState(() => _controlsVisible = true);
          }
        }
      }),
    );
    _subscriptions.add(
      _player.stream.buffering.listen((value) {
        if (mounted) setState(() => _buffering = value);
      }),
    );
    _subscriptions.add(
      _player.stream.tracks.listen((_) {
        if (mounted) setState(() {});
      }),
    );
    _subscriptions.add(
      _player.stream.completed.listen((value) {
        if (value && mounted) _onCompleted();
      }),
    );
    _subscriptions.add(
      _player.stream.error.listen((message) {
        if (!mounted) return;
        if (!_playing || _loading) {
          setState(() => _error = message);
        }
      }),
    );

    _openCurrent();
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _save());
  }

  Future<void> _openCurrent() async {
    final media = _media;
    setState(() {
      _loading = true;
      _error = null;
      _completed = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _buffered = Duration.zero;
      _panelOpen = false;
      _controlsVisible = true;
      _panelMessage = null;
    });
    try {
      final saved = await widget.controller.progressFor(media);
      await _player.open(Media(media.path), play: true);
      _playerFocus.requestFocus();

      // 恢复记住的播放速度
      if (widget.controller.settings.rememberPlaybackSpeed) {
        final remembered = widget.controller.settings.lastPlaybackSpeed;
        if ((remembered - _speed).abs() > 0.001) {
          _speed = remembered;
          await _player.setRate(remembered);
        }
      }

      if (saved != null &&
          saved.positionMs > 15000 &&
          !saved.completed &&
          (saved.durationMs == 0 ||
              saved.positionMs < saved.durationMs * 0.96)) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await _player.seek(Duration(milliseconds: saved.positionMs));
        _flash(
          '已从 ${formatClock(Duration(milliseconds: saved.positionMs))} 继续播放',
        );
      }
      if (widget.controller.settings.autoLoadSubtitles) {
        await _loadSidecarSubtitle(media);
      }
      if (mounted) setState(() => _loading = false);
      _scheduleHide();
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '无法播放此文件\n$error';
        });
      }
    }
  }

  Future<void> _loadSidecarSubtitle(MediaItem media) async {
    try {
      final dir = Directory(p.dirname(media.path));
      if (!await dir.exists()) return;
      final base = p.basenameWithoutExtension(media.path).toLowerCase();
      final files = await dir
          .list()
          .where((e) => e is File)
          .cast<File>()
          .toList();
      final candidates = files.where((file) {
        final name = p.basename(file.path).toLowerCase();
        final ext = p.extension(name);
        if (!{'.srt', '.ass', '.ssa', '.vtt', '.sub'}.contains(ext)) {
          return false;
        }
        final stem = p.basenameWithoutExtension(name);
        return stem == base || stem.startsWith('$base.');
      }).toList();
      if (candidates.isEmpty) return;
      candidates.sort((a, b) {
        int score(File file) {
          final name = p.basename(file.path).toLowerCase();
          if (RegExp(r'(zh|chs|chi|sc|简|中)').hasMatch(name)) return 0;
          if (RegExp(r'(en|eng|英)').hasMatch(name)) return 2;
          return 1;
        }

        return score(a).compareTo(score(b));
      });
      final chosen = candidates.first;
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(
          chosen.path,
          title: p.basename(chosen.path),
          language: 'zh',
        ),
      );
      _flash('已加载外挂字幕：${p.basename(chosen.path)}');
    } catch (_) {
      // Missing sidecar subtitles are not an error.
    }
  }

  void _onCompleted() {
    if (_completed) return;
    _completed = true;
    _save(completed: true);
    _controlsVisible = true;
    setState(() {});
    final next = _index + 1 < widget.queue.length
        ? widget.queue[_index + 1]
        : null;
    if (next != null && widget.controller.settings.autoPlayNext) {
      _nextTimer?.cancel();
      _nextTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) _playIndex(_index + 1);
      });
    }
  }

  Future<void> _playIndex(int index) async {
    if (index < 0 || index >= widget.queue.length) return;
    _nextTimer?.cancel();
    await _save();
    if (!mounted) return;
    setState(() => _index = index);
    await _openCurrent();
  }

  Future<void> _save({bool completed = false}) async {
    final media = _media;
    final position = _position;
    final duration = _duration;
    if (media.id == null) return;
    if (position.inMilliseconds == 0 || duration.inMilliseconds == 0) return;
    if (!completed && position == _lastSaved) return;
    _lastSaved = position;
    await widget.controller.savePlaybackProgress(
      media,
      position,
      duration,
      completed: completed,
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_playing || _panelOpen || _seeking) return;
    _hideTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls({bool keepVisible = false}) {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    if (keepVisible) {
      _hideTimer?.cancel();
    } else if (!_seeking) {
      _scheduleHide();
    }
  }

  Future<void> _seekTo(Duration position) async {
    _markInteraction();
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return;
    final target = Duration(
      milliseconds: position.inMilliseconds.clamp(0, durationMs).toInt(),
    );
    await _player.seek(target);
    if (!mounted) return;
    setState(() => _position = target);
    _flash(formatClock(target));
    _showControls();
  }

  Future<void> _seekBy(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds
          .clamp(
            0,
            _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1 << 31,
          )
          .toInt(),
    );
    await _player.seek(clamped);
    setState(() => _position = clamped);
    _flash(seconds > 0 ? '+${seconds}s' : '${seconds}s');
    _showControls();
  }

  void _flash(String message) {
    _flashTimer?.cancel();
    setState(() => _seekFlash = message);
    _flashTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _seekFlash = null);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_panelOpen) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        _closePanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (_controlsVisible) {
        setState(() => _controlsVisible = false);
        _hideTimer?.cancel();
      } else {
        _exit();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekBy(-widget.controller.settings.seekIntervalSeconds);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekBy(widget.controller.settings.seekIntervalSeconds);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.contextMenu) {
      _openPanel();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _controlsVisible = !_controlsVisible);
      if (_controlsVisible) _scheduleHide();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _togglePlay() {
    if (_player.state.playing) {
      _player.pause();
    } else {
      if (_completed) {
        _player.seek(Duration.zero);
        setState(() => _completed = false);
      }
      _player.play();
    }
    _showControls();
  }

  static const _speedCycle = [1.0, 1.25, 1.5, 2.0, 0.5, 0.75];
  Future<void> _cycleSpeed() async {
    final index = _speedCycle.indexWhere((s) => (s - _speed).abs() < 0.001);
    final next = _speedCycle[(index + 1) % _speedCycle.length];
    await _player.setRate(next);
    if (!mounted) return;
    setState(() => _speed = next);
    _showControls();
    if (widget.controller.settings.rememberPlaybackSpeed) {
      await widget.controller.setLastPlaybackSpeed(next);
    }
  }

  void _toggleFit() {
    setState(
      () => _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain,
    );
    _showControls();
  }

  void _handleVideoDoubleTapDown(TapDownDetails details, double width) {
    final fraction = width <= 0 ? 0.5 : details.localPosition.dx / width;
    _doubleTapZone = fraction < 1 / 3
        ? _DoubleTapZone.left
        : fraction > 2 / 3
        ? _DoubleTapZone.right
        : _DoubleTapZone.center;
  }

  void _handleVideoDoubleTap() {
    if (_panelOpen || _loading) return;
    switch (_doubleTapZone) {
      case _DoubleTapZone.left:
        _seekBy(-widget.controller.settings.seekIntervalSeconds);
      case _DoubleTapZone.center:
        _togglePlay();
      case _DoubleTapZone.right:
        _seekBy(widget.controller.settings.seekIntervalSeconds);
    }
  }

  void _handleSurfaceTap(PointerUpEvent event) {
    final downAt = _tapDownAt;
    final downAtPosition = _tapDownAtPosition;
    _tapDownAt = null;
    _tapDownAtPosition = null;
    if (downAt == null || downAtPosition == null) return;
    if (DateTime.now().difference(downAt) > const Duration(milliseconds: 300)) {
      _scheduleHide();
      return;
    }
    if ((event.localPosition - downAtPosition).distance > 28) {
      // This was a horizontal drag / gesture, not a tap.
      _scheduleHide();
      return;
    }
    _tapForwardToggle();
  }

  /// 长按判定：按住 600ms 且手指在右侧区域，则进入 2.0x 倍速；
  /// 放开后还原到长按前的播放速度。单击不会触发。
  void _startHoldTimer(Offset position, double width) {
    _holdTimer?.cancel();
    final fraction = width <= 0 ? 0.5 : position.dx / width;
    if (fraction <= 2 / 3) {
      // 只有右侧长按才调速。
      return;
    }
    _holdTimer = Timer(const Duration(milliseconds: 600), () {
      _holdTimer = null;
      _isSpeedHoldActive = true;
      _speedBeforeHold = _speed;
      _setSpeed(2.0);
      _flash('×2.0');
    });
  }

  /// 手指抬起：停止长按判定。只有真正进入过倍速状态才还原速度，
  /// 单击（定时器还未触发就抬起）不会干扰正常点击。
  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_isSpeedHoldActive) {
      _isSpeedHoldActive = false;
      _setSpeed(_speedBeforeHold);
      _flash('还原速度');
    }
  }

  Future<void> _setSpeed(double speed) async {
    await _player.setRate(speed);
    if (!mounted) return;
    setState(() => _speed = speed);
    if (widget.controller.settings.rememberPlaybackSpeed) {
      await widget.controller.setLastPlaybackSpeed(speed);
    }
  }

  /// 垂直拖动开始：根据手指区域决定调音量（右侧）。
  Future<void> _startDrag(Offset position, double width) async {
    // 拖动时取消长按倍速判定，避免与点击/长按冲突。
    _holdTimer?.cancel();
    _dragStartPosition = position;
    final fraction = width <= 0 ? 0.5 : position.dx / width;
    if (fraction > 2 / 3) {
      // 右侧：调音量
      _dragIsVolume = true;
      _dragStartVolume = (_currentVolume ?? 70.0).clamp(0.0, 100.0) / 100.0;
    } else {
      // 左侧和中间区域：不处理（亮度控制已移除，避免编译问题）
      _dragIsVolume = false;
    }
  }

  /// 垂直拖动更新：根据位移调整音量，向上增大，向下减小。
  void _updateDrag(Offset position, double height) {
    if (!_dragIsVolume) return;
    if (_dragStartPosition == null) return;

    // 垂直位移：手指向上移动 delta 为负，表示增大；向下移动 delta 为正，表示减小。
    final delta = _dragStartPosition!.dy - position.dy;
    // 全屏滑动可变化 100%（0~100）。
    final change = delta / height * 1.0;

    if (_dragIsVolume) {
      final next = (_dragStartVolume + change).clamp(0.0, 1.0);
      _setVolume(next);
      _flashVolume('音量 ${(next * 100).round()}%');
    }
  }

  /// 垂直拖动结束。
  void _endDrag() {
    _dragStartPosition = null;
    _dragIsVolume = false;
  }

  Future<void> _setVolume(double volume) async {
    await _player.setVolume(volume * 100);
    _currentVolume = volume * 100;
    if (!mounted) return;
    setState(() {});
  }

  void _flashVolume(String message) {
    _volumeFlashTimer?.cancel();
    setState(() => _volumeFlash = message);
    _volumeFlashTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _volumeFlash = null);
    });
  }

  void _openPanel() {
    setState(() {
      _panelOpen = true;
      _controlsVisible = false;
      _panelMessage = null;
    });
    _hideTimer?.cancel();
    _panelController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _panelFocus.requestFocus();
      _panelFocus.nextFocus();
    });
  }

  void _closePanel() {
    _panelController.reverse().then((_) {
      if (mounted) {
        setState(() => _panelOpen = false);
      }
    });
    _playerFocus.requestFocus();
  }

  Future<void> _exit() async {
    if (_exiting) return;
    _exiting = true;
    await _save();
    if (!mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _flashTimer?.cancel();
    _nextTimer?.cancel();
    _save();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _tapSuppressTimer?.cancel();
    _holdTimer?.cancel();
    _volumeFlashTimer?.cancel();
    _panelController.dispose();
    _player.dispose();
    _playerFocus.dispose();
    _panelFocus.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_panelOpen) {
          _closePanel();
        } else if (_controlsVisible) {
          setState(() => _controlsVisible = false);
          _hideTimer?.cancel();
        } else {
          _exit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _tapDownAt = DateTime.now();
            _tapDownAtPosition = event.localPosition;
            _startHoldTimer(
              event.localPosition,
              MediaQuery.sizeOf(context).width,
            );
          },
          onPointerUp: (event) {
            _endHold();
            _endDrag();
            _handleSurfaceTap(event);
          },
          onPointerCancel: (_) {
            _endHold();
            _endDrag();
            _tapDownAt = null;
            _tapDownAtPosition = null;
            _scheduleHide();
          },
          onPointerHover: (_) => _showControls(),
          child: Focus(
            focusNode: _playerFocus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: (details) => _handleVideoDoubleTapDown(
                details,
                MediaQuery.sizeOf(context).width,
              ),
              onDoubleTap: _handleVideoDoubleTap,
              onVerticalDragStart: (details) => _startDrag(
                details.localPosition,
                MediaQuery.sizeOf(context).width,
              ),
              onVerticalDragUpdate: (details) => _updateDrag(
                details.localPosition,
                MediaQuery.sizeOf(context).height,
              ),
              onVerticalDragEnd: (_) => _endDrag(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Video(
                    controller: _videoController,
                    controls: NoVideoControls,
                    fit: _fit,
                    fill: Colors.black,
                    wakelock: true,
                    subtitleViewConfiguration: const SubtitleViewConfiguration(
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.35,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black87),
                          Shadow(blurRadius: 2, color: Colors.black),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(80, 0, 80, 110),
                    ),
                  ),
                  if (_loading)
                    Center(
                      child: CircularProgressIndicator(
                        color: LumaColors.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  if (_error != null)
                    _ErrorOverlay(
                      message: _error!,
                      onRetry: _openCurrent,
                      onBack: _exit,
                    ),
                  _buildControls(),
                  if (_panelVisible) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closePanel,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: 410,
                      child: SlideTransition(
                        position: _panelSlide,
                        child: _buildPanel(),
                      ),
                    ),
                  ],
                  if (_seekFlash != null)
                    IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, -0.15),
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: LumaColors.accentSoft),
                            ),
                            child: Text(
                              _seekFlash!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: LumaColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_volumeFlash != null)
                    IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, -0.15),
                        child: AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: LumaColors.accentSoft),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  size: 20,
                                  color: LumaColors.accent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _volumeFlash!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: LumaColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return IgnorePointer(
      ignoring: !_controlsVisible && _playing,
      child: AnimatedOpacity(
        opacity: _controlsVisible || !_playing ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.28, 0.62, 1],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(46, 38, 46, 0),
                child: Row(
                  children: [
                    TvIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: '返回',
                      size: 40,
                      onTap: () {
                        _markInteraction();
                        _exit();
                      },
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _media.isEpisode
                                ? (_media.seriesTitle ?? _media.title)
                                : _media.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (_media.isEpisode)
                            Text(
                              '${episodeCode(_media.season, _media.episode)}  ·  ${_media.displayTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB9BBC4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TvButton(
                      icon: Icons.more_vert_rounded,
                      style: TvButtonStyle.filled,
                      backgroundColor: LumaColors.primary.withValues(
                        alpha: 0.40,
                      ),
                      compact: true,
                      square: true,
                      onTap: () {
                        _markInteraction();
                        _openPanel();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_buffering && !_loading)
              Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: LumaColors.accent,
                    strokeWidth: 2.4,
                  ),
                ),
              )
            else if (!_playing)
              Center(
                child: GestureDetector(
                  onTap: () {
                    _markInteraction();
                    _togglePlay();
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      _completed
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 46,
              right: 46,
              bottom: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressBar(
                    position: _position,
                    duration: _duration,
                    buffered: _buffered,
                    onSeek: _seekTo,
                    onSeekingChanged: (seeking) {
                      setState(() => _seeking = seeking);
                      if (seeking) {
                        _showControls(keepVisible: true);
                      } else {
                        _scheduleHide();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        formatClock(_position),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '  /  ',
                        style: TextStyle(
                          fontSize: 13,
                          color: LumaColors.textMuted,
                        ),
                      ),
                      Text(
                        formatClock(_duration),
                        style: TextStyle(
                          fontSize: 13,
                          color: LumaColors.textMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 14),
                      TvIconButton(
                        icon: _completed
                            ? Icons.replay_rounded
                            : _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        tooltip: _completed
                            ? '重播'
                            : _playing
                            ? '暂停'
                            : '播放',
                        size: 40,
                        onTap: () {
                          _markInteraction();
                          _togglePlay();
                        },
                      ),
                      const SizedBox(width: 24),
                      TvChip(
                        label: _speed == _speed.roundToDouble()
                            ? '${_speed.toStringAsFixed(0)}x'
                            : '${_speed.toStringAsFixed(2)}x',
                        selected: _speed != 1.0,
                        onTap: () {
                          _markInteraction();
                          _cycleSpeed();
                        },
                      ),
                      const SizedBox(width: 8),
                      TvChip(
                        label: _fit == BoxFit.contain ? '适应画面' : '铺满屏幕',
                        selected: _fit == BoxFit.cover,
                        onTap: () {
                          _markInteraction();
                          _toggleFit();
                        },
                      ),
                      if (_completed && _index + 1 < widget.queue.length)
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            '即将播放下一集…',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '单击 显示/隐藏  ·  双击 快进退/播放',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final tracks = _player.state.tracks;
    final currentSubtitle = _player.state.track.subtitle.id;
    final currentAudio = _player.state.track.audio.id;

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
      return TvFocusable(
        onTap: onTap,
        scale: 1.01,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: focused ? LumaColors.surfaceHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focused ? LumaColors.accent : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: LumaColors.primary,
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
          );
        },
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
                  (speed) => TvChip(
                    label: '${speed}x',
                    selected: _speed == speed,
                    onTap: () async {
                      await _player.setRate(speed);
                      setState(() => _speed = speed);
                      _panelMessage = '播放速度 ${speed}x';
                      if (widget.controller.settings.rememberPlaybackSpeed) {
                        await widget.controller.setLastPlaybackSpeed(speed);
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
                  (seconds) => TvChip(
                    label: '$seconds秒',
                    selected:
                        widget.controller.settings.seekIntervalSeconds ==
                        seconds,
                    onTap: () async {
                      await widget.controller.setSeekIntervalSeconds(seconds);
                      if (!mounted) return;
                      setState(() => _panelMessage = '跳转步长已设为 $seconds 秒');
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          section('画面'),
          Row(
            children: [
              TvChip(
                label: '适应画面',
                selected: _fit == BoxFit.contain,
                onTap: () => setState(() {
                  _fit = BoxFit.contain;
                  _panelMessage = '已切换为适应画面';
                }),
              ),
              const SizedBox(width: 8),
              TvChip(
                label: '铺满屏幕',
                selected: _fit == BoxFit.cover,
                onTap: () => setState(() {
                  _fit = BoxFit.cover;
                  _panelMessage = '已切换为铺满屏幕';
                }),
              ),
            ],
          ),
          if (_index + 1 < widget.queue.length) ...[
            const SizedBox(height: 24),
            section('播放'),
            option(
              '播放下一集',
              selected: false,
              onTap: () => _playIndex(_index + 1),
            ),
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
        onTap: () => _setSubtitle(SubtitleTrack.no()),
      ),
      option(
        '自动',
        selected: currentSubtitle == 'auto',
        onTap: () => _setSubtitle(SubtitleTrack.auto()),
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
          onTap: () => _setSubtitle(track),
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
            await _player.setAudioTrack(track);
            _panelMessage = '已切换音轨';
            setState(() {});
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
        node: _panelFocus,
        autofocus: true,
        child: Container(
          decoration: BoxDecoration(
            color: LumaColors.primary.withValues(alpha: 0.70),
            border: Border(
              left: BorderSide(color: LumaColors.primaryDeep, width: 1),
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
                        indicatorColor: LumaColors.accent,
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
              if (_panelMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 20, right: 20),
                  child: Text(
                    _panelMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setSubtitle(SubtitleTrack track) async {
    try {
      await _player.setSubtitleTrack(track);
      if (mounted) {
        setState(() => _panelMessage = track.id == 'no' ? '已关闭字幕' : '已切换字幕');
      }
    } catch (error) {
      if (mounted) setState(() => _panelMessage = '字幕切换失败：$error');
    }
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.onSeek,
    this.onSeekingChanged,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<bool>? onSeekingChanged;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragFraction;

  void _setSeeking(bool value) {
    widget.onSeekingChanged?.call(value);
  }

  double _fractionAt(double dx, double width) =>
      width <= 0 ? 0 : (dx / width).clamp(0.0, 1.0);

  Duration _positionAt(double fraction) => Duration(
    milliseconds: (widget.duration.inMilliseconds * fraction).round(),
  );

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds;
    final played = total <= 0
        ? 0.0
        : (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
    final buffer = total <= 0
        ? 0.0
        : (widget.buffered.inMilliseconds / total).clamp(0.0, 1.0);
    final activeFraction = _dragFraction ?? played;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final canSeek = total > 0 && width.isFinite;
        return MouseRegion(
          cursor: canSeek ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: canSeek
                ? (details) => widget.onSeek(
                    _positionAt(_fractionAt(details.localPosition.dx, width)),
                  )
                : null,
            onHorizontalDragStart: canSeek
                ? (details) {
                    setState(() {
                      _dragFraction = _fractionAt(
                        details.localPosition.dx,
                        width,
                      );
                    });
                    _setSeeking(true);
                  }
                : null,
            onHorizontalDragUpdate: canSeek
                ? (details) => setState(() {
                    _dragFraction = _fractionAt(
                      details.localPosition.dx,
                      width,
                    );
                  })
                : null,
            onHorizontalDragEnd: canSeek
                ? (_) {
                    final fraction = _dragFraction;
                    setState(() => _dragFraction = null);
                    _setSeeking(false);
                    if (fraction != null) widget.onSeek(_positionAt(fraction));
                  }
                : null,
            onHorizontalDragCancel: () {
              setState(() => _dragFraction = null);
              _setSeeking(false);
            },
            child: SizedBox(
              height: 32,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: buffer,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: activeFraction,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: LumaColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (activeFraction * width - 6).clamp(0, width - 12),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: LumaColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: LumaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LumaColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: LumaColors.danger,
                size: 36,
              ),
              const SizedBox(height: 14),
              const Text(
                '播放失败',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: LumaColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TvButton(
                    label: '返回',
                    style: TvButtonStyle.outline,
                    compact: true,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                  TvButton(
                    label: '重试',
                    autofocus: true,
                    compact: true,
                    onTap: onRetry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
