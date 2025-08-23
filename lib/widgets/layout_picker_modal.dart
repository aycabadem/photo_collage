import 'package:flutter/material.dart';
import '../models/layout_template.dart';

/// Modern layout picker modal with simple grid preview
class LayoutPickerModal extends StatelessWidget {
  final Function(LayoutTemplate?) onLayoutSelected;

  const LayoutPickerModal({super.key, required this.onLayoutSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Choose Layout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Custom option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCustomOption(context),
          ),

          const SizedBox(height: 20),

          // Layout grid - direct without categories
          Expanded(child: _buildLayoutGrid()),
        ],
      ),
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onLayoutSelected(null); // null means custom mode
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Create your own layout',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutGrid() {
    // Get all layouts
    List<LayoutTemplate> layouts = LayoutTemplates.templates;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 columns like the reference
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: layouts.length,
        itemBuilder: (context, index) {
          final layout = layouts[index];
          return _buildModernLayoutTile(layout, context);
        },
      ),
    );
  }

  Widget _buildModernLayoutTile(LayoutTemplate layout, BuildContext context) {
    return GestureDetector(
      onTap: () {
        onLayoutSelected(layout);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        child: Stack(
          children: [
            // Layout preview with borders
            Container(
              margin: const EdgeInsets.all(4),
              child: CustomPaint(
                size: const Size.square(double.infinity),
                painter: ModernLayoutPreviewPainter(layout.photoLayouts),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern layout preview painter with visible borders
class ModernLayoutPreviewPainter extends CustomPainter {
  final List<PhotoLayout> photoLayouts;

  ModernLayoutPreviewPainter(this.photoLayouts);

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final backgroundPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Border paint
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final photoLayout in photoLayouts) {
      final rect = Rect.fromLTWH(
        photoLayout.position.dx * size.width,
        photoLayout.position.dy * size.height,
        photoLayout.size.width * size.width,
        photoLayout.size.height * size.height,
      );

      // Draw filled rectangle
      canvas.drawRect(rect, backgroundPaint);

      // Draw border
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
