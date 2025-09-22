part of collage_manager_service;

mixin _CollageGuidelineControls on _CollageManagerBase {
  List<AlignmentGuideline> getAlignmentGuidelines(PhotoBox selectedBox) {
    if (_snappingSuspended) {
      return const [];
    }
    try {
      final List<AlignmentGuideline> guidelines = [];

      final centerX = _templateSize.width / 2;
      final centerY = _templateSize.height / 2;

      final photoCenterX = selectedBox.position.dx + selectedBox.size.width / 2;
      final photoCenterY =
          selectedBox.position.dy + selectedBox.size.height / 2;

      if ((photoCenterX - centerX).abs() <= 5) {
        guidelines.add(
          AlignmentGuideline(
            position: centerX,
            isHorizontal: false,
            type: 'background-center',
            label: 'Background Center',
          ),
        );
      }

      if ((photoCenterY - centerY).abs() <= 5) {
        guidelines.add(
          AlignmentGuideline(
            position: centerY,
            isHorizontal: true,
            type: 'background-center',
            label: 'Background Center',
          ),
        );
      }

      if (_photoBoxes.length <= 1) {
        return guidelines;
      }

      for (final otherBox in _photoBoxes) {
        if (otherBox == selectedBox) continue;

        if ((selectedBox.position.dx - otherBox.position.dx).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'edge',
              label: 'Left Edge',
            ),
          );
        }

        if ((selectedBox.position.dx +
                    selectedBox.size.width -
                    otherBox.position.dx -
                    otherBox.size.width)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'edge',
              label: 'Right Edge',
            ),
          );
        }

        if ((selectedBox.position.dx -
                    (otherBox.position.dx + otherBox.size.width))
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'edge',
              label: 'Left to Right Edge',
            ),
          );
        }

        if (((selectedBox.position.dx + selectedBox.size.width) -
                    otherBox.position.dx)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'edge',
              label: 'Right to Left Edge',
            ),
          );
        }

        if ((selectedBox.position.dy - otherBox.position.dy).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'edge',
              label: 'Top Edge',
            ),
          );
        }

        if ((selectedBox.position.dy +
                    selectedBox.size.height -
                    otherBox.position.dy -
                    otherBox.size.height)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'edge',
              label: 'Bottom Edge',
            ),
          );
        }

        if ((selectedBox.position.dy -
                    (otherBox.position.dy + otherBox.size.height))
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'edge',
              label: 'Top to Bottom Edge',
            ),
          );
        }

        if (((selectedBox.position.dy + selectedBox.size.height) -
                    otherBox.position.dy)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'edge',
              label: 'Bottom to Top Edge',
            ),
          );
        }

        final selectedCenterX =
            selectedBox.position.dx + selectedBox.size.width / 2;
        final otherCenterX = otherBox.position.dx + otherBox.size.width / 2;
        final selectedCenterY =
            selectedBox.position.dy + selectedBox.size.height / 2;
        final otherCenterY = otherBox.position.dy + otherBox.size.height / 2;

        if ((selectedCenterX - otherCenterX).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterX,
              isHorizontal: false,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        if ((selectedCenterY - otherCenterY).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterY,
              isHorizontal: true,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        if ((selectedBox.position.dx -
                        (otherBox.position.dx + otherBox.size.width))
                    .abs() <=
                5 &&
            (selectedBox.position.dy -
                        (otherBox.position.dy + otherBox.size.height))
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        if (((selectedBox.position.dx + selectedBox.size.width) -
                        otherBox.position.dx)
                    .abs() <=
                5 &&
            (selectedBox.position.dy -
                        (otherBox.position.dy + otherBox.size.height))
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        if ((selectedBox.position.dx -
                        (otherBox.position.dx + otherBox.size.width))
                    .abs() <=
                5 &&
            ((selectedBox.position.dy + selectedBox.size.height) -
                        otherBox.position.dy)
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        if (((selectedBox.position.dx + selectedBox.size.width) -
                        otherBox.position.dx)
                    .abs() <=
                5 &&
            ((selectedBox.position.dy + selectedBox.size.height) -
                        otherBox.position.dy)
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }
      }

      return guidelines;
    } catch (_) {
      return [];
    }
  }
}
