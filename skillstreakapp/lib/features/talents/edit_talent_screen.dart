import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../../providers/talent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/talent_model.dart';

class EditTalentScreen extends ConsumerStatefulWidget {
  final Talent talent;

  const EditTalentScreen({super.key, required this.talent});

  @override
  ConsumerState<EditTalentScreen> createState() => _EditTalentScreenState();
}

class _EditTalentScreenState extends ConsumerState<EditTalentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  
  late String _selectedCategory;
  late String _selectedLevel;
  late List<String> _tags;

  // Image editing state
  final ImagePicker _picker = ImagePicker();
  
  // existing and new images combined as strings for simplicity in PUT body
  late List<String> _currentImages;
  late List<String> _currentCertificates;

  final List<String> _categories = [
    'Sports',
    'Music',
    'Arts',
    'Debate',
    'Dance',
    'Singing',
    'fights',
    'yoga',
    'direction',
    'Other'
  ];

  final List<String> _levels = [
    'Zonal',
    'District',
    'State',
    'National',
    'International'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.talent.title);
    _descriptionController = TextEditingController(text: widget.talent.description);
    _tagController = TextEditingController();
    _selectedCategory = _categories.contains(widget.talent.category) 
        ? widget.talent.category 
        : _categories.first;
    _selectedLevel = _levels.contains(widget.talent.level)
        ? widget.talent.level
        : _levels.first;
    _tags = List.from(widget.talent.tags);
    
    // Initialize with existing data from the post
    _currentImages = List.from(widget.talent.images);
    _currentCertificates = List.from(widget.talent.certificates);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000, // Reasonable size for base64
        maxHeight: 1000,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        final base64String = await _convertImageToBase64(pickedFile);
        setState(() {
          _currentImages.add(base64String);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        final base64String = await _convertImageToBase64(pickedFile);
        setState(() {
          _currentCertificates.add(base64String);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick certificate: $e');
    }
  }

  Future<String> _convertImageToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final mimeType = _getMimeType(file.name);
    return 'data:$mimeType;base64,$base64Str';
  }

  String _getMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _isSubmitting = false;

  Future<void> _updateTalent() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      final user = authState.value;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final updateData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'level': _selectedLevel,
          'tags': _tags,
          'images': _currentImages,
          'certificates': _currentCertificates,
        };

        await ref.read(talentsProvider.notifier).updatePost(
          widget.talent.id, 
          user.id, 
          updateData,
        );
        
        if (!mounted) return;
        
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Go back to Detail
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update talent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          _isSubmitting 
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ))
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: _updateTalent,
                tooltip: 'Save Changes',
              ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Talent Title'),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter talent title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe your talent...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Category'),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) { if (value != null) setState(() => _selectedCategory = value); },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Level'),
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  items: _levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                  onChanged: (value) { if (value != null) setState(() => _selectedLevel = value); },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.leaderboard),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Tags'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add a tag',
                          prefixIcon: const Icon(Icons.tag),
                          suffixIcon: IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle), color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onFieldSubmitted: (_) => _addTag(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(entry.value),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(entry.key),
                        backgroundColor: Colors.teal.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 30),
                _buildSectionTitle('Images'),
                _buildImageGrid(
                  images: _currentImages,
                  onAdd: _pickImage,
                  onRemove: (index) => setState(() => _currentImages.removeAt(index)),
                ),

                const SizedBox(height: 30),
                _buildSectionTitle('Certificates'),
                _buildImageGrid(
                  images: _currentCertificates,
                  onAdd: _pickCertificate,
                  onRemove: (index) => setState(() => _currentCertificates.removeAt(index)),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _updateTalent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageGrid({
    required List<String> images,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      children: [
        if (images.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: const Center(child: Text('No photos added yet', style: TextStyle(color: Colors.grey))),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUri = images[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUri.startsWith('data:')
                      ? Image.memory(base64Decode(imageUri.split(',').last), fit: BoxFit.cover)
                      : Image.network(imageUri, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.withOpacity(0.1),
            foregroundColor: Colors.teal,
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
