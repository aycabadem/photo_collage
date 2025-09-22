part of collage_manager_service;

mixin _CollageTransformControls on _CollageManagerBase {
  void moveBox(PhotoBox box, Offset delta) {
    final newX = box.position.dx + delta.dx;
    final newY = box.position.dy + delta.dy;

    final Offset basePosition = Offset(newX, newY);

    final Offset snappedPosition = _snappingSuspended
        ? basePosition
        : _applySnapping(basePosition, box);

    final Offset adjustedPosition = _snappingSuspended
        ? snappedPosition
        : _applyInnerMarginSpacing(snappedPosition, box);

    final clampedPosition = _clampBoxWithinTemplate(box, adjustedPosition);

    box.position = clampedPosition;
    notifyListeners();
  }

  void clampBoxToTemplate(PhotoBox box, {bool notify = false}) {
    final Offset originalPosition = box.position;
    final Size originalSize = box.size;
    final Offset clamped = _clampBoxWithinTemplate(box, originalPosition);
    if (clamped != originalPosition || box.size != originalSize) {
      box.position = clamped;
      if (notify) notifyListeners();
    }
  }

  Offset _applySnapping(Offset position, PhotoBox movingBox) {
    double snappedX = position.dx;
    double snappedY = position.dy;

    for (final otherBox in _photoBoxes) {
      if (otherBox == movingBox) continue;

      if ((position.dx - otherBox.position.dx).abs() <= 5) {
        snappedX = otherBox.position.dx;
      }

      if ((position.dx +
                  movingBox.size.width -
                  otherBox.position.dx -
                  otherBox.size.width)
              .abs() <=
          5) {
        snappedX =
            otherBox.position.dx + otherBox.size.width - movingBox.size.width;
      }

      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
          5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
      }

      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
          5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
      }

      if ((position.dy - otherBox.position.dy).abs() <= 5) {
        snappedY = otherBox.position.dy;
      }

      if ((position.dy +
                  movingBox.size.height -
                  otherBox.position.dy -
                  otherBox.size.height)
              .abs() <=
          5) {
        snappedY = otherBox.position.dy +
            otherBox.size.height -
            movingBox.size.height;
      }

      if ((position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
          5) {
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      if ((position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
          5) {
        snappedY = otherBox.position.dy - movingBox.size.height;
      }

      final movingCenterX = position.dx + movingBox.size.width / 2;
      final otherCenterX = otherBox.position.dx + otherBox.size.width / 2;
      if ((movingCenterX - otherCenterX).abs() <= 5) {
        snappedX = otherCenterX - movingBox.size.width / 2;
      }

      final movingCenterY = position.dy + movingBox.size.height / 2;
      final otherCenterY = otherBox.position.dy + otherBox.size.height / 2;
      if ((movingCenterY - otherCenterY).abs() <= 5) {
        snappedY = otherCenterY - movingBox.size.height / 2;
      }

      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
              5 &&
          (position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
              5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
              5 &&
          (position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
              5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
              5 &&
          (position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
              5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
        snappedY = otherBox.position.dy - movingBox.size.height;
      }

      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
              5 &&
          (position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
              5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
        snappedY = otherBox.position.dy - movingBox.size.height;
      }
    }

    final centerX = _templateSize.width / 2;
    final centerY = _templateSize.height / 2;
    final movingCenterX = position.dx + movingBox.size.width / 2;
    final movingCenterY = position.dy + movingBox.size.height / 2;

    if ((movingCenterX - centerX).abs() <= 5) {
      snappedX = centerX - movingBox.size.width / 2;
    }
    if ((movingCenterY - centerY).abs() <= 5) {
      snappedY = centerY - movingBox.size.height / 2;
    }

    return Offset(snappedX, snappedY);
  }

  Offset _applyInnerMarginSpacing(Offset position, PhotoBox movingBox) {
    if (_innerMargin <= 0) return position;

    double adjustedX = position.dx;
    double adjustedY = position.dy;

    for (final otherBox in _photoBoxes) {
      if (otherBox == movingBox) continue;

      final movingRight = position.dx + movingBox.size.width;
      final movingBottom = position.dy + movingBox.size.height;
      final otherRight = otherBox.position.dx + otherBox.size.width;
      final otherBottom = otherBox.position.dy + otherBox.size.height;

      if (movingRight <= otherBox.position.dx) {
        final gap = otherBox.position.dx - movingRight;
        if (gap < _innerMargin) {
          adjustedX =
              otherBox.position.dx - movingBox.size.width - _innerMargin;
        }
      } else if (position.dx >= otherRight) {
        final gap = position.dx - otherRight;
        if (gap < _innerMargin) {
          adjustedX = otherRight + _innerMargin;
        }
      }

      if (movingBottom <= otherBox.position.dy) {
        final gap = otherBox.position.dy - movingBottom;
        if (gap < _innerMargin) {
          adjustedY =
              otherBox.position.dy - movingBox.size.height - _innerMargin;
        }
      } else if (position.dy >= otherBottom) {
        final gap = position.dy - otherBottom;
        if (gap < _innerMargin) {
          adjustedY = otherBottom + _innerMargin;
        }
      }
    }

    return Offset(adjustedX, adjustedY);
  }

  (double left, double top, double right, double bottom) _snapResizedEdges(
    PhotoBox box,
    double left,
    double top,
    double right,
    double bottom,
    bool moveLeftEdge,
    bool moveRightEdge,
    bool moveTopEdge,
    bool moveBottomEdge,
  ) {
    const double minSize = 50.0;
    const double snapThreshold = 6.0;

    double snapValue(double value, List<double> targets) {
      double snapped = value;
      double smallestDiff = snapThreshold + 1;
      for (final target in targets) {
        final double diff = (value - target).abs();
        if (diff <= snapThreshold && diff < smallestDiff) {
          smallestDiff = diff;
          snapped = target;
        }
      }
      return snapped;
    }

    final List<double> horizontalTargets = [0.0, _templateSize.width];
    final List<double> verticalTargets = [0.0, _templateSize.height];

    for (final other in _photoBoxes) {
      if (other == box) continue;
      final double otherLeft = other.position.dx;
      final double otherTop = other.position.dy;
      final double otherRight = otherLeft + other.size.width;
      final double otherBottom = otherTop + other.size.height;

      horizontalTargets.addAll([otherLeft, otherRight]);
      verticalTargets.addAll([otherTop, otherBottom]);

      if (_innerMargin > 0) {
        horizontalTargets.addAll([
          otherLeft - _innerMargin,
          otherRight + _innerMargin,
        ]);
        verticalTargets.addAll([
          otherTop - _innerMargin,
          otherBottom + _innerMargin,
        ]);
      }
    }

    if (moveLeftEdge) {
      final double snappedLeft = snapValue(left, horizontalTargets);
      if (snappedLeft != left) {
        left = snappedLeft;
      }
      if (left < 0) left = 0;
      if (right - left < minSize) {
        left = right - minSize;
      }
    }

    if (moveRightEdge) {
      final double snappedRight = snapValue(right, horizontalTargets);
      if (snappedRight != right) {
        right = snappedRight;
      }
      if (right > _templateSize.width) right = _templateSize.width;
      if (right - left < minSize) {
        right = left + minSize;
      }
    }

    if (moveTopEdge) {
      final double snappedTop = snapValue(top, verticalTargets);
      if (snappedTop != top) {
        top = snappedTop;
      }
      if (top < 0) top = 0;
      if (bottom - top < minSize) {
        top = bottom - minSize;
      }
    }

    if (moveBottomEdge) {
      final double snappedBottom = snapValue(bottom, verticalTargets);
      if (snappedBottom != bottom) {
        bottom = snappedBottom;
      }
      if (bottom > _templateSize.height) bottom = _templateSize.height;
      if (bottom - top < minSize) {
        bottom = top + minSize;
      }
    }

    return (left, top, right, bottom);
  }

  Offset getAdjustedPosition(PhotoBox box) {
    if (_innerMargin <= 0) return box.position;
    return _applyInnerMarginSpacing(box.position, box);
  }

  void resizeBox(PhotoBox box, double deltaWidth, double deltaHeight) {
    final double newWidth = CollageUtils.safeClamp(
      box.size.width + deltaWidth,
      50.0,
      _templateSize.width - box.position.dx,
    );
    final double newHeight = CollageUtils.safeClamp(
      box.size.height + deltaHeight,
      50.0,
      _templateSize.height - box.position.dy,
    );

    if (newWidth >= 50 && newHeight >= 50) {
      box.size = Size(newWidth, newHeight);
      notifyListeners();
    }
  }

  void resizeBoxFromHandle(
    PhotoBox box,
    Alignment handleAlignment,
    double deltaWidth,
    double deltaHeight,
  ) {
    const double minSize = 50.0;
    final double oldWidth = box.size.width;
    final double oldHeight = box.size.height;
    final double oldX = box.position.dx;
    final double oldY = box.position.dy;

    final double angle = box.rotationRadians;
    final double cosAngle = math.cos(angle);
    final double sinAngle = math.sin(angle);

    double localDx = deltaWidth;
    double localDy = deltaHeight;
    if (angle.abs() > 1e-4) {
      final double rotatedDx = (cosAngle * localDx) + (sinAngle * localDy);
      final double rotatedDy = (-sinAngle * localDx) + (cosAngle * localDy);
      localDx = rotatedDx;
      localDy = rotatedDy;
    }

    double newWidth = oldWidth;
    double newHeight = oldHeight;

    if (handleAlignment == Alignment.topLeft) {
      newWidth = math.max(minSize, oldWidth - localDx);
      newHeight = math.max(minSize, oldHeight - localDy);
    } else if (handleAlignment == Alignment.topRight) {
      newWidth = math.max(minSize, oldWidth + localDx);
      newHeight = math.max(minSize, oldHeight - localDy);
    } else if (handleAlignment == Alignment.bottomLeft) {
      newWidth = math.max(minSize, oldWidth - localDx);
      newHeight = math.max(minSize, oldHeight + localDy);
    } else if (handleAlignment == Alignment.bottomRight) {
      newWidth = math.max(minSize, oldWidth + localDx);
      newHeight = math.max(minSize, oldHeight + localDy);
    }

    if (newWidth < minSize || newHeight < minSize) {
      return;
    }

    final double oldCenterX = oldX + oldWidth * 0.5;
    final double oldCenterY = oldY + oldHeight * 0.5;

    Offset cornerOffset(Alignment alignment, double width, double height) {
      return Offset(
        alignment.x * width * 0.5,
        alignment.y * height * 0.5,
      );
    }

    Offset rotateLocal(Offset local) {
      return Offset(
        (local.dx * cosAngle) - (local.dy * sinAngle),
        (local.dx * sinAngle) + (local.dy * cosAngle),
      );
    }

    final Alignment pivotAlignment = Alignment(-handleAlignment.x, -handleAlignment.y);
    final Offset pivotLocalOld = cornerOffset(pivotAlignment, oldWidth, oldHeight);
    final Offset pivotWorld = Offset(oldCenterX, oldCenterY) + rotateLocal(pivotLocalOld);
    final Offset pivotLocalNew = cornerOffset(pivotAlignment, newWidth, newHeight);
    final Offset rotatedPivotLocalNew = rotateLocal(pivotLocalNew);

    final double newCenterX = pivotWorld.dx - rotatedPivotLocalNew.dx;
    final double newCenterY = pivotWorld.dy - rotatedPivotLocalNew.dy;

    double newX = newCenterX - newWidth * 0.5;
    double newY = newCenterY - newHeight * 0.5;

    final bool moveLeftEdge = handleAlignment.x < 0;
    final bool moveRightEdge = handleAlignment.x > 0;
    final bool moveTopEdge = handleAlignment.y < 0;
    final bool moveBottomEdge = handleAlignment.y > 0;

    final double initialRight = newX + newWidth;
    final double initialBottom = newY + newHeight;

    final (snappedLeft, snappedTop, snappedRight, snappedBottom) =
        _snapResizedEdges(
      box,
      newX,
      newY,
      initialRight,
      initialBottom,
      moveLeftEdge,
      moveRightEdge,
      moveTopEdge,
      moveBottomEdge,
    );

    newX = snappedLeft;
    newY = snappedTop;
    newWidth = snappedRight - snappedLeft;
    newHeight = snappedBottom - snappedTop;

    box.size = Size(newWidth, newHeight);
    box.position = Offset(newX, newY);

    final Offset clamped = _clampBoxWithinTemplate(box, box.position);
    box.position = clamped;

    notifyListeners();
  }

  void resizePairAlongEdge(PhotoBox a, PhotoBox b, bool isVertical, double delta) {
    if (isVertical) {
      PhotoBox left = a.position.dx <= b.position.dx ? a : b;
      PhotoBox right = left == a ? b : a;

      const double minSize = 50.0;
      final double minDelta = -(left.size.width - minSize);
      final double maxDelta = (right.size.width - minSize);
      final double clampedDelta = delta.clamp(minDelta, maxDelta);

      final double newLeftWidth = left.size.width + clampedDelta;
      final double newRightWidth = right.size.width - clampedDelta;

      left.size = Size(newLeftWidth, left.size.height);
      right.position = Offset(right.position.dx + clampedDelta, right.position.dy);
      right.size = Size(newRightWidth, right.size.height);
      notifyListeners();
    } else {
      PhotoBox top = a.position.dy <= b.position.dy ? a : b;
      PhotoBox bottom = top == a ? b : a;

      const double minSize = 50.0;
      final double minDelta = -(top.size.height - minSize);
      final double maxDelta = (bottom.size.height - minSize);
      final double clampedDelta = delta.clamp(minDelta, maxDelta);

      final double newTopHeight = top.size.height + clampedDelta;
      final double newBottomHeight = bottom.size.height - clampedDelta;

      top.size = Size(top.size.width, newTopHeight);
      bottom.position = Offset(bottom.position.dx, bottom.position.dy + clampedDelta);
      bottom.size = Size(bottom.size.width, newBottomHeight);
      notifyListeners();
    }
  }

  void resizeGroupAlongEdge(
    PhotoBox anchor,
    List<PhotoBox> group,
    bool isVertical,
    bool groupOnNegativeSide,
    double delta,
  ) {
    if (group.isEmpty) return;
    const double minSize = 50.0;

    if (isVertical) {
      double minDelta = -double.infinity;
      double maxDelta = double.infinity;

      if (groupOnNegativeSide) {
        maxDelta = anchor.size.width - minSize;
        for (final n in group) {
          final double nd = -(n.size.width - minSize);
          if (nd > minDelta) minDelta = nd;
        }
      } else {
        minDelta = -(anchor.size.width - minSize);
        for (final n in group) {
          final double nd = (n.size.width - minSize);
          if (nd < maxDelta) maxDelta = nd;
        }
      }

      final double clamped = delta.clamp(minDelta, maxDelta);

      if (groupOnNegativeSide) {
        for (final n in group) {
          n.size = Size(n.size.width + clamped, n.size.height);
        }
        anchor.position = Offset(anchor.position.dx + clamped, anchor.position.dy);
        anchor.size = Size(anchor.size.width - clamped, anchor.size.height);
      } else {
        for (final n in group) {
          n.position = Offset(n.position.dx + clamped, n.position.dy);
          n.size = Size(n.size.width - clamped, n.size.height);
        }
        anchor.size = Size(anchor.size.width + clamped, anchor.size.height);
      }

      notifyListeners();
    } else {
      double minDelta = -double.infinity;
      double maxDelta = double.infinity;

      if (groupOnNegativeSide) {
        maxDelta = anchor.size.height - minSize;
        for (final n in group) {
          final double nd = -(n.size.height - minSize);
          if (nd > minDelta) minDelta = nd;
        }
      } else {
        minDelta = -(anchor.size.height - minSize);
        for (final n in group) {
          final double nd = (n.size.height - minSize);
          if (nd < maxDelta) maxDelta = nd;
        }
      }

      final double clamped = delta.clamp(minDelta, maxDelta);

      if (groupOnNegativeSide) {
        for (final n in group) {
          n.size = Size(n.size.width, n.size.height + clamped);
        }
        anchor.position = Offset(anchor.position.dx, anchor.position.dy + clamped);
        anchor.size = Size(anchor.size.width, anchor.size.height - clamped);
      } else {
        for (final n in group) {
          n.position = Offset(n.position.dx, n.position.dy + clamped);
          n.size = Size(n.size.width, n.size.height - clamped);
        }
        anchor.size = Size(anchor.size.width, anchor.size.height + clamped);
      }

      notifyListeners();
    }
  }

  double resizeTwoGroupsAlongEdge(
    List<PhotoBox> negativeGroup,
    List<PhotoBox> positiveGroup,
    bool isVertical,
    double delta,
  ) {
    if (negativeGroup.isEmpty && positiveGroup.isEmpty) return 0.0;
    const double minSize = 50.0;

    if (isVertical) {
      double minDelta = double.negativeInfinity;
      double maxDelta = double.infinity;

      for (final n in negativeGroup) {
        final double nd = minSize - n.size.width;
        if (nd > minDelta) minDelta = nd;
      }
      for (final p in positiveGroup) {
        final double pd = p.size.width - minSize;
        if (pd < maxDelta) maxDelta = pd;
      }

      final double clamped = delta.clamp(minDelta, maxDelta);

      for (final n in negativeGroup) {
        n.size = Size(n.size.width + clamped, n.size.height);
      }
      for (final p in positiveGroup) {
        p.position = Offset(p.position.dx + clamped, p.position.dy);
        p.size = Size(p.size.width - clamped, p.size.height);
      }
      notifyListeners();
      return clamped;
    } else {
      double minDelta = double.negativeInfinity;
      double maxDelta = double.infinity;

      for (final n in negativeGroup) {
        final double nd = minSize - n.size.height;
        if (nd > minDelta) minDelta = nd;
      }
      for (final p in positiveGroup) {
        final double pd = p.size.height - minSize;
        if (pd < maxDelta) maxDelta = pd;
      }

      final double clamped = delta.clamp(minDelta, maxDelta);

      for (final n in negativeGroup) {
        n.size = Size(n.size.width, n.size.height + clamped);
      }
      for (final p in positiveGroup) {
        p.position = Offset(p.position.dx, p.position.dy + clamped);
        p.size = Size(p.size.width, p.size.height - clamped);
      }
      notifyListeners();
      return clamped;
    }
  }

  void snapGroupsToVerticalLine(
    List<PhotoBox> negativeGroup,
    List<PhotoBox> positiveGroup,
    double x,
  ) {
    for (final n in negativeGroup) {
      n.position = Offset(x - n.size.width, n.position.dy);
    }
    for (final p in positiveGroup) {
      p.position = Offset(x, p.position.dy);
    }
    notifyListeners();
  }

  void snapGroupsToHorizontalLine(
    List<PhotoBox> negativeGroup,
    List<PhotoBox> positiveGroup,
    double y,
  ) {
    for (final n in negativeGroup) {
      n.position = Offset(n.position.dx, y - n.size.height);
    }
    for (final p in positiveGroup) {
      p.position = Offset(p.position.dx, y);
    }
    notifyListeners();
  }

  void snapNeighborsToAnchorEdge(
    PhotoBox anchor,
    List<PhotoBox> group,
    bool isVertical,
    bool groupOnNegativeSide,
  ) {
    const double eps = 0.5;
    if (group.isEmpty) return;
    if (isVertical) {
      final double anchorLeft = anchor.position.dx;
      final double anchorRight = anchor.position.dx + anchor.size.width;
      if (groupOnNegativeSide) {
        for (final n in group) {
          final double nRight = n.position.dx + n.size.width;
          if ((nRight - anchorLeft).abs() <= eps) {
            n.position = Offset(anchorLeft - n.size.width, n.position.dy);
          }
        }
      } else {
        for (final n in group) {
          if ((n.position.dx - anchorRight).abs() <= eps) {
            n.position = Offset(anchorRight, n.position.dy);
          }
        }
      }
    } else {
      final double anchorTop = anchor.position.dy;
      final double anchorBottom = anchor.position.dy + anchor.size.height;
      if (groupOnNegativeSide) {
        for (final n in group) {
          final double nBottom = n.position.dy + n.size.height;
          if ((nBottom - anchorTop).abs() <= eps) {
            n.position = Offset(n.position.dx, anchorTop - n.size.height);
          }
        }
      } else {
        for (final n in group) {
          if ((n.position.dy - anchorBottom).abs() <= eps) {
            n.position = Offset(n.position.dx, anchorBottom);
          }
        }
      }
    }
    notifyListeners();
  }
}
