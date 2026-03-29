import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  FragmentShader? shader;
  ui.Image? bgImage;
  late Ticker ticker;
  double time = 0;

  @override
  void initState() {
    super.initState();
    _load();
    ticker = createTicker((elapsed) {
      setState(() => time = elapsed.inMilliseconds / 1000.0);
    });
    ticker.start();
  }

  Future<void> _load() async {
    final program = await FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    final data    = await rootBundle.load('assets/bg.jpg');
    final codec   = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame   = await codec.getNextFrame();
    setState(() {
      shader  = program.fragmentShader();
      bgImage = frame.image;
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (shader == null || bgImage == null) return const SizedBox();

    return Stack(
      children: [
        // Фон
        Positioned.fill(
          child: Image.asset('assets/bg.jpg', fit: BoxFit.cover),
        ),

        // Кнопка по центру
        Center(
          child: LiquidGlassButton(
            shader: shader!,
            bgImage: bgImage!,
            label: 'Tap me',
            onTap: () => debugPrint('tapped'),
          ),
        ),
      ],
    );
  }
}

// ─── Кнопка ──────────────────────────────────────────────────────────────────

class LiquidGlassButton extends StatefulWidget {
  final FragmentShader shader;
  final ui.Image bgImage;
  final String label;
  final VoidCallback? onTap;

  const LiquidGlassButton({
    super.key,
    required this.shader,
    required this.bgImage,
    required this.label,
    this.onTap,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  final _key = GlobalKey();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOffset());
  }

  void _updateOffset() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final o = box.localToGlobal(Offset.zero);
    if (o != _offset) setState(() => _offset = o);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const size   = Size(200, 60);

    return GestureDetector(
      onTap: widget.onTap,
      child: CustomPaint(
        key: _key,
        size: size,
        painter: _GlassPainter(
          shader:     widget.shader,
          bgImage:    widget.bgImage,
          offset:     _offset,
          screenSize: screen,
        ),
        child: SizedBox(
          width:  size.width,
          height: size.height,
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   18,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _GlassPainter extends CustomPainter {
  final FragmentShader shader;
  final ui.Image bgImage;
  final Offset offset;
  final Size screenSize;

  const _GlassPainter({
    required this.shader,
    required this.bgImage,
    required this.offset,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, offset.dx);
    shader.setFloat(3, offset.dy);
    shader.setFloat(4, screenSize.width);
    shader.setFloat(5, screenSize.height);
    shader.setImageSampler(0, bgImage);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.offset != offset || old.bgImage != bgImage;
}