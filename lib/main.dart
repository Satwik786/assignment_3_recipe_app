import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/recipe.dart';
import 'pages/recipe_details.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App 🍳',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7CD4FD),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Recipes')),
      body: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _CreateRecipeCard(),
            SizedBox(height: 12),
            Expanded(child: _RecipeList()),
          ],
        ),
      ),
    );
  }
}

class _CreateRecipeCard extends StatefulWidget {
  const _CreateRecipeCard();

  @override
  State<_CreateRecipeCard> createState() => _CreateRecipeCardState();
}

class _CreateRecipeCardState extends State<_CreateRecipeCard> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _ingredients = TextEditingController();
  final _instructions = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _instructions.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  List<String> _parseIngredients(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _urlValidator(String? v) {
    if (_required(v) != null) return 'Required';
    final uri = Uri.tryParse(v!.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = Recipe(
      id: '',
      title: _title.text.trim(),
      ingredients: _parseIngredients(_ingredients.text),
      instructions: _instructions.text.trim(),
      imageUrl: _imageUrl.text.trim(),
    ).toMap();

    try {
      await FirebaseFirestore.instance.collection('recipes').add(data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recipe added')));
        _formKey.currentState!.reset();
        _title.clear();
        _ingredients.clear();
        _instructions.clear();
        _imageUrl.clear();
        setState(() {}); // refresh preview
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _imageUrl.text.trim();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a new recipe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ingredients,
                decoration: const InputDecoration(
                  labelText: 'Ingredients (comma-separated)',
                  hintText: 'eggs, flour, milk',
                ),
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructions,
                decoration: const InputDecoration(labelText: 'Instructions'),
                validator: _required,
                maxLines: 5,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/photo.jpg',
                ),
                validator: _urlValidator,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (previewUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        alignment: Alignment.center,
                        color: Colors.black26,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Image preview failed'),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Text('Add Recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeList extends StatelessWidget {
  const _RecipeList();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('recipes')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No recipes yet. Add your first one!'),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final recipe = Recipe.fromSnapshot(docs[i]);
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.restaurant, size: 40),
                  ),
                ),
                title: Text(
                  recipe.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailsPage(recipe: recipe),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete recipe?'),
                        content: Text(
                          'This will permanently delete “${recipe.title}”.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('recipes')
                          .doc(recipe.id)
                          .delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted "${recipe.title}"')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
