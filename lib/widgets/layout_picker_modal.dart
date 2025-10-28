import 'package:flutter/material.dart';
import '../models/layout_template.dart';

/// Modern layout picker modal with simple grid preview
class LayoutPickerModal extends StatelessWidget {
  final Function(LayoutTemplate?) onLayoutSelected;
  final bool isPremium;
  final VoidCallback onUpgradeRequested;
  final BuildContext hostContext;

  const LayoutPickerModal({
    super.key,
    required this.onLayoutSelected,
    required this.isPremium,
    required this.onUpgradeRequested,
    required this.hostContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAEE),
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Choose Layout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onLayoutSelected(null); // null means custom mode
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Create your own layout',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutGrid() {
    const int freeLayoutLimit = 8;
    final bool premium = isPremium;
    // Get all layouts
    List<LayoutTemplate> layouts = _uniqueLayoutsBySignature(LayoutTemplates.templates);

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
          final bool locked = !premium && index >= freeLayoutLimit;
          return _buildModernLayoutTile(layout, context, locked);
        },
      ),
    );
  }

  // Deduplicate visually identical layouts by rounding rects to 1 decimal and hashing
  List<LayoutTemplate> _uniqueLayoutsBySignature(List<LayoutTemplate> all) {
    final seen = <String>{};
    final result = <LayoutTemplate>[];
    for (final t in all) {
      final sigParts = t.photoLayouts
          .map((p) =>
              '${_r(p.position.dx)},${_r(p.position.dy)},${_r(p.size.width)},${_r(p.size.height)}')
          .toList()
        ..sort();
      final sig = sigParts.join('|');
      if (seen.add(sig)) {
        result.add(t);
      }
    }
    return result;
  }

  String _r(double v) => (v * 10).round().toString(); // 1 decimal rounding key

  Widget _buildModernLayoutTile(
    LayoutTemplate layout,
    BuildContext context,
    bool locked,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (locked) {
          ScaffoldMessenger.of(hostContext).hideCurrentSnackBar();
          ScaffoldMessenger.of(hostContext).showSnackBar(
            const SnackBar(
              content: Text('Upgrade to unlock all premium layouts.'),
              duration: Duration(seconds: 2),
            ),
          );
          onUpgradeRequested();
          return;
        }
        onLayoutSelected(layout);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          children: [
            // Layout preview with borders
            Container(
              margin: const EdgeInsets.all(4),
              child: CustomPaint(
                size: const Size.square(double.infinity),
                painter: ModernLayoutPreviewPainter(
                  layout.photoLayouts,
                  fillColor: const Color(0xFFFCFAEE), // background fill
                  strokeColor: const Color(0xFFA5B68D), // frame color
                ),
              ),
            ),
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
  final Color fillColor;
  final Color strokeColor;

  ModernLayoutPreviewPainter(
    this.photoLayouts, {
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    final backgroundPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Border paint
    final borderPaint = Paint()
      ..color = strokeColor
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
