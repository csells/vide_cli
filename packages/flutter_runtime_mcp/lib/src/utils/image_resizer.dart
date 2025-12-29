import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Maximum dimension (width or height) allowed for Claude API multi-image requests.
const int maxImageDimension = 2000;

/// Resizes a PNG image if either dimension exceeds [maxImageDimension].
/// Returns the original bytes if no resizing is needed.
///
/// The image is scaled proportionally to fit within [maxImageDimension] x [maxImageDimension].
Uint8List resizeImageIfNeeded(List<int> pngBytes) {
  final image = img.decodePng(Uint8List.fromList(pngBytes));
  if (image == null) {
    // If decoding fails, return original bytes
    return Uint8List.fromList(pngBytes);
  }

  final width = image.width;
  final height = image.height;

  // Check if resizing is needed
  if (width <= maxImageDimension && height <= maxImageDimension) {
    return Uint8List.fromList(pngBytes);
  }

  // Calculate new dimensions maintaining aspect ratio
  double scale;
  if (width > height) {
    scale = maxImageDimension / width;
  } else {
    scale = maxImageDimension / height;
  }

  final newWidth = (width * scale).round();
  final newHeight = (height * scale).round();

  // Resize the image
  final resized = img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.linear,
  );

  // Encode back to PNG
  return Uint8List.fromList(img.encodePng(resized));
}
