
import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class EditableImage {
  String id;
  Uint8List imageBytes;

  EditableImage({required this.imageBytes}) : id = const Uuid().v4();

  // Private constructor for fromJson
  EditableImage._({required this.id, required this.imageBytes});

  // Convert an EditableImage object into a Map.
  Map<String, dynamic> toJson() => {
        'id': id,
        // Uint8List must be base64 encoded to be stored in JSON.
        'imageBytes': base64Encode(imageBytes),
      };

  // Create an EditableImage object from a Map.
  factory EditableImage.fromJson(Map<String, dynamic> json) {
    return EditableImage._(
      id: json['id'] as String,
      // Decode the base64 string back into Uint8List.
      imageBytes: base64Decode(json['imageBytes' ] as String),
    );
  }
}
