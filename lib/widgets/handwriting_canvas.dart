import 'package:flutter/material.dart';

class HandwritingCanvas extends StatefulWidget {
  final Color strokeColor;
  final double strokeWidth;
  final bool showBackground;
  final Color backgroundColor;
  final Color borderColor;
  final String? hintText;
  final VoidCallback? onDrawingChanged;
  final bool enabled;

  const HandwritingCanvas({
    super.key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.showBackground = true,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.hintText,
    this.onDrawingChanged,
    this.enabled = true,
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas> {

  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    widget.onDrawingChanged?.call();
  }

  List<List<Offset>> getAllPoints() {
    return List.unmodifiable(_strokes);
  }

  Rect? getBoundingBox() {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in _strokes) {
      for (final point in stroke) {
        minX = point.dx < minX ? point.dx : minX;
        minY = point.dy < minY ? point.dy : minY;
        maxX = point.dx > maxX ? point.dx : maxX;
        maxY = point.dy > maxY ? point.dy : maxY;
      }
    }

    if (minX == double.infinity) return null;

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  int getStrokeCount() {
    return _strokes.length;
  }

  int getTotalPointCount() {
    return _strokes.fold(0, (sum, stroke) => sum + stroke.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled ? (details) {
        setState(() {
          _currentStroke = [details.localPosition];
        });
      } : null,
      onPanUpdate: widget.enabled ? (details) {
        if (_currentStroke != null) {
          setState(() {
            _currentStroke = List.from(_currentStroke!)..add(details.localPosition);
          });
        }
        widget.onDrawingChanged?.call();
      } : null,
      onPanEnd: widget.enabled ? (details) {
        setState(() {
          if (_currentStroke != null && _currentStroke!.isNotEmpty) {
            _strokes.add(_currentStroke!);
            _currentStroke = null;
          }
        });
        widget.onDrawingChanged?.call();
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: widget.borderColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ),
            if (widget.hintText != null && _strokes.isEmpty && _currentStroke == null)
              Center(
                child: Text(
                  widget.hintText!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  _CanvasPainter({
    required this.strokes,
    this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw all completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke (even if it has only one point, draw it as a dot)
    if (currentStroke != null && currentStroke!.isNotEmpty) {
      if (currentStroke!.length == 1) {
        // Draw a single point as a circle
        canvas.drawCircle(currentStroke![0], strokeWidth / 2, paint);
      } else {
        // Draw the path
        final path = Path();
        path.moveTo(currentStroke![0].dx, currentStroke![0].dy);
        for (int i = 1; i < currentStroke!.length; i++) {
          path.lineTo(currentStroke![i].dx, currentStroke![i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    // Always repaint if current stroke exists (is being drawn)
    if (currentStroke != null || oldDelegate.currentStroke != null) {
      return true;
    }
    return strokes.length != oldDelegate.strokes.length ||
        strokeColor != oldDelegate.strokeColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

