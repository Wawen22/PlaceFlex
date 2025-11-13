import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../moments/models/moment.dart';

/// Genera icone personalizzate per momenti sulla mappa
/// Design 2026: gradiente, ombra, icone per tipo media, animazioni
class MomentMarkerIcon {
  /// Crea icona singola momento con gradiente e icona per tipo media
  static Future<Uint8List> createMarkerForType({
    required MomentMediaType mediaType,
    required bool isDark,
    double size = 56,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // Gradiente personalizzato per tipo media
    final gradientColors = _getGradientForType(mediaType);
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size, size),
      gradientColors,
    );

    // Ombra esterna più delicata
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(size / 2, size / 2 + 2), size / 2.5, shadowPaint);

    // Cerchio principale con gradiente
    paint.shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, paint);

    // Cerchio bianco semi-trasparente per contrasto icona
    final iconBgPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 3.2, iconBgPaint);

    // Bordo interno bianco più sottile
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, borderPaint);

    // Disegna icona per tipo media
    _drawMediaIcon(canvas, mediaType, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Restituisce gradiente personalizzato per tipo media
  static List<Color> _getGradientForType(MomentMediaType type) {
    switch (type) {
      case MomentMediaType.photo:
        return [
          const Color(0xFF00FFA3), // Verde
          const Color(0xFF0094FF), // Blu
        ];
      case MomentMediaType.video:
        return [
          const Color(0xFFFF0080), // Magenta
          const Color(0xFFFF8C00), // Arancione
        ];
      case MomentMediaType.audio:
        return [
          const Color(0xFF9D00FF), // Viola
          const Color(0xFFFF00F5), // Rosa
        ];
      case MomentMediaType.text:
        return [
          const Color(0xFFFFD700), // Oro
          const Color(0xFFFF6B00), // Arancione scuro
        ];
    }
  }

  /// Disegna l'icona specifica per il tipo di media
  static void _drawMediaIcon(Canvas canvas, MomentMediaType type, double size) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final centerX = size / 2;
    final centerY = size / 2;
    final iconSize = size / 2.8;

    switch (type) {
      case MomentMediaType.photo:
        _drawCameraIcon(
          canvas,
          centerX,
          centerY,
          iconSize,
          iconPaint,
          strokePaint,
        );
        break;
      case MomentMediaType.video:
        _drawPlayIcon(canvas, centerX, centerY, iconSize, iconPaint);
        break;
      case MomentMediaType.audio:
        _drawMicIcon(
          canvas,
          centerX,
          centerY,
          iconSize,
          iconPaint,
          strokePaint,
        );
        break;
      case MomentMediaType.text:
        _drawTextIcon(
          canvas,
          centerX,
          centerY,
          iconSize,
          iconPaint,
          strokePaint,
        );
        break;
    }
  }

  /// Icona camera (foto) - Design semplificato
  static void _drawCameraIcon(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    // Body principale della camera (rettangolo arrotondato)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + size * 0.08),
        width: size * 1.1,
        height: size * 0.75,
      ),
      const Radius.circular(6),
    );

    // Riempi il body
    canvas.drawRRect(bodyRect, fillPaint);

    // Bordo body per definizione
    strokePaint.strokeWidth = 2.0;
    canvas.drawRRect(bodyRect, strokePaint);

    // Lente circolare centrale più grande
    final lensPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(Offset(cx, cy + size * 0.08), size * 0.28, lensPaint);

    // Cerchio interno lente per effetto vetro
    final innerLensPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(cx, cy + size * 0.08),
      size * 0.15,
      innerLensPaint,
    );

    // Flash in alto a destra (piccolo cerchio)
    final flashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx + size * 0.35, cy - size * 0.25),
      size * 0.08,
      flashPaint,
    );
  }

  /// Icona play (video)
  static void _drawPlayIcon(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint fillPaint,
  ) {
    final path = Path();

    // Triangolo play centrato
    path.moveTo(cx - size * 0.3, cy - size * 0.45);
    path.lineTo(cx - size * 0.3, cy + size * 0.45);
    path.lineTo(cx + size * 0.45, cy);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  /// Icona microfono (audio)
  static void _drawMicIcon(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    // Capsula microfono
    final micRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - size * 0.15),
        width: size * 0.5,
        height: size * 0.7,
      ),
      Radius.circular(size * 0.25),
    );
    canvas.drawRRect(micRect, fillPaint);

    // Stand base
    final standPath = Path();
    standPath.moveTo(cx, cy + size * 0.3);
    standPath.lineTo(cx, cy + size * 0.5);
    standPath.moveTo(cx - size * 0.3, cy + size * 0.5);
    standPath.lineTo(cx + size * 0.3, cy + size * 0.5);
    canvas.drawPath(standPath, strokePaint);
  }

  /// Icona testo (text)
  static void _drawTextIcon(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    strokePaint.strokeWidth = 3;

    // Tre linee di testo
    final lineSpacing = size * 0.35;
    for (int i = 0; i < 3; i++) {
      final y = cy - lineSpacing + (i * lineSpacing);
      final lineWidth = i == 1 ? size * 1.1 : size * 0.8;

      canvas.drawLine(
        Offset(cx - lineWidth / 2, y),
        Offset(cx + lineWidth / 2, y),
        strokePaint,
      );
    }
  }

  /// Crea icona cluster con contatore
  static Future<Uint8List> createClusterMarker({
    required int count,
    required bool isDark,
    double size = 64,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // Gradiente per cluster (radiale)
    final gradient = ui.Gradient.radial(Offset(size / 2, size / 2), size / 2, [
      const Color(0xFF0094FF).withOpacity(0.95),
      const Color(0xFF00FFA3).withOpacity(0.95),
    ]);

    // Ombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2.2, shadowPaint);

    // Cerchio esterno con gradiente
    paint.shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint);

    // Cerchio interno bianco per contatore
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3.2, innerPaint);

    // Disegna numero
    final textSpan = TextSpan(
      text: count > 99 ? '99+' : count.toString(),
      style: TextStyle(
        color: const Color(0xFF0094FF),
        fontSize: size / 3.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
