part of '../collage_manager.dart';

mixin _CollageExportControls on _CollageManagerBase {
  Future<String?> saveCollage({int? exportWidth}) async {
    try {
      final double aspectRatio = _selectedAspect.ratio;
      final int resolvedWidth = (exportWidth ?? _selectedExportWidth).clamp(800, 8000);
      final int resolvedHeight = (resolvedWidth / aspectRatio).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final rect = Rect.fromLTWH(0, 0, resolvedWidth.toDouble(), resolvedHeight.toDouble());
      if (_backgroundMode == BackgroundMode.gradient) {
        final angle = _backgroundGradient.angleDeg * math.pi / 180.0;
        final cx = resolvedWidth / 2.0;
        final cy = resolvedHeight / 2.0;
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        final halfDiag = 0.5 * math.sqrt(
          resolvedWidth * resolvedWidth + resolvedHeight * resolvedHeight,
        );
        final start = Offset(cx - dx * halfDiag, cy - dy * halfDiag);
        final end = Offset(cx + dx * halfDiag, cy + dy * halfDiag);

        final colors = _backgroundGradient.stops
            .map((s) => s.color.withValues(alpha: s.color.a * _backgroundOpacity))
            .toList();
        final stops = _backgroundGradient.stops.map((s) => s.offset).toList();
        final shader = ui.Gradient.linear(start, end, colors, stops);
        final paint = Paint()..shader = shader;
        canvas.drawRect(rect, paint);
      } else {
        final paint = Paint()..color = backgroundColorWithOpacity;
        canvas.drawRect(rect, paint);
      }

      final double scaleX = resolvedWidth / _templateSize.width;
      final double scaleY = resolvedHeight / _templateSize.height;
      final double outerX = _outerMargin * scaleX;
      final double outerY = _outerMargin * scaleY;
      final double sX = (resolvedWidth - 2 * outerX) / _templateSize.width;
      final double sY = (resolvedHeight - 2 * outerY) / _templateSize.height;
      final double innerHalfX = (_innerMargin * 0.5) * sX;
      final double innerHalfY = (_innerMargin * 0.5) * sY;

      for (final box in _photoBoxes) {
        if (box.imageFile == null || !box.imageFile!.existsSync()) continue;

        try {
          final image = await _loadImage(box.imageFile!);
          if (image == null) continue;

          double baseLeft = outerX + box.position.dx * sX;
          double baseTop = outerY + box.position.dy * sY;
          double baseW = box.size.width * sX;
          double baseH = box.size.height * sY;

          const double eps = 0.5;
          final bool isLeftEdge = box.position.dx <= eps;
          final bool isRightEdge =
              (box.position.dx + box.size.width) >= (_templateSize.width - eps);
          final bool isTopEdge = box.position.dy <= eps;
          final bool isBottomEdge =
              (box.position.dy + box.size.height) >= (_templateSize.height - eps);

          final double leftInset = isLeftEdge ? 0.0 : innerHalfX;
          final double rightInset = isRightEdge ? 0.0 : innerHalfX;
          final double topInset = isTopEdge ? 0.0 : innerHalfY;
          final double bottomInset = isBottomEdge ? 0.0 : innerHalfY;

          final Rect dstRect = Rect.fromLTWH(
            baseLeft + leftInset,
            baseTop + topInset,
            math.max(1, baseW - (leftInset + rightInset)),
            math.max(1, baseH - (topInset + bottomInset)),
          );

          final Rect srcRect = _computeSrcRectForFit(
            image,
            dstRect.size,
            box.imageFit,
            box.alignment,
            box.photoScale,
          );

          if (_shadowIntensity > 0) {
            final double t = (_shadowIntensity.clamp(0.0, 14.0)) / 14.0;
            final double blur = 8 + 12 * t;
            final double yOff = 4 + 6 * t;
            final double a = 0.15 + 0.10 * t;
            final Paint shadowPaint = Paint()
              ..color = Colors.black.withValues(alpha: a)
              ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
            final RRect shadowRRect = RRect.fromRectAndRadius(
              dstRect.translate(0, yOff),
              Radius.circular(cornerRadius * ((sX + sY) / 2)),
            );
            canvas.drawRRect(shadowRRect, shadowPaint);
          }

          final double r = cornerRadius * ((sX + sY) / 2);
          final double cx = dstRect.center.dx;
          final double cy = dstRect.center.dy;
          final double w = dstRect.width;
          final double h = dstRect.height;
          final Rect localDst = Rect.fromLTWH(-w / 2, -h / 2, w, h);

          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(box.rotationRadians);
          if (r > 0) {
            canvas.clipRRect(
              RRect.fromRectAndRadius(localDst, Radius.circular(r)),
            );
          } else {
            canvas.clipRect(localDst);
          }

          final paintImg = Paint()
            ..isAntiAlias = true
            ..filterQuality = FilterQuality.high;
          canvas.drawImageRect(image, srcRect, localDst, paintImg);

          if (_hasGlobalBorder && _globalBorderWidth > 0) {
            _drawSimpleBorders(
              canvas,
              Offset(localDst.left, localDst.top),
              Size(localDst.width, localDst.height),
              sX,
              sY,
            );
          }
          canvas.restore();
        } catch (_) {
          // Ignore failures for individual images during export
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(resolvedWidth, resolvedHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      final result = await SaverGallery.saveImage(
        byteData.buffer.asUint8List(),
        quality: 100,
        name: 'collage_${DateTime.now().millisecondsSinceEpoch}.png',
        isReturnPathOfIOS: true,
        androidRelativePath: 'Pictures/CollageMaker',
      );

      if (result.isSuccess) {
        final String path = (result.filePath ?? '').trim();
        if (path.isNotEmpty) {
          return path;
        }
        return '';
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _loadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Rect _computeSrcRectForFit(
    ui.Image image,
    Size dstSize,
    BoxFit fit,
    Alignment alignment,
    double additionalScale,
  ) {
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();
    if (fit == BoxFit.fill) {
      return Rect.fromLTWH(0, 0, imgW, imgH);
    }
    if (fit == BoxFit.contain) {
      final double visibleW = imgW;
      final double visibleH = imgH;
      return Rect.fromLTWH(0, 0, visibleW, visibleH);
    }
    double scale = math.max(dstSize.width / imgW, dstSize.height / imgH);
    if (additionalScale.isFinite && additionalScale > 0) {
      scale *= additionalScale;
    }
    final double cropW = dstSize.width / scale;
    final double cropH = dstSize.height / scale;
    final double extraW = imgW - cropW;
    final double extraH = imgH - cropH;
    final double alignX = (alignment.x + 1) / 2;
    final double alignY = (alignment.y + 1) / 2;
    final double left = extraW * alignX.clamp(0.0, 1.0);
    final double top = extraH * alignY.clamp(0.0, 1.0);
    return Rect.fromLTWH(left, top, cropW, cropH);
  }

  void _drawSimpleBorders(
    Canvas canvas,
    Offset position,
    Size size,
    double scaleX,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = _globalBorderColor
      ..strokeWidth = _globalBorderWidth * scaleX
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(position.dx, position.dy),
      Offset(position.dx, position.dy + size.height),
      paint,
    );

    canvas.drawLine(
      Offset(position.dx + size.width, position.dy),
      Offset(position.dx + size.width, position.dy + size.height),
      paint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy),
      Offset(position.dx + size.width, position.dy),
      paint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy + size.height),
      Offset(position.dx + size.width, position.dy + size.height),
      paint,
    );
  }
}
