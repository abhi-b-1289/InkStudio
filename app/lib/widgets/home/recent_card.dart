import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/saved_drawing.dart';
import '../../painters/canvas_painters.dart';

class RecentCard extends StatelessWidget {
  final SavedDrawing drawing;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  const RecentCard({
    super.key,
    required this.drawing, required this.onTap,
    required this.onDelete, required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF3B3B7A).withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    color: Colors.white,
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.black12),
                    ),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: ThumbnailPainter(drawing)),
                        ),
                        if (drawing.preset != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                drawing.preset!.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          drawing.name,
                          style: const TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF1B1B2F)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeAgo(drawing.updatedAt),
                          style: const TextStyle(fontSize: 9.5, height: 1.2, color: Colors.black45),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: PopupMenuButton<String>(
                      tooltip: 'Options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Flexible(child: Text('Rename', overflow: TextOverflow.ellipsis))])),
                        PopupMenuItem(value: 'delete', padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: cs.error), const SizedBox(width: 10), Flexible(child: Text('Delete', overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.error)))])),
                      ],
                      onSelected: (v) {
                        if (v == 'rename') onRename();
                        if (v == 'delete') onDelete();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.more_vert_rounded, size: 15, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

