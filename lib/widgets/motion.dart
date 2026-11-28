import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

// ===========================================================================
// MOTION: kumpulan animasi CleanDrive (hanya memakai bawaan Flutter).
//   1. Pressable                    efek menyusut saat ditekan (tombol, kartu, menu)
//   2. FadeSlideIn                  muncul memudar sambil naik (masuk bertahap)
//   3. SuccessBurst                 centang animasi + gelombang + konfeti (voucher, pembayaran)
//   4. ShineLogo                    logo muncul membesar + kilau berjalan (splash)
//   5. FloatingBubbles              gelembung sabun naik pelan (latar splash)
//   6. SlideFadePageTransitionsBuilder  transisi pindah halaman (geser + pudar)
//   7. SwipeSwitcher                isi berganti dengan geser sesuai arah (filter, kategori, mode)
//   8. Pop                          denyut membesar sebentar saat nilai berubah (badge, jumlah)
// ===========================================================================

// ---------------------------------------------------------------------------
// 1. PRESSABLE: efek tekan
// ---------------------------------------------------------------------------
/// Membungkus widget apa pun: saat disentuh ia sedikit mengecil, lalu melenting kembali.
/// Memakai [Listener], jadi TIDAK mengganggu onTap / InkWell di dalamnya.
/// Bila jari mulai menggeser (scroll), efeknya dibatalkan supaya daftar tetap nyaman digulir.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Timer? _timer;
  Offset _start = Offset.zero;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  void _onDown(PointerDownEvent e) {
    if (!widget.enabled) return;
    _start = e.position;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 40), () => _set(true));
  }

  void _onMove(PointerMoveEvent e) {
    if ((e.position - _start).distance > 10) {
      _timer?.cancel();
      _set(false);
    }
  }

  void _end() {
    _timer?.cancel();
    _set(false);
  }

  void _onUp(PointerUpEvent e) => _end();
  void _onCancel(PointerCancelEvent e) => _end();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1.0,
          duration: Duration(milliseconds: _down ? 90 : 220),
          curve: _down ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      );
}

// ---------------------------------------------------------------------------
// 2. FADE SLIDE IN: masuk bertahap
// ---------------------------------------------------------------------------
/// Kunci yang sudah pernah dimainkan oleh [FadeSlideIn.playOnce].
final Set<Object> _fadeSlidePlayed = <Object>{};

/// Memunculkan [child] dengan memudar sambil bergeser sedikit. Atur [delay] untuk membuat urutan
/// (mis. 0 ms, 150 ms, 300 ms). Dimainkan sekali saat widget pertama kali tampil.
///
/// - [dy]: geser vertikal awal (positif = dari bawah). [dx]: geser horizontal awal (positif = dari kanan).
/// - [playOnce]: untuk item di dalam daftar yang bisa dibangun ulang saat digulir. Bila kunci yang sama
///   sudah pernah dimainkan, item langsung tampil tanpa animasi (jadi tidak berulang tiap digulir).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;
  final double dx;
  final Object? playOnce;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.dy = 18,
    this.dx = 0,
    this.playOnce,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  late final bool _skip;

  @override
  void initState() {
    super.initState();
    final k = widget.playOnce;
    if (k == null) {
      _skip = false;
    } else {
      if (_fadeSlidePlayed.length > 3000) _fadeSlidePlayed.clear();
      _skip = !_fadeSlidePlayed.add(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_skip) return widget.child;
    final total = widget.delay + widget.duration;
    final start = widget.delay.inMilliseconds / total.inMilliseconds;
    final curve = Interval(start, 1.0, curve: Curves.easeOutCubic);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      child: widget.child,
      builder: (context, t, c) {
        final v = curve.transform(t);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset((1 - v) * widget.dx, (1 - v) * widget.dy), child: c),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 3. SUCCESS BURST: centang + gelombang + konfeti
// ---------------------------------------------------------------------------
class _Particle {
  final double angle, dist, size, rot, spin;
  final Color color;
  final bool round;
  const _Particle(this.angle, this.dist, this.size, this.rot, this.spin, this.color, this.round);
}

/// Lingkaran hijau yang membesar dengan efek lenting, centangnya tergambar perlahan, lalu
/// gelombang dan konfeti memancar keluar. Dimainkan otomatis saat widget pertama kali tampil.
class SuccessBurst extends StatefulWidget {
  final double size;
  final Color color;
  final bool confetti;
  const SuccessBurst({super.key, this.size = 96, this.color = const Color(0xFF19A66A), this.confetti = true});

  @override
  State<SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<SuccessBurst> with SingleTickerProviderStateMixin {
  static const _palette = [
    Color(0xFFFFB91F),
    Color(0xFF19A66A),
    Color(0xFF6FE0A6),
    Color(0xFFFF6B73),
    Color(0xFF4F8CFF),
    Color(0xFFFFFFFF),
  ];

  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    unawaited(HapticFeedback.lightImpact());
    final rnd = math.Random(11);
    const n = 22;
    _particles = [
      for (var i = 0; i < n; i++)
        _Particle(
          i * (2 * math.pi / n) + rnd.nextDouble() * .25,
          widget.size * (.85 + rnd.nextDouble() * .75),
          5 + rnd.nextDouble() * 5,
          rnd.nextDouble() * math.pi,
          (rnd.nextDouble() - .5) * 8,
          _palette[i % _palette.length],
          rnd.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _iv(double a, double b, Curve curve) => Interval(a, b, curve: curve).transform(_c.value);

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final badge = _iv(0.0, 0.45, Curves.elasticOut);
          final check = _iv(0.25, 0.6, Curves.easeOut);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _BurstPainter(
                  base: s,
                  color: widget.color,
                  ring1: _iv(0.15, 0.85, Curves.easeOut),
                  ring2: _iv(0.3, 1.0, Curves.easeOut),
                  confetti: widget.confetti ? _iv(0.2, 1.0, Curves.linear) : 0,
                  particles: _particles,
                ),
              ),
              Transform.scale(
                scale: badge,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    border: Border.all(color: Colors.white.withValues(alpha: .22), width: s * .07),
                    boxShadow: [BoxShadow(color: widget.color.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: CustomPaint(painter: _CheckPainter(progress: check, stroke: s * .075)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final double stroke;
  const _CheckPainter({required this.progress, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * .27, size.height * .52)
      ..lineTo(size.width * .43, size.height * .68)
      ..lineTo(size.width * .74, size.height * .34);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

class _BurstPainter extends CustomPainter {
  final double base;
  final Color color;
  final double ring1, ring2, confetti;
  final List<_Particle> particles;
  const _BurstPainter({
    required this.base,
    required this.color,
    required this.ring1,
    required this.ring2,
    required this.confetti,
    required this.particles,
  });

  // Titik (0, 0) = pusat lingkaran centang.
  void _ring(Canvas canvas, double p) {
    if (p <= 0 || p >= 1) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: (1 - p) * .45);
    canvas.drawCircle(Offset.zero, base * .5 * (1 + p * .9), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ring(canvas, ring1);
    _ring(canvas, ring2);
    if (confetti <= 0 || confetti >= 1) return;
    final e = Curves.easeOutCubic.transform(confetti);
    final alpha = confetti < .65 ? 1.0 : (1 - (confetti - .65) / .35);
    for (final p in particles) {
      final dx = math.cos(p.angle) * p.dist * e;
      final dy = math.sin(p.angle) * p.dist * e + base * .35 * confetti * confetti;
      final paint = Paint()..color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble());
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rot + confetti * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .55), const Radius.circular(1.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.ring1 != ring1 || old.ring2 != ring2 || old.confetti != confetti;
}

// ---------------------------------------------------------------------------
// 4. SHINE LOGO: logo muncul + kilau berjalan
// ---------------------------------------------------------------------------
class _SlideGradientTransform extends GradientTransform {
  final double slide;
  const _SlideGradientTransform(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Logo muncul dengan membesar + memudar, setelah itu kilau putih menyapu logo berulang kali.
/// Kilau hanya tampak pada bagian logo yang tidak transparan.
class ShineLogo extends StatefulWidget {
  final Widget child;
  const ShineLogo({super.key, required this.child});

  @override
  State<ShineLogo> createState() => _ShineLogoState();
}

class _ShineLogoState extends State<ShineLogo> with TickerProviderStateMixin {
  late final AnimationController _in;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _in.forward().whenComplete(() {
      if (mounted) _shine.repeat();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shined = AnimatedBuilder(
      animation: _shine,
      child: widget.child,
      builder: (context, c) {
        final t = Curves.easeInOut.transform((_shine.value / .55).clamp(0.0, 1.0).toDouble());
        final slide = -1.2 + 2.4 * t;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: const Alignment(-1, -.4),
            end: const Alignment(1, .4),
            colors: const [Color(0x00FFFFFF), Color(0xAAFFFFFF), Color(0x00FFFFFF)],
            stops: const [.4, .5, .6],
            transform: _SlideGradientTransform(slide),
          ).createShader(bounds),
          child: c,
        );
      },
    );
    return AnimatedBuilder(
      animation: _in,
      child: shined,
      builder: (context, c) {
        final fade = const Interval(0.0, .6, curve: Curves.easeOut).transform(_in.value);
        final grow = Curves.easeOutBack.transform(_in.value);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, (1 - _in.value) * 14),
            child: Transform.scale(scale: .8 + .2 * grow, child: c),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 5. FLOATING BUBBLES: gelembung sabun naik pelan
// ---------------------------------------------------------------------------
class _Bubble {
  final double x, r, offset, alpha, wobble;
  final int loops;
  const _Bubble(this.x, this.r, this.offset, this.alpha, this.wobble, this.loops);
}

/// Latar berisi gelembung yang naik pelan. Letakkan di belakang isi (mis. di Stack, Positioned.fill).
class FloatingBubbles extends StatefulWidget {
  final int count;
  final Color color;
  const FloatingBubbles({super.key, this.count = 16, this.color = Colors.white});

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    final rnd = math.Random(5);
    _bubbles = [
      for (var i = 0; i < widget.count; i++)
        _Bubble(
          rnd.nextDouble(),
          4 + rnd.nextDouble() * 12,
          rnd.nextDouble(),
          .10 + rnd.nextDouble() * .20,
          1 + rnd.nextDouble() * 2,
          1 + rnd.nextInt(2),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BubblePainter(_c.value, _bubbles, widget.color),
          ),
        ),
      );
}

class _BubblePainter extends CustomPainter {
  final double t;
  final List<_Bubble> bubbles;
  final Color color;
  const _BubblePainter(this.t, this.bubbles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final phase = (t * b.loops + b.offset) % 1.0;
      final x = b.x * size.width + math.sin(phase * 2 * math.pi * b.wobble) * 14;
      final y = size.height * (1 - phase);
      final a = math.sin(phase * math.pi) * b.alpha;
      canvas.drawCircle(Offset(x, y), b.r, Paint()..color = color.withValues(alpha: a * .35));
      canvas.drawCircle(
        Offset(x, y),
        b.r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// 7. SWIPE SWITCHER: isi berganti dengan geser sesuai arah
// ---------------------------------------------------------------------------
/// Mengganti isi saat [index] berubah. Isi baru masuk dari kanan bila index naik (dari kiri bila turun),
/// isi lama keluar ke arah berlawanan sambil memudar. Cocok untuk filter/kategori/mode berurutan.
/// Isi yang keluar tidak bisa disentuh selama transisi. Letakkan di tempat yang tingginya jelas
/// (mis. di dalam Expanded) atau di dalam kolom/daftar biasa.
class SwipeSwitcher extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  const SwipeSwitcher({super.key, required this.index, required this.child, this.duration = const Duration(milliseconds: 320)});

  @override
  State<SwipeSwitcher> createState() => _SwipeSwitcherState();
}

class _SwipeSwitcherState extends State<SwipeSwitcher> {
  int _dir = 1;

  @override
  void didUpdateWidget(covariant SwipeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _dir = widget.index > oldWidget.index ? 1 : -1;
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: widget.duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, anim) {
          final incoming = child.key == ValueKey<int>(widget.index);
          final dx = (incoming ? .10 : -.10) * _dir;
          return IgnorePointer(
            ignoring: !incoming,
            child: FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey<int>(widget.index), child: widget.child),
      );
}

// ---------------------------------------------------------------------------
// 8. POP: denyut saat nilai berubah
// ---------------------------------------------------------------------------
/// Membesar sebentar lalu mengendap kembali setiap kali [trigger] berubah (dan [enabled] true).
/// Contoh: angka badge keranjang, harga total, pil filter yang baru dipilih.
/// [playOnInit] true = juga berdenyut saat pertama kali muncul (mis. badge yang baru muncul).
class Pop extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  final bool enabled;
  final bool playOnInit;
  final double amount;
  final Alignment alignment;
  const Pop({
    super.key,
    required this.trigger,
    required this.child,
    this.enabled = true,
    this.playOnInit = false,
    this.amount = 1.25,
    this.alignment = Alignment.center,
  });

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    if (widget.playOnInit) _c.forward();
  }

  @override
  void didUpdateWidget(covariant Pop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && oldWidget.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.amount;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, c) {
        final t = _c.value;
        final s = t < .3
            ? 1 + (a - 1) * Curves.easeOut.transform(t / .3)
            : 1 + (a - 1) * (1 - Curves.easeOutBack.transform((t - .3) / .7));
        return Transform.scale(scale: s, alignment: widget.alignment, child: c);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 6. TRANSISI PINDAH HALAMAN
// ---------------------------------------------------------------------------
/// Halaman baru masuk dengan bergeser dari kanan sedikit sambil memudar (lebih halus daripada
/// bawaan). Dipasang di theme.dart pada pageTransitionsTheme.
class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(.06, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
