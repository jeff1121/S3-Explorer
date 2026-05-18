import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Bookmark for quick access to frequently used locations
class Bookmark {
  Bookmark({
    required this.id,
    required this.name,
    required this.profileId,
    required this.bucket,
    this.prefix,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String profileId;
  final String bucket;
  final String? prefix;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileId': profileId,
        'bucket': bucket,
        'prefix': prefix,
        'createdAt': createdAt.toIso8601String(),
      };

  static Bookmark fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      name: json['name'] as String,
      profileId: json['profileId'] as String,
      bucket: json['bucket'] as String,
      prefix: json['prefix'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() =>
      'Bookmark($name, $bucket${prefix != null ? "/$prefix" : ""})';
}

/// Service for managing bookmarks
class BookmarksService with ChangeNotifier {
  BookmarksService() {
    _init();
  }

  final _uuid = const Uuid();
  final List<Bookmark> _bookmarks = [];
  File? _storageFile;

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  Future<void> _init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _storageFile = File(p.join(dir.path, 'bookmarks.json'));
      await _load();
    } catch (e) {
      debugPrint('Failed to init bookmarks: $e');
    }
  }

  Future<void> _load() async {
    if (_storageFile == null || !await _storageFile!.exists()) return;

    try {
      final content = await _storageFile!.readAsString();
      final json = jsonDecode(content) as List<dynamic>;
      _bookmarks.clear();
      _bookmarks.addAll(
          json.map((item) => Bookmark.fromJson(item as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load bookmarks: $e');
    }
  }

  Future<void> _save() async {
    if (_storageFile == null) return;

    try {
      final json = _bookmarks.map((b) => b.toJson()).toList();
      final content = jsonEncode(json);
      await _storageFile!.writeAsString(content);
    } catch (e) {
      debugPrint('Failed to save bookmarks: $e');
    }
  }

  /// Add a new bookmark
  Future<Bookmark> addBookmark({
    required String name,
    required String profileId,
    required String bucket,
    String? prefix,
  }) async {
    final bookmark = Bookmark(
      id: _uuid.v4(),
      name: name,
      profileId: profileId,
      bucket: bucket,
      prefix: prefix,
      createdAt: DateTime.now(),
    );

    _bookmarks.add(bookmark);
    await _save();
    notifyListeners();
    return bookmark;
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await _save();
    notifyListeners();
  }

  /// Update a bookmark
  Future<void> updateBookmark({
    required String id,
    String? name,
    String? profileId,
    String? bucket,
    String? prefix,
  }) async {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    final old = _bookmarks[index];
    _bookmarks[index] = Bookmark(
      id: id,
      name: name ?? old.name,
      profileId: profileId ?? old.profileId,
      bucket: bucket ?? old.bucket,
      prefix: prefix ?? old.prefix,
      createdAt: old.createdAt,
    );

    await _save();
    notifyListeners();
  }

  /// Get bookmarks for a specific profile
  List<Bookmark> getBookmarksForProfile(String profileId) {
    return _bookmarks.where((b) => b.profileId == profileId).toList();
  }
}
