import 'package:flutter/foundation.dart';

enum LibraryKind {
  all('全部'),
  movies('电影'),
  series("剧集");

  const LibraryKind(this.label);
  final String label;
}

enum LibrarySort {
  recent('最近添加'),
  title('名称'),
  year('年份'),
  rating('评分');

  const LibrarySort(this.label);
  final String label;
}

class LibraryController extends ChangeNotifier {
  LibraryKind kind = LibraryKind.all;
  LibrarySort sort = LibrarySort.recent;

  LibraryController();

  void setKind(LibraryKind v) {
    kind = v;
    notifyListeners();
  }

  void setSort(LibrarySort v) {
    sort = v;
    notifyListeners();
  }
}
