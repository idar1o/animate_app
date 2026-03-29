import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ShaderAnimation extends StatefulWidget {
  @override
  _ShaderAnimationState createState() => _ShaderAnimationState();
}

class _ShaderAnimationState extends State<ShaderAnimation>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  FragmentShader? shader;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1000),
    )..repeat();

    load();
  }

  Future<void> load() async {
    final program =
    await FragmentProgram.fromAsset('shaders/plasma.frag');

    shader = program.fragmentShader();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (shader == null) {
      return SizedBox();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: ShaderPainter(
            shader!,
            controller.value * 10,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;

  ShaderPainter(this.shader, this.time);

  @override
  void paint(Canvas canvas, Size size) {

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) => true;
}

class LiquidGlassPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final ui.Image bgImage;
  final Offset mousePos;
  final Offset cardOffset;   // глобальная позиция карточки на экране
  final Size screenSize;     // размер экрана

  LiquidGlassPainter({
    required this.shader,
    required this.time,
    required this.bgImage,
    required this.cardOffset,
    required this.screenSize,
    this.mousePos = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);       // uCardSize.x
    shader.setFloat(1, size.height);      // uCardSize.y
    shader.setFloat(2, time);             // uTime
    shader.setFloat(3, mousePos.dx);      // uMouse.x
    shader.setFloat(4, mousePos.dy);      // uMouse.y
    shader.setFloat(5, cardOffset.dx);    // uCardOffset.x
    shader.setFloat(6, cardOffset.dy);    // uCardOffset.y
    shader.setFloat(7, screenSize.width); // uScreenSize.x
    shader.setFloat(8, screenSize.height);// uScreenSize.y

    shader.setImageSampler(0, bgImage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter old) => true;
}