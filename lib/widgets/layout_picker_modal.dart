import 'package:flutter/material.dart';
import '../models/layout_template.dart';

/// Modern layout picker modal with simple grid preview
class LayoutPickerModal extends StatelessWidget {
  final Function(LayoutTemplate?) onLayoutSelected;
  final bool isPremium;
  final VoidCallback onUpgradeRequested;
  final BuildContext hostContext;
  final ScrollController? scrollController;

  const LayoutPickerModal({
    super.key,
    required this.onLayoutSelected,
    required this.isPremium,
    required this.onUpgradeRequested,
    required this.hostContext,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = scrollController ?? ScrollController();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(0, -6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      'Choose Layout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCustomOption(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildLayoutGridSliver(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: scheme.onSurface,
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
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    'Create your own layout',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: scheme.onSurface.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  SliverGrid _buildLayoutGridSliver() {
    const int freeLayoutLimit = 8;
    final bool premium = isPremium;
    // Get all layouts
    List<LayoutTemplate> layouts = _uniqueLayoutsBySignature(LayoutTemplates.templates);

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns like the reference
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final layout = layouts[index];
          final bool locked = !premium && index >= freeLayoutLimit;
          return _buildModernLayoutTile(layout, context, locked);
        },
        childCount: layouts.length,
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
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            // Layout preview with borders
            Container(
              margin: const EdgeInsets.all(4),
              child: CustomPaint(
                size: const Size.square(double.infinity),
                painter: ModernLayoutPreviewPainter(
                  layout.photoLayouts,
                  fillColor: Colors.white,
                  strokeColor: Colors.black,
                ),
              ),
            ),
            if (locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
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
