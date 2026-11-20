import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/membership_models.dart';

// ===========================================================================
// KOMPONEN UI BERSAMA untuk halaman Membership, CleanDrive Coins, dan Voucher Saya.
// Hanya berisi warna dan widget tampilan. TIDAK ada logika bisnis di sini.
//
// Aturan warna:
//  - Navy  : latar kartu utama, judul, ikon dekoratif.
//  - Gold  : aksen Coins / membership / reward.
//  - MERAH : SEMUA elemen yang bisa diklik (tombol, tab aktif, tautan, panah).
// ===========================================================================

const kRwNavy = Color(0xFF07347F);
const kRwNavyDark = Color(0xFF092D70);
const kRwNavyLight = Color(0xFF2457A5);
const kRwBg = Color(0xFFF1F5FC);
const kRwText = Color(0xFF102B59);
const kRwSub = Color(0xFF7183A5);
const kRwGold = Color(0xFFFFB91F);
const kRwGoldLight = Color(0xFFFFF0CC);
const kRwGoldDark = Color(0xFF8A5A00);
const kRwGreen = Color(0xFF19A66A);
const kRwDanger = Color(0xFFD91F2B);
const kRwBlueSoft = Color(0xFFE6EEFB);
const kRwLine = Color(0xFFE3EAF7);

/// Gradasi navy untuk kartu utama.
const kRwGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kRwNavy, kRwNavyLight],
);

const kRwShadow = [BoxShadow(color: Color(0x2607347F), blurRadius: 22, offset: Offset(0, 10))];
const kRwShadowThin = [BoxShadow(color: Color(0x1207347F), blurRadius: 14, offset: Offset(0, 5))];

/// Warna ikon tiap paket (di latar terang).
Color rwTierColor(MembershipTier t) => switch (t) {
      MembershipTier.bronze => const Color(0xFFB8772E),
      MembershipTier.silver => const Color(0xFF6F82A3),
      MembershipTier.gold => const Color(0xFFE5A100),
      MembershipTier.platinum => const Color(0xFF3F8AD9),
    };

/// Warna latar lingkaran ikon tiap paket.
Color rwTierSoft(MembershipTier t) => switch (t) {
      MembershipTier.bronze => const Color(0xFFFBE6CF),
      MembershipTier.silver => const Color(0xFFE3E8F0),
      MembershipTier.gold => const Color(0xFFFFEDB8),
      MembershipTier.platinum => const Color(0xFFDCEBFB),
    };

/// Warna nama paket di atas kartu navy.
Color rwTierOnDark(MembershipTier t) => switch (t) {
      MembershipTier.bronze => const Color(0xFFF0B27A),
      MembershipTier.silver => const Color(0xFFDDE4F0),
      MembershipTier.gold => kRwGold,
      MembershipTier.platinum => const Color(0xFFB4D6FF),
    };

/// Lingkaran ikon medali sesuai tingkatan paket.
class RwTierMedal extends StatelessWidget {
  final MembershipTier tier;
  final double size;
  const RwTierMedal(this.tier, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: rwTierSoft(tier), shape: BoxShape.circle),
        child: Icon(tier.icon, color: rwTierColor(tier), size: size * .52),
      );
}

/// Kartu putih: radius 20, bayangan tipis. Bila [onTap] diisi, kartu bisa diklik.
class RwCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  const RwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: borderColor == null ? null : Border.all(color: borderColor!, width: borderWidth),
          boxShadow: kRwShadowThin,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Kartu utama bergradasi navy dengan hiasan lingkaran halus.
class RwHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const RwHeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: kRwGradient,
          boxShadow: kRwShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [
            Positioned(
              right: -40,
              bottom: -60,
              child: IgnorePointer(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .05)),
                ),
              ),
            ),
            Positioned(
              right: 30,
              top: -70,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .04)),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ]),
        ),
      );
}

/// Judul bagian (navy, tebal).
class RwSectionTitle extends StatelessWidget {
  final String title;
  final double top;
  final Widget? trailing;
  const RwSectionTitle(this.title, {super.key, this.top = 24, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 12, left: 2),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kRwText))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Tombol utama MERAH (tinggi 54, radius 15). [outlined] = tombol sekunder bergaris merah.
class RwButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool outlined;
  final double height;
  const RwButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.outlined = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: outlined ? kRed : Colors.white),
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1)),
          ]);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kRed,
                backgroundColor: Colors.white,
                minimumSize: Size(0, height),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: kRed, width: 1.3),
                shape: shape,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onPressed: busy ? null : onPressed,
              child: content,
            )
          : FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                minimumSize: Size(0, height),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
              ),
              onPressed: busy ? null : onPressed,
              child: content,
            ),
    );
  }
}

/// Tombol kecil MERAH (mis. Klaim). Tinggi 38, radius 12.
class RwSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const RwSmallButton(this.label, {super.key, this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: kRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(68, 38),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      );
}

/// Kotak kecil berisi ikon (navy, dekoratif).
class RwIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color bg, fg;
  final bool circle;
  const RwIconBox(
    this.icon, {
    super.key,
    this.size = 38,
    this.bg = kRwBlueSoft,
    this.fg = kRwNavy,
    this.circle = true,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(size * .3),
        ),
        child: Icon(icon, color: fg, size: size * .52),
      );
}

/// Pil kecil berwarna (badge status).
class RwPill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  final IconData? icon;
  const RwPill(this.text, {super.key, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11.5)),
        ]),
      );
}


// ===========================================================================
// KOMPONEN TAMBAHAN UNTUK ALUR PEMBAYARAN (konfirmasi, metode, bayar, berhasil, detail).
// Hanya tampilan, tanpa logika bisnis.
// ===========================================================================

/// Baris label-nilai: label abu-biru di kiri, nilai tebal rata kanan.
/// [onDark] = dipakai di atas kartu navy (teks putih).
Widget rwKv(String k, String v, {bool bold = false, Color? valueColor, bool onDark = false, double vPad = 5}) => Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: Text(k, style: TextStyle(color: onDark ? Colors.white.withValues(alpha: .82) : kRwSub, fontSize: 13.5, height: 1.3)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              height: 1.3,
              color: valueColor ?? (onDark ? Colors.white : kRwText),
            ),
          ),
        ),
      ]),
    );

/// Judul di dalam kartu putih (mis. "Detail Pesanan").
Widget rwCardTitle(String t, {double bottom = 8}) => Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(t, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kRwText)),
    );

/// Garis pemisah tipis di dalam kartu.
Widget rwDivider({double v = 10}) => Padding(
      padding: EdgeInsets.symmetric(vertical: v),
      child: const Divider(height: 1, thickness: 1, color: kRwLine),
    );

/// Koin emas kecil (ikon Coins).
class RwCoin extends StatelessWidget {
  final double size;
  const RwCoin({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFD25E), kRwGold]),
          border: Border.all(color: const Color(0xFFFFE9A8), width: size * .06),
          boxShadow: const [BoxShadow(color: Color(0x33FFB91F), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Icon(Icons.attach_money_rounded, color: Colors.white, size: size * .62),
      );
}

/// Lingkaran centang hijau (status berhasil).
class RwCheckCircle extends StatelessWidget {
  final double size;
  const RwCheckCircle({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kRwGreen,
          border: Border.all(color: Colors.white.withValues(alpha: .22), width: size * .07),
          boxShadow: const [BoxShadow(color: Color(0x4019A66A), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: size * .62),
      );
}