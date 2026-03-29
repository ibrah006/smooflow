import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// A professional image picker with hover effects.
/// Default size is 270×180. Tapping opens the file picker.
/// Empty state shows a dashed border and a message.
/// On hover over an empty state, the border and background subtly change.
/// When an image is present, hover shows a dark overlay with an "Edit" badge.
class CompanyLogoPicker extends StatefulWidget {
  const CompanyLogoPicker({
    super.key,
    this.onImageSelected,
    this.initialImageFile,
    this.width = 270,
    this.height = 180,
    this.hintText = 'Tap to attach company logo\n(3:2 ratio recommended)',
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
      cursor: SystemMouseCursors.click,
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
            border: _getBorder(hasImage, context),
            boxShadow: _getBoxShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or placeholder
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

                // Dark overlay on hover when image exists
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

  Border? _getBorder(bool hasImage, BuildContext context) {
    if (hasImage) {
      // Image present: show border only on hover
      if (_isHovering) {
        return Border.all(color: Theme.of(context).primaryColor, width: 2);
      }
      return null;
    } else {
      // Empty state: always have a border; change color on hover
      return Border.all(
        color:
            _isHovering ? Theme.of(context).primaryColor : Colors.grey.shade300,
        width: _isHovering ? 2 : 1,
      );
    }
  }

  List<BoxShadow>? _getBoxShadow() {
    // Add a subtle shadow on hover for empty state, otherwise keep light shadow
    if (!(_imageFile?.existsSync() ?? true) && _isHovering) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  Widget _buildPlaceholder(BuildContext context) {
    // Empty state background: changes slightly on hover
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isHovering ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 32,
            color:
                _isHovering
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.hintText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    _isHovering ? Colors.grey.shade700 : Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "PNG, JPG",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    _isHovering
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
