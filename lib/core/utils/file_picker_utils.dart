import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PickedAttachmentFile {
  const PickedAttachmentFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

Future<PickedAttachmentFile?> pickAttachmentFile(
  BuildContext context, {
  int maxSizeBytes = 5 * 1024 * 1024,
}) async {
  final result = await FilePicker.platform.pickFiles(withData: true);
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gagal membaca file.')));
    return null;
  }

  if (file.size > maxSizeBytes) {
    if (!context.mounted) return null;
    final maxSizeMb = (maxSizeBytes / (1024 * 1024)).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ukuran file maksimal ${maxSizeMb}MB.')),
    );
    return null;
  }

  return PickedAttachmentFile(name: file.name, bytes: bytes);
}
