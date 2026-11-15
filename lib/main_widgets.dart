import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:luma_tv/widgets/luma_widgets/chip.dart';
import 'package:luma_tv/widgets/luma_widgets/selector.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePage();
}

final variants = ["outlined", "filled", "text", "ghost"];

class _ButtonsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LSubTitle("default"),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LButton(label: "添加", icon: Icons.add),
            LButton(label: "添加"),
            LButton(icon: Icons.add),
            Divider(height: 12),
          ],
        ),
        LH3("变体"),
        for (String variant in variants) ...[
          Wrap(
            children: [
              LSubTitle(variant),
              LButton(variant: variant, label: "添加", icon: Icons.add),
              LButton(variant: variant, label: "添加"),
              LButton(variant: variant, icon: Icons.add),
            ],
          ),
        ],
        Divider(height: 12),
        LH3("颜色"),
        for (String variant in variants) ...[
          Row(
            children: [
              LH4(variant),
              LButton(
                variant: variant,
                label: "添加",
                icon: Icons.add,
                color: Colors.cyan,
              ),
              LButton(variant: variant, label: "添加", color: Colors.cyan),
              LButton(variant: variant, icon: Icons.add, color: Colors.cyan),
              LButton(
                variant: variant,
                icon: Icons.add,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class LongTextDemo extends StatefulWidget {
  const LongTextDemo({super.key});

  @override
  State<StatefulWidget> createState() => _LongTextDemo();
}

class _LongTextDemo extends State<LongTextDemo> {
  int maxLines = 1;
  double maxWidth = 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1),
        Row(
          children: [
            LSelector(
              ["1行", "2行", "3行"],
              label: "最大行数",
              onSelect: (v) => {maxLines = v + 1, setState(() {})},
            ),
            Divider(),
            LSelector(
              ["200", "400", "600"],
              label: "最大宽度",
              onSelect: (v) => {maxWidth = (v + 1) * 200, setState(() {})},
            ),
          ],
        ),
        LText(
          "舷窗外，木星的大红斑正缓缓转过第七象限。林晓把神经接驳线的最后一根探针插进后颈接口，系统提示音在颅腔内响起：“同步率98.7%，记忆备份已完成。",
          maxLines: maxLines,
          maxWidth: maxWidth,
        ),
      ],
    );
  }
}

class _SelectorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LSelector(["全部", "电影", "剧集"]),
        Divider(height: 20),
        LSelector(["评分", "时间"], label: "排序", color: Colors.green),
      ],
    );
  }
}

class _TextsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        LH0("header 0"),
        LH1("header 1"),
        LH2("header 2"),
        LH3("header 3"),
        Divider(height: 20),

        LText("普通文本"),
        LText("普通蓝色文本", color: Colors.blue),
        Divider(height: 20),
        LTitle("标题 title"),
        LSubTitle("子标题"),
        Divider(height: 20),
        LongTextDemo(),
      ],
    );
  }
}

class _ChipWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            LChip("chip"),
            LChip("rounded chip", rounded: true),
            LChip("icon chip", icon: Icons.star),
          ],
        ),
        const SizedBox(height: 10),
        LH3("filled"),
        Wrap(
          spacing: 4,
          children: [
            LChip.filled(" rounded chip", icon: Icons.star),
            LChip.filled("filled chip", icon: Icons.star, rounded: true),
          ],
        ),
        LH3("text"),
        Wrap(
          spacing: 4,
          children: [
            LChip.text("5.0", icon: Icons.star, iconColor: Colors.amber),
          ],
        ),
        const SizedBox(height: 10),
        LH3("color"),
        Wrap(
          spacing: 4,
          children: [
            LChip(
              " chip",
              icon: Icons.star,
              variant: "filled",
              color: Colors.amber,
            ),
            LChip("chip", color: Colors.amber, icon: Icons.star, rounded: true),
          ],
        ),
        LH3("pill"),
        Wrap(
          spacing: 4,
          children: [
            LPill("年份", "2026"),
            LPill("类型", "电影", color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ],
    );
  }
}

class _HomePage extends State<HomePage> {
  int _index = 0;
  final _pages = [
    _ButtonsWidget(),
    _SelectorWidget(),
    _TextsWidget(),
    _ChipWidget(),
  ];

  // const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luma widgets')),
      body: Row(
        children: [
          // 左侧导航
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.widgets),
                label: Text('Button'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.autofps_select),
                label: Text('Selector'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.text_fields_outlined),
                label: Text('Text'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tag),
                label: Text('Chip'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          // 右侧内容区
          Expanded(
            child: Container(padding: EdgeInsets.all(8), child: _pages[_index]),
          ),
        ],
      ),
    );
  }
}

class TvWidgetsApp extends StatelessWidget {
  const TvWidgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Widgets App',
      theme: ThemeData(
        useMaterial3: true,
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const HomePage(),
      builder: Dpad.wrap(
        theme: const DpadThemeData(
          effects: [DpadScaleEffect(scale: 1.08), DpadGlowEffect()],
          scrollPadding: 48,
        ),
        onBack: () {
          return false;
        },
        onMenu: () {},
        debugOverlay: false,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TvWidgetsApp());
}
