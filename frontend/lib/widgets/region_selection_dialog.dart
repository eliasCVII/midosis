import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class RegionSelectionDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const RegionSelectionDialog({super.key, required this.imageBytes});

  @override
  State<RegionSelectionDialog> createState() => _RegionSelectionDialogState();
}

class _RegionSelectionDialogState extends State<RegionSelectionDialog> {
  Offset? _startPoint;
  Offset? _currentPoint;
  Size _containerSize = Size.zero;

  double _imageWidth = 0;
  double _imageHeight = 0;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(widget.imageBytes, (img) {
      completer.complete(img);
    });
    final image = await completer.future;
    if (mounted) {
      setState(() {
        _imageWidth = image.width.toDouble();
        _imageHeight = image.height.toDouble();
        _imageLoaded = true;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.localPosition;
      _currentPoint = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoint = details.localPosition;
    });
  }

  Rect? get _selectionRect {
    if (_startPoint == null || _currentPoint == null) return null;
    return Rect.fromPoints(_startPoint!, _currentPoint!);
  }

  Map<String, double>? _getCropBox() {
    final rect = _selectionRect;
    if (rect == null || !_imageLoaded || _imageWidth <= 0 || _imageHeight <= 0 || _containerSize == Size.zero) {
      return null;
    }

    final containerAspect = _containerSize.width / _containerSize.height;
    final imageAspect = _imageWidth / _imageHeight;

    double renderW, renderH, renderX, renderY;
    if (imageAspect > containerAspect) {
      renderW = _containerSize.width;
      renderH = _containerSize.width / imageAspect;
      renderX = 0;
      renderY = (_containerSize.height - renderH) / 2;
    } else {
      renderH = _containerSize.height;
      renderW = _containerSize.height * imageAspect;
      renderX = (_containerSize.width - renderW) / 2;
      renderY = 0;
    }

    final leftInImg = (rect.left - renderX).clamp(0.0, renderW);
    final topInImg = (rect.top - renderY).clamp(0.0, renderH);
    final rightInImg = (rect.right - renderX).clamp(0.0, renderW);
    final bottomInImg = (rect.bottom - renderY).clamp(0.0, renderH);

    final x = (leftInImg < rightInImg ? leftInImg : rightInImg) / renderW;
    final y = (topInImg < bottomInImg ? topInImg : bottomInImg) / renderH;
    final w = (rightInImg - leftInImg).abs() / renderW;
    final h = (bottomInImg - topInImg).abs() / renderH;

    if (w < 0.01 || h < 0.01) return null;

    return {
      'x': x,
      'y': y,
      'width': w,
      'height': h,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Encuadrar Medicamentos a Escanear',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dibuje un rectángulo sobre el área de los medicamentos.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.contain,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                          if (_selectionRect != null)
                            CustomPaint(
                              painter: _CropPainter(rect: _selectionRect!),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'CANCEL'),
                  child: const Text('Cancelar'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'FULL'),
                  child: const Text('Escanear Todo'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () {
                    final cropBox = _getCropBox();
                    Navigator.pop(context, cropBox ?? 'FULL');
                  },
                  child: const Text('Escanear Selección', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect rect;

  _CropPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
