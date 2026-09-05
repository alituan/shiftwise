/// Seam over the image plugins so scan flow tests never touch platform
/// channels. Picking and cropping are one user journey (cancel anywhere
/// returns null); the plugins own their native/web UIs.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  const PickedImage(this.bytes, this.path);

  final Uint8List bytes;

  /// Native file path, or the web picker's blob URL — both work as the
  /// cropper's sourcePath.
  final String path;
}

abstract class ImageSourceGateway {
  /// Camera or gallery; null means the user cancelled.
  Future<PickedImage?> pick({required bool fromCamera});

  /// Crop to the user's own schedule row; null means the user cancelled.
  Future<Uint8List?> crop(PickedImage image, {required BuildContext context});
}

class PluginImageSourceGateway implements ImageSourceGateway {
  @override
  Future<PickedImage?> pick({required bool fromCamera}) async {
    final file = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return null;
    return PickedImage(await file.readAsBytes(), file.path);
  }

  @override
  Future<Uint8List?> crop(
    PickedImage image, {
    required BuildContext context,
  }) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [if (kIsWeb) WebUiSettings(context: context)],
    );
    return cropped == null ? null : await cropped.readAsBytes();
  }
}
