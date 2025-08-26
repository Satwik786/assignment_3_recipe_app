import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;
  const EditRecipePage({super.key, required this.recipe});

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _ingredients;
  late TextEditingController _instructions;
  late TextEditingController _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.recipe.title);
    _ingredients = TextEditingController(
      text: widget.recipe.ingredients.join(', '),
    );
    _instructions = TextEditingController(text: widget.recipe.instructions);
    _imageUrl = TextEditingController(text: widget.recipe.imageUrl);
  }

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _instructions.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  List<String> _parseIngredients(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .update({
            'title': _title.text.trim(),
            'ingredients': _parseIngredients(_ingredients.text),
            'instructions': _instructions.text.trim(),
            'imageUrl': _imageUrl.text.trim(),
          });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recipe updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Recipe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredients,
                decoration: const InputDecoration(
                  labelText: 'Ingredients (comma separated)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructions,
                decoration: const InputDecoration(labelText: 'Instructions'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
