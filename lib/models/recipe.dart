import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final List<String> ingredients;
  final String instructions;
  final String imageUrl;
  final Timestamp? createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'ingredients': ingredients,
    'instructions': instructions,
    'imageUrl': imageUrl,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory Recipe.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return Recipe(
      id: snap.id,
      title: d['title'] ?? '',
      ingredients:
          (d['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      instructions: d['instructions'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      createdAt: d['createdAt'],
    );
  }
}
