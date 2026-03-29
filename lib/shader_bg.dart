import 'dart:ui';

import 'package:animate_app/shader_animation.dart';
import 'package:flutter/material.dart';

class ShaderBackground extends StatelessWidget {
  final FragmentShader shader;
  final double time;

  const ShaderBackground({
    required this.shader,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ShaderPainter(shader, time),
      size: Size.infinite,
    );
  }
}