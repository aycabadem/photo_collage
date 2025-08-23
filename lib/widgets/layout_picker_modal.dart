import 'package:flutter/material.dart';
import '../models/layout_template.dart';

/// Modal for selecting preset layout templates
class LayoutPickerModal extends StatelessWidget {
  final Function(LayoutTemplate?) onLayoutSelected;

  const LayoutPickerModal({
    super.key,
    required this.onLayoutSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Choose Layout',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Layout grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom option
                  _buildCustomOption(context),
                  
                  const SizedBox(height: 20),
                  
                  // Preset layouts
                  _buildLayoutGrid(context),
                ],
              ),
            ),
          ),
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

  Widget _buildLayoutGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preset Layouts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Group by photo count
        ..._buildLayoutGroups(context),
      ],
    );
  }

  List<Widget> _buildLayoutGroups(BuildContext context) {
    final groups = <Widget>[];
    
    // Group layouts by photo count
    final photoCounts = LayoutTemplates.templates
        .map((t) => t.photoCount)
        .toSet()
        .toList()
      ..sort();
    
    for (final count in photoCounts) {
      final layouts = LayoutTemplates.getByPhotoCount(count);
      groups.add(_buildLayoutGroup(context, count, layouts));
      groups.add(const SizedBox(height: 20));
    }
    
    return groups;
  }

  Widget _buildLayoutGroup(BuildContext context, int photoCount, List<LayoutTemplate> layouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$photoCount Photos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: layouts.length,
          itemBuilder: (context, index) {
            final layout = layouts[index];
            return _buildLayoutThumbnail(context, layout);
          },
        ),
      ],
    );
  }

  Widget _buildLayoutThumbnail(BuildContext context, LayoutTemplate layout) {
    return GestureDetector(
      onTap: () {
        onLayoutSelected(layout);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // Thumbnail preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                child: _buildLayoutPreview(layout),
              ),
            ),
            
            // Layout name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                layout.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutPreview(LayoutTemplate layout) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: LayoutPreviewPainter(layout.photoLayouts),
    );
  }
}

/// Custom painter for drawing layout previews
class LayoutPreviewPainter extends CustomPainter {
  final List<PhotoLayout> photoLayouts;

  LayoutPreviewPainter(this.photoLayouts);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[400]!
      ..style = PaintingStyle.fill;

    for (final photoLayout in photoLayouts) {
      final rect = Rect.fromLTWH(
        photoLayout.position.dx * size.width,
        photoLayout.position.dy * size.height,
        photoLayout.size.width * size.width,
        photoLayout.size.height * size.height,
      );
      
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
