import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:luma_tv/widgets/luma_widgets/carousel.dart';
import 'package:luma_tv/widgets/luma_widgets/chip.dart';
import 'package:luma_tv/widgets/luma_widgets/layout.dart';
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
        CenterWrap.small([
          LButton(label: "添加", icon: Icons.add),
          LButton(label: "添加"),
          LButton(icon: Icons.add),
          Divider(height: 12),
        ]),
        LH3("变体"),
        for (String variant in variants) ...[
          CenterWrap.small([
            LSubTitle(variant),
            const SizedBox(width: 20),
            LButton(variant: variant, label: "添加", icon: Icons.add),
            LButton(variant: variant, label: "添加"),
            LButton(variant: variant, icon: Icons.add),
          ]),
        ],
        Divider(height: 12),
        LH3("颜色"),
        for (String variant in variants) ...[
          CenterWrap.small([
            LH4(variant),
            const SizedBox(width: 20),
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
          ]),
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
        CenterWrap.large([
          LSelector(
            ["1行", "2行", "3行"],
            label: "最大行数",
            onSelect: (v) => {maxLines = v + 1, setState(() {})},
          ),
          LSelector(
            ["200", "400", "600"],
            label: "最大宽度",
            onSelect: (v) => {maxWidth = (v + 1) * 200, setState(() {})},
          ),
        ]),
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
        const SizedBox(height: 8),
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
        CenterWrap.small([
          LChip("chip"),
          LChip("rounded chip", rounded: true),
          LChip("icon chip", icon: Icons.star),
        ]),
        const SizedBox(height: 10),
        LH3("filled"),
        CenterWrap.small([
          LChip.filled("rounded chip", icon: Icons.star, rounded: true),
          LChip.filled("chip", icon: Icons.star),
        ]),
        LH3("text"),
        CenterWrap.small([
          LChip.text("5.0", icon: Icons.star, iconColor: Colors.amber),
        ]),
        const SizedBox(height: 10),
        LH3("Color"),
        CenterWrap.small([
          LChip.filled(" chip", icon: Icons.star, color: Colors.amber),
          LChip("chip", color: Colors.amber, icon: Icons.star, rounded: true),
        ]),
        LH3("Pill"),
        CenterWrap([
          LPill("年份", "2026"),
          LPill("类型", "电影", color: Theme.of(context).colorScheme.secondary),
        ]),
      ],
    );
  }
}

class _CarouselWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LCarousel([
      CarouselItem(
        SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [LH1("111111", color: Colors.red)],
          ),
        ),
        image: "https://ts1.tc.mm.bing.net/th/id/OIP-C.LZVq5G8tHTosSDy9QEdSuwHaEc?r=0&rs=1&pid=ImgDetMain&o=7&rm=3",
      ),
      CarouselItem(
        LH1("22222"),
        image: "https://ts1.tc.mm.bing.net/th/id/R-C.bf0b3a015a0d0aa32bb5ce8ffe7600d0?rik=MMRxwZ4yCmjJeQ&riu=http%3a%2f%2fn.sinaimg.cn%2fsinacn20122%2f619%2fw959h460%2f20200123%2f4666-innckcf2900169.jpg&ehk=k84ToP0uhVfIv6f6j9s3B%2bPNAFUumecUIQ0VfitgLhI%3d&risl=&pid=ImgRaw&r=0",
      ),

      CarouselItem(
        LH1("333333"),
        image: "https://ts4.tc.mm.bing.net/th/id/OIP-C.OI8Ih_uewHisSvOD6UO3rQHaEJ?r=0&rs=1&pid=ImgDetMain&o=7&rm=3",
      ),
    ]);
  }
}

class _HomePage extends State<HomePage> {
  int _index = 0;
  final _pages = [
    _ButtonsWidget(),
    _SelectorWidget(),
    _TextsWidget(),
    _ChipWidget(),
    _CarouselWidget(),
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
              NavigationRailDestination(
                icon: Icon(Icons.card_membership_rounded),
                label: Text('Carousel'),
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
