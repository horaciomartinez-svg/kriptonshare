import 'package:flutter/material.dart';

/// Vista Cercada (Fence View): enmascaramiento táctil de UI.
/// Fragmentación visual que inviabiliza la fotografía externa sistemática.
/// Solo revela el contenido donde el usuario toque/pase el dedo.
class FenceViewMask extends StatefulWidget {
  final Widget child; // El documento PDF o Imagen subyacente
  final double radius;

  const FenceViewMask({
    super.key,
    required this.child,
    this.radius = 120.0,
  });

  @override
  State<FenceViewMask> createState() => _FenceViewMaskState();
}

class _FenceViewMaskState extends State<FenceViewMask> {
  Offset _pointerPosition = const Offset(-1000, -1000); // Oculto por defecto

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _pointerPosition = details.localPosition;
        });
      },
      onPanEnd: (_) {
        setState(() {
          // Ocultar al soltar
          _pointerPosition = const Offset(-1000, -1000);
        });
      },
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return RadialGradient(
            center: Alignment(
              (_pointerPosition.dx / bounds.width) * 2 - 1,
              (_pointerPosition.dy / bounds.height) * 2 - 1,
            ),
            radius: (widget.radius / bounds.width) * 2,
            colors: const [Colors.transparent, Colors.black87],
            stops: const [0.5, 1.0], // Transición dura para el enmascaramiento
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcOver,
        child: widget.child,
      ),
    );
  }
}
