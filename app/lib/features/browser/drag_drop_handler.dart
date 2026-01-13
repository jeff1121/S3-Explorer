import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;

class FileUploadInfo {
  final String localPath;
  final String relativePath;
  
  FileUploadInfo({required this.localPath, required this.relativePath});
}

/// Helper to normalize drag/drop payload into local file paths.
class DragDropHandler {
  Future<List<FileUploadInfo>> filesFromDrop(DropDoneDetails details) async {
    final allFiles = <FileUploadInfo>[];
    
    for (final file in details.files) {
      final path = file.path;
      if (path.isEmpty) continue;
      
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        // Recursively collect all files in the directory
        final dirFiles = await _collectFilesInDirectory(path);
        allFiles.addAll(dirFiles);
      } else if (entity == FileSystemEntityType.file) {
        // Single file - use just the filename
        allFiles.add(FileUploadInfo(
          localPath: path,
          relativePath: p.basename(path),
        ));
      }
    }
    return allFiles;
  }
  
  Future<List<FileUploadInfo>> _collectFilesInDirectory(String dirPath) async {
    final files = <FileUploadInfo>[];
    final dir = Directory(dirPath);
    final dirName = p.basename(dirPath);
    
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          // Calculate relative path from the dragged directory
          final relativePath = p.join(dirName, p.relative(entity.path, from: dirPath));
          files.add(FileUploadInfo(
            localPath: entity.path,
            relativePath: relativePath,
          ));
        }
      }
    } catch (e) {
      print('Warning: Failed to read directory $dirPath: $e');
    }
    
    return files;
  }
  
  // Legacy method for backward compatibility
  Future<List<String>> pathsFromDrop(DropDoneDetails details) async {
    final files = await filesFromDrop(details);
    return files.map((f) => f.localPath).toList();
  }
}
