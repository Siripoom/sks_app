import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> createImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }

  return FileImage(File(path));
}
