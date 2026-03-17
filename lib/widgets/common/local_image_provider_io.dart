import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> createImageProvider(String path) {
  return FileImage(File(path));
}
