import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// A widget that lets the user pick a company logo.
/// Displays a placeholder when no image is selected.
/// On hover over the image, shows a subtle border and a dark overlay.
class CompanyLogoPicker extends StatefulWidget {
  const CompanyLogoPicker({
    super.key,
    this.onImageSelected,
    this.initialImageFile,
    this.width = 256,
    this.height = 180,
  });

  /// Callback when a new image is selected.
  final void Function(File? file)? onImageSelected;

  /// Optional initial image file (e.g., from previous state).
  final File? initialImageFile;

  /// Width of the image container.
  final double width;

  /// Height of the image container.
  final double height;

  @override
  State<CompanyLogoPicker> createState() => _CompanyLogoPickerState();
}

class _CompanyLogoPickerState extends State<CompanyLogoPicker> {
  File? _imageFile;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImageFile;
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _imageFile = file;
        });
        widget.onImageSelected?.call(file);
      }
    } catch (e) {
      // Handle error if needed
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border:
                _isHovering && _imageFile != null
                    ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                    : null,
            boxShadow:
                _isHovering && _imageFile != null
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image or placeholder
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => _buildPlaceholder(),
                  ),
                )
              else
                _buildPlaceholder(),

              // Dark overlay on hover (only when image exists)
              if (_isHovering && _imageFile != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

              // Optional hint text when no image
              Align(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _imageFile == null && !_isHovering
                        ? 'Tap to attach your company logo\n(512 x 512 recommended)'
                        : '\n',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
