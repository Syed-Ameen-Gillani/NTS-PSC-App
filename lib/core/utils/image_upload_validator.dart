import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageUploadValidator {
  const ImageUploadValidator._();

  static const int maxBytes = 5 * 1024 * 1024;

  static Future<String> validate(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw ArgumentError('Choose an image no larger than 5 MB.');
    }

    String? mime;
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71) {
      mime = 'image/png';
    } else if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      mime = 'image/jpeg';
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      mime = 'image/webp';
    }
    if (mime == null) {
      throw ArgumentError('Choose a JPEG, PNG or WebP image.');
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width > 8192 ||
            descriptor.height > 8192 ||
            descriptor.width * descriptor.height > 24000000) {
          throw ArgumentError(
            'Choose an image up to 8192 pixels per side and 24 megapixels.',
          );
        }
        final codec = await descriptor.instantiateCodec(targetWidth: 256);
        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    return mime;
  }
}
