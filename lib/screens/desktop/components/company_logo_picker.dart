import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// A professional image picker with hover effects and a fixed 256×180 size.
/// Tapping the area opens the file picker. The empty state shows a dashed border
/// and a clear message. On hover over an image, a dark overlay appears with an
/// "Edit" label, and a subtle border highlights the area.
class CompanyLogoPicker extends StatefulWidget {
  const CompanyLogoPicker({
    super.key,
    this.onImageSelected,
    this.initialImageFile,
    this.width = 256,
    this.height = 180,
    this.hintText = 'Tap to attach company logo\n(256×180 recommended)',
  });

  final void Function(File? file)? onImageSelected;
  final File? initialImageFile;
  final double width;
  final double height;
  final String hintText;

  @override
  State<CompanyLogoPicker> createState() => _CompanyLogoPickerState();
}

class _CompanyLogoPickerState extends State<CompanyLogoPicker>
    with SingleTickerProviderStateMixin {
  File? _imageFile;
  bool _isHovering = false;
  late AnimationController _hoverController;
  late Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImageFile;
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _overlayOpacity = Tween<double>(
      begin: 0.0,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
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
      debugPrint('Error picking image: $e');
    }
  }

  void _updateHover(bool hovering) {
    if (hovering == _isHovering) return;
    setState(() => _isHovering = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _imageFile != null;

    return MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) => _updateHover(false),
      child: GestureDetector(
        onTap: _pickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                hasImage && _isHovering
                    ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background / image
                if (hasImage)
                  Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                  )
                else
                  _buildPlaceholder(context),

                // Dark overlay on hover (only when image exists)
                if (hasImage && _isHovering)
                  FadeTransition(
                    opacity: _overlayOpacity,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 32,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.hintText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
