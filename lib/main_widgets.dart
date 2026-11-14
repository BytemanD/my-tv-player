import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:luma_tv/widgets/luma_widgets/selector.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:media_kit/media_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _ButtonsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TH3("按钮"),
        for (Variant variant in Variant.values) ...[
          Row(
            children: [
              TH4(variant.name),
              TDivider(),
              LButton(variant: variant, label: "添加", icon: Icons.add),
              LButton(variant: variant, label: "添加"),
              LButton(variant: variant, icon: Icons.add),
            ],
          ),
          TDivider(height: 2),
        ],
        TDivider(),
        TH3("颜色"),
        for (Variant variant in Variant.values) ...[
          Row(
            children: [
              TH4(variant.name),
              TDivider(),
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
        TLine(),
        Row(
          children: [
            LSelector(
              ["1行", "2行", "3行"],
              label: "最大行数",
              onChanged: (v) => {maxLines = v + 1, setState(() {})},
            ),
            TDivider(),
            LSelector(
              ["200", "400", "600"],
              label: "最大宽度",
              onChanged: (v) => {maxWidth = (v + 1) * 200, setState(() {})},
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
        TH3("选择器"),
        TDivider(),
        LSelector(["全部", "电影", "剧集"]),
        TDivider(),
        LSelector(["评分", "时间"], label: "排序"),
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
        TDivider(height: 20),

        LText("普通文本"),
        LText("普通蓝色文本", color: Colors.blue),
        TDivider(height: 20),
        LTitle("标题 title"),
        LSubTitle("子标题"),
        TDivider(height: 20),
        LongTextDemo(),
      ],
    );
  }
}

class _HomePage extends State<HomePage> {
  int _index = 0;
  final List<Widget> _pages = [
    _ButtonsWidget(),
    _SelectorWidget(),
    _TextsWidget(),
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

  MediaKit.ensureInitialized();
  // runApp(const LumaApp());
  runApp(const TvWidgetsApp());
}
