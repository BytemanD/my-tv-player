class LibrarySource {
  const LibrarySource({
    this.id,
    required this.path,
    this.uri,
    required this.name,
    required this.addedAt,
    this.lastScanAt,
  });

  final int? id;
  final String path;
  final String? uri;
  final String name;
  final int addedAt;
  final int? lastScanAt;

  factory LibrarySource.fromMap(Map<String, Object?> map) {
    return LibrarySource(
      id: map['id'] as int?,
      path: map['path'] as String? ?? '',
      uri: map['uri'] as String?,
      name: map['name'] as String? ?? '',
      addedAt: map['added_at'] as int? ?? 0,
      lastScanAt: map['last_scan_at'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'path': path,
      'uri': uri,
      'name': name,
      'added_at': addedAt,
      'last_scan_at': lastScanAt,
    };
  }
}
