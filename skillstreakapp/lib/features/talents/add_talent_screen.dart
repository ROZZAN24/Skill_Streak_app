import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/talent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/talent_model.dart';


class AddTalentScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const AddTalentScreen({super.key, this.onSuccess});

  @override
  ConsumerState<AddTalentScreen> createState() => _AddTalentScreenState();
}

class _AddTalentScreenState extends ConsumerState<AddTalentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _achievementController = TextEditingController();
  final _organizationController = TextEditingController();
  final _achievementDescriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  String _selectedCategory = 'Sports';
  String _selectedLevel = 'Zonal';
  DateTime _selectedDate = DateTime.now();
  
  // Store both File objects and their bytes for web compatibility
  final List<File> _certificates = [];
  final List<Uint8List> _certificatesBytes = [];
  final List<File> _images = [];
  final List<Uint8List> _imagesBytes = [];
  final List<String> _tags = [];

  final ImagePicker _picker = ImagePicker();

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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _achievementController.dispose();
    _organizationController.dispose();
    _achievementDescriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (kIsWeb) {
            _imagesBytes.add(bytes);
          } else {
            _images.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (kIsWeb) {
            _imagesBytes.add(bytes);
          } else {
            _images.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (kIsWeb) {
            _certificatesBytes.add(bytes);
          } else {
            _certificates.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick certificate: $e');
    }
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

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _imagesBytes.removeAt(index);
      } else {
        _images.removeAt(index);
      }
    });
  }

  void _removeCertificate(int index) {
    setState(() {
      if (kIsWeb) {
        _certificatesBytes.removeAt(index);
      } else {
        _certificates.removeAt(index);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSubmitting = false;

  Future<void> _saveTalent() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      final user = authState.value;
      
      if (user == null) {
        _showErrorSnackBar('Please login first');
        return;
      }

      setState(() => _isSubmitting = true);

      // Create achievement list using Achievement model
      final List<Achievement> achievements = [];
      if (_achievementController.text.trim().isNotEmpty) {
        achievements.add(Achievement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _achievementController.text.trim(),
          description: _achievementDescriptionController.text.trim(),
          organization: _organizationController.text.trim(),
          date: _selectedDate,
          certificateUrl: '',
          level: _selectedLevel,
        ));
      }

      try {
        final talentNotifier = ref.read(talentsProvider.notifier);
        await talentNotifier.addTalent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          level: _selectedLevel,
          userId: user.id,
          userName: user.name,
          userAvatar: user.profileImage,
          institution: user.institution,
          tags: _tags,
          achievements: achievements,
          images: kIsWeb ? [] : _images,
          imagesBytes: kIsWeb ? _imagesBytes : [],
          certificates: kIsWeb ? [] : _certificates,
          certificatesBytes: kIsWeb ? _certificatesBytes : [],
        );
        
        if (!mounted) return;
        
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Talent uploaded to server successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Clear form and go back
        _clearForm();
        // If used as a tab, call onSuccess callback instead of popping
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showErrorSnackBar('Failed to add talent: $e');
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _achievementController.clear();
    _organizationController.clear();
    _achievementDescriptionController.clear();
    _tagController.clear();
    setState(() {
      _tags.clear();
      _images.clear();
      _imagesBytes.clear();
      _certificates.clear();
      _certificatesBytes.clear();
      _selectedCategory = 'Sports';
      _selectedLevel = 'Zonal';
      _selectedDate = DateTime.now();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Talent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTalent,
            tooltip: 'Save Talent',
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
                // Title
                _buildSectionTitle('Talent Title'),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter talent title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                _buildSectionTitle('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe your talent...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category
                _buildSectionTitle('Category'),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Level
                _buildSectionTitle('Level'),
                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  items: _levels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLevel = value);
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.leaderboard),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Achievement Section (Optional)
                _buildSectionTitle('Achievement (Optional)'),
                TextFormField(
                  controller: _achievementController,
                  decoration: InputDecoration(
                    hintText: 'Achievement title',
                    prefixIcon: const Icon(Icons.emoji_events),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _organizationController,
                  decoration: InputDecoration(
                    hintText: 'Organization',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _achievementDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Achievement description',
                    prefixIcon: const Icon(Icons.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Change Date'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tags (Optional)
                _buildSectionTitle('Tags (Optional)'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add a tag and press Enter',
                          prefixIcon: const Icon(Icons.tag),
                          suffixIcon: IconButton(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add_circle),
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _addTag();
                          }
                        },
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
                      final index = entry.key;
                      final tag = entry.value;
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(index),
                        backgroundColor: Colors.teal.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // Images Section (Optional)
                _buildSectionTitle('Images (Optional)'),
                _buildImageGrid(
                  title: 'Talent Images',
                  isWeb: kIsWeb,
                  files: kIsWeb ? [] : _images,
                  filesBytes: kIsWeb ? _imagesBytes : [],
                  onAdd: _showImagePickerDialog,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 20),

                // Certificates Section (Optional)
                _buildSectionTitle('Certificates (Optional)'),
                _buildImageGrid(
                  title: 'Certificates',
                  isWeb: kIsWeb,
                  files: kIsWeb ? [] : _certificates,
                  filesBytes: kIsWeb ? _certificatesBytes : [],
                  onAdd: _pickCertificate,
                  onRemove: _removeCertificate,
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _saveTalent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Talent',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildImageGrid({
    required String title,
    required bool isWeb,
    required List<File> files,
    required List<Uint8List> filesBytes,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    final itemCount = isWeb ? filesBytes.length : files.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$title ($itemCount)',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.withOpacity(0.1),
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (itemCount == 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'No images added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        if (itemCount > 0)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isWeb
                          ? Image.memory(
                              filesBytes[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            )
                          : Image.file(
                              files[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}