import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
// OPEN ITEM: add `desktop_drop` to pubspec.yaml for native OS drag-and-drop
// support (`flutter pub add desktop_drop`). Uncomment the import + DropTarget
// wrapper below once added. Click-to-browse works without it.
// import 'package:desktop_drop/desktop_drop.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — copied from detail_panel.dart / print_specs.dart to match
// the codebase convention of each component file owning its own token copy.
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFEFF6FF);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink3 = Color(0xFF334155);
  static const r = 8.0;
  static const rLg = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum AttachmentKind { image, pdf, document, spreadsheet, archive, other }

AttachmentKind attachmentKindFor(String fileName, String mimeType) {
  final ext =
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  if (mimeType.startsWith('image/')) return AttachmentKind.image;
  if (mimeType == 'application/pdf' || ext == 'pdf') return AttachmentKind.pdf;
  if (['doc', 'docx', 'txt', 'rtf'].contains(ext))
    return AttachmentKind.document;
  if (['xls', 'xlsx', 'csv'].contains(ext)) return AttachmentKind.spreadsheet;
  if (['zip', 'rar', '7z'].contains(ext)) return AttachmentKind.archive;
  return AttachmentKind.other;
}

/// Local view model for a task attachment. Once the backend/API is wired
/// up, this likely mirrors a TypeORM `Attachment` entity (id, taskId,
/// fileName, url, sizeBytes, mimeType, uploadedBy, createdAt).
class TaskAttachment {
  final int id; // negative id = optimistic local upload, not yet confirmed
  final String fileName;
  final String? url; // null while uploading
  final int sizeBytes;
  final String mimeType;
  final String uploadedByName;
  final DateTime uploadedAt;

  /// 0..1 while uploading, null once complete/not applicable.
  final double? uploadProgress;
  final bool isFailed;

  const TaskAttachment({
    required this.id,
    required this.fileName,
    this.url,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedByName,
    required this.uploadedAt,
    this.uploadProgress,
    this.isFailed = false,
  });

  AttachmentKind get kind => attachmentKindFor(fileName, mimeType);
  bool get isUploading => uploadProgress != null && !isFailed;

  TaskAttachment copyWith({
    String? url,
    double? uploadProgress,
    bool clearUploadProgress = false,
    bool? isFailed,
  }) {
    return TaskAttachment(
      id: id,
      fileName: fileName,
      url: url ?? this.url,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      uploadedByName: uploadedByName,
      uploadedAt: uploadedAt,
      uploadProgress:
          clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      isFailed: isFailed ?? this.isFailed,
    );
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

const Map<AttachmentKind, (IconData, Color, Color)> _kKindStyle = {
  AttachmentKind.image: (Icons.image_outlined, _T.purple, _T.purple50),
  AttachmentKind.pdf: (Icons.picture_as_pdf_outlined, _T.red, _T.red50),
  AttachmentKind.document: (Icons.description_outlined, _T.blue, _T.blue50),
  AttachmentKind.spreadsheet: (
    Icons.grid_on_outlined,
    _T.green,
    Color(0xFFECFDF5),
  ),
  AttachmentKind.archive: (Icons.folder_zip_outlined, _T.amber, _T.amber50),
  AttachmentKind.other: (
    Icons.insert_drive_file_outlined,
    _T.slate500,
    _T.slate100,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENTS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class AttachmentsSection extends StatefulWidget {
  final List<TaskAttachment> attachments;

  /// Called with local file paths once the user picks or drops files.
  /// OPEN ITEM: wire this to request a presigned upload URL from the
  /// backend, PUT the file to it, then confirm the Attachment row.
  final Future<void> Function(List<String> filePaths) onUpload;

  /// OPEN ITEM: wire to DELETE /attachments/:id (and remove from remote
  /// storage) once the backend exists.
  final Future<void> Function(TaskAttachment attachment) onDelete;

  /// Called when a non-image attachment is tapped (download/open in
  /// browser). Images are previewed in-place. OPEN ITEM: hook up
  /// url_launcher once attachment URLs are real.
  final void Function(TaskAttachment attachment)? onOpen;

  /// Optional — shows a refresh icon that re-fetches attachments from the server.
  final Future<void> Function()? onRefresh;

  const AttachmentsSection({
    super.key,
    required this.attachments,
    required this.onUpload,
    required this.onDelete,
    this.onOpen,
    this.onRefresh,
  });

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  static const int _maxBytes = 3 * 1024 * 1024; // 3MB per file

  bool _dragging = false;
  bool _picking = false;
  bool _refreshing = false;

  Future<void> _pickFiles() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      final files = result?.files ?? [];

      final tooBig = files.where((f) => f.size > _maxBytes).toList();
      final ok = files.where((f) => f.size <= _maxBytes).toList();

      if (tooBig.isNotEmpty && mounted) {
        final names = tooBig.map((f) => f.name).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Skipped (over 3MB): $names',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      final paths = ok.map((f) => f.path).whereType<String>().toList();
      if (paths.isNotEmpty) {
        await widget.onUpload(paths);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _previewImage(TaskAttachment a) {
    if (a.url == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(48),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                    maxHeight: 700,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_T.rLg),
                    child: Image.network(a.url!, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with DropTarget once desktop_drop is added, e.g.:
    // return DropTarget(
    //   onDragEntered: (_) => setState(() => _dragging = true),
    //   onDragExited: (_) => setState(() => _dragging = false),
    //   onDragDone: (details) async {
    //     setState(() => _dragging = false);
    //     final paths = details.files.map((f) => f.path).toList();
    //     if (paths.isNotEmpty) await widget.onUpload(paths);
    //   },
    //   child: _content(),
    // );
    return _content();
  }

  Future<void> _refresh() async {
    if (_refreshing || widget.onRefresh == null) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget _content() {
    if (widget.attachments.isEmpty) {
      return _EmptyDropZone(
        dragging: _dragging,
        busy: _picking,
        onTap: _pickFiles,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (widget.onRefresh != null)
        //   Align(
        //     alignment: Alignment.centerRight,
        //     child: MouseRegion(
        //       cursor: SystemMouseCursors.click,
        //       child: GestureDetector(
        //         onTap: _refresh,
        //         child: Padding(
        //           padding: const EdgeInsets.only(bottom: 6),
        //           child: AnimatedRotation(
        //             turns: _refreshing ? 1 : 0,
        //             duration: const Duration(milliseconds: 500),
        //             child: Icon(
        //               Icons.refresh_rounded,
        //               size: 15,
        //               color: _refreshing ? _T.blue : _T.slate400,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AddTile(busy: _picking, onTap: _pickFiles),
            ...widget.attachments.map(
              (a) => _AttachmentCard(
                key: ValueKey(a.id),
                attachment: a,
                onTap: () {
                  if (a.kind == AttachmentKind.image) {
                    _previewImage(a);
                  } else {
                    widget.onOpen?.call(a);
                  }
                },
                onDelete: () => widget.onDelete(a),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — full drop zone
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyDropZone extends StatefulWidget {
  final bool dragging;
  final bool busy;
  final VoidCallback onTap;

  const _EmptyDropZone({
    required this.dragging,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_EmptyDropZone> createState() => _EmptyDropZoneState();
}

class _EmptyDropZoneState extends State<_EmptyDropZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.dragging || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            color: active ? _T.blue50 : _T.slate50,
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(
              color: active ? _T.blue.withOpacity(0.4) : _T.slate200,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? _T.blue.withOpacity(0.12) : _T.slate100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.busy
                      ? Icons.hourglass_empty_rounded
                      : Icons.upload_outlined,
                  size: 16,
                  color: active ? _T.blue : _T.slate400,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.busy
                    ? 'Opening file picker…'
                    : 'Drag & drop files, or click to browse',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: active ? _T.blue : _T.ink3,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Reference images, design proofs, and other task files\n(max 3MB each)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _T.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD TILE — compact "+" card shown alongside existing attachments
// ─────────────────────────────────────────────────────────────────────────────
class _AddTile extends StatefulWidget {
  final bool busy;
  final VoidCallback onTap;

  const _AddTile({required this.busy, required this.onTap});

  @override
  State<_AddTile> createState() => _AddTileState();
}

class _AddTileState extends State<_AddTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 132,
          height: 118,
          decoration: BoxDecoration(
            color: _hovered ? _T.blue50 : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _hovered ? _T.blue.withOpacity(0.35) : _T.slate200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 9),
              Icon(
                Icons.add_rounded,
                size: 18,
                color: _hovered ? _T.blue : _T.slate400,
              ),
              const SizedBox(height: 4),
              Text(
                'Add files',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? _T.blue : _T.slate400,
                ),
              ),
              Text(
                '3MB max',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? _T.blue : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AttachmentCard extends StatefulWidget {
  final TaskAttachment attachment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AttachmentCard({
    super.key,
    required this.attachment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final (icon, color, bg) = _kKindStyle[a.kind]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: a.isUploading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 132,
          height: 118,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _hovered ? _T.slate300 : _T.slate200),
            boxShadow:
                _hovered
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Thumbnail / icon area ──
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_T.r - 1),
                    ),
                    child: SizedBox(
                      height: 72,
                      width: double.infinity,
                      child:
                          a.kind == AttachmentKind.image && a.url != null
                              ? Image.network(
                                a.url!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => _iconTile(icon, color, bg),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return _iconTile(icon, color, bg);
                                },
                              )
                              : _iconTile(icon, color, bg),
                    ),
                  ),
                  // ── Filename / size ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _T.ink,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          formatFileSize(a.sizeBytes),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Upload progress scrim ──
              if (a.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value:
                              a.uploadProgress == 0 ? null : a.uploadProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _T.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Failed state ──
              if (a.isFailed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _T.red50.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: _T.red,
                      ),
                    ),
                  ),
                ),

              // ── Hover-reveal delete ──
              if (_hovered && !a.isUploading)
                Positioned(
                  top: 5,
                  right: 5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.slate200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: _T.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, Color color, Color bg) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: color),
    );
  }
}
