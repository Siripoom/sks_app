import 'package:flutter/widgets.dart';
import 'package:sks/widgets/common/local_image_provider_stub.dart'
    if (dart.library.io) 'package:sks/widgets/common/local_image_provider_io.dart'
    if (dart.library.html)
    'package:sks/widgets/common/local_image_provider_web.dart';

ImageProvider<Object>? imageProviderFromPath(String path) {
  if (path.trim().isEmpty) {
    return null;
  }

  return createImageProvider(path);
}
