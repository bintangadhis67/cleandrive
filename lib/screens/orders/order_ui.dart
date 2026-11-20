import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import '../../models/loyalty_models.dart';
import '../../models/models.dart';
import '../rewards/reward_ui.dart';

// ===========================================================================
// KOMPONEN UI untuk halaman "Beri Rating & Ulasan" dan "Detail Pesanan".
// File ini HANYA berisi tampilan. Tidak ada logika bisnis, API, atau database.
// Semua data (status, QR, rating, dsb.) dikirim dari orders.dart.
// ===========================================================================

/// Keterangan kepuasan berdasarkan jumlah bintang (1-5).
String satisfactionLabel(int r) =>
    const ['', 'Sangat Tidak Puas', 'Tidak Puas', 'Cukup Puas', 'Puas', 'Sangat Puas'][r.clamp(1, 5)];

// ---------------------------------------------------------------------------
// BINTANG RATING (hanya tampilan, warna gold)
// ---------------------------------------------------------------------------
class RatingStars extends StatelessWidget {
  final int rating;
  final double size;
  const RatingStars(this.rating, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size, color: i <= rating ? kRwGold : kRwGold.withValues(alpha: .35)),
      ]);
}

// ---------------------------------------------------------------------------
// HALAMAN BERI RATING & ULASAN
// ---------------------------------------------------------------------------

/// Kartu header navy gradasi: tombol kembali, judul, ucapan, 5 bintang interaktif, keterangan.
class ReviewHero extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRate;
  final VoidCallback onBack;
  const ReviewHero({super.key, required this.rating, required this.onRate, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyDark, kRwNavy, kRwNavyLight]),
        boxShadow: kRwShadow,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(children: [
          // hiasan lingkaran halus
          Positioned(
            right: -50,
            bottom: -70,
            child: IgnorePointer(
              child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .05))),
            ),
          ),
          Positioned(
            left: -40,
            top: -60,
            child: IgnorePointer(
              child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .04))),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 6, 12, 28),
            child: Column(children: [
              // Header: kembali (kiri), judul (tengah)
              SizedBox(
                height: 48,
                child: Row(children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('Beri Rating & Ulasan',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ),
                  const SizedBox(width: 48), // penyeimbang agar judul benar-benar di tengah
                ]),
              ),
              const SizedBox(height: 18),
              const Text('Terima kasih!',
                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.3)),
              const SizedBox(height: 8),
              Text('Bagaimana pengalamanmu\nmenggunakan layanan kami?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 14.5, height: 1.4)),
              const SizedBox(height: 20),
              // 5 bintang interaktif (fungsi pemilihan rating tetap sama)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 1; i <= 5; i++)
                    Semantics(
                      button: true,
                      selected: i == rating,
                      label: '$i bintang',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onRate(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          child: AnimatedScale(
                            scale: i == rating ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            child: Icon(
                              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 46,
                              color: i <= rating ? kRwGold : kRwGold.withValues(alpha: .5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey(rating),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
                  child: Text(satisfactionLabel(rating),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Dekorasi kolom ulasan: sudut membulat, border tipis, fokus navy.
InputDecoration reviewFieldDecoration() {
  OutlineInputBorder b(Color c, [double w = 1.2]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: 'Ceritakan pengalamanmu...',
    hintStyle: const TextStyle(color: kRwSub),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: b(kRwLine),
    enabledBorder: b(kRwLine),
    focusedBorder: b(kRwNavy, 1.6),
  );
}

/// Counter karakter "0/200" (dipakai di buildCounter TextField).
Widget reviewCounter(int current, int? max) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('$current/${max ?? 200}', style: const TextStyle(color: kRwSub, fontSize: 12.5, fontWeight: FontWeight.w600)),
    );

/// Info reward: ikon koin gold + keterangan. Nilai Coins diambil dari konstanta yang sudah ada.
class RewardInfoBar extends StatelessWidget {
  const RewardInfoBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: kRwBg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const RwCoin(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Dapat +$kReviewCoins Coins, +$kReviewCommentBonus bonus bila menulis ulasan.',
                style: const TextStyle(color: kRwText, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// HALAMAN DETAIL PESANAN
// ---------------------------------------------------------------------------

/// Badge status pesanan (kanan atas header). Warna sama dengan daftar riwayat.
class OrderStatusBadge extends StatelessWidget {
  final Booking b;
  const OrderStatusBadge(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = b.cancelled
        ? ('Dibatalkan', const Color(0xFFFDE3E5), kRwDanger)
        : switch (b.status) {
            0 => ('Menunggu', kRwGoldLight, kRwGoldDark),
            3 => ('Selesai', const Color(0xFFDDF3E8), const Color(0xFF148A57)),
            _ => ('Diproses', kRwBlueSoft, kRwNavy),
          };
    return RwPill(text, bg: bg, fg: fg);
  }
}

/// Progress horizontal 3 tahap: Booking, Proses, Selesai.
/// [stage]: 0 = Booking, 1 = Proses, 2 = Selesai (dihitung dari status pesanan asli).
/// Navy = sudah dilewati, merah = tahap aktif / terakhir, abu-abu = belum tercapai.
class OrderStepper extends StatelessWidget {
  final int stage;
  const OrderStepper({super.key, required this.stage});

  static const _names = ['Booking', 'Proses', 'Selesai'];
  static const _grey = Color(0xFFDDE4F1);

  Widget _dot(int i) {
    final done = i < stage, cur = i == stage;
    return SizedBox(
      width: 68,
      child: Column(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cur ? kRed : (done ? kRwNavy : _grey),
            boxShadow: cur ? const [BoxShadow(color: Color(0x44C62026), blurRadius: 10, offset: Offset(0, 4))] : null,
          ),
          child: (done || cur) ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        Text(_names[i],
            maxLines: 1,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cur ? kRed : (done ? kRwNavy : kRwSub))),
      ]),
    );
  }

  Widget _line(int i) {
    // garis antara tahap i dan i+1
    final BoxDecoration deco;
    if (i < stage - 1) {
      deco = BoxDecoration(color: kRwNavy, borderRadius: BorderRadius.circular(3));
    } else if (i == stage - 1) {
      deco = BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: const LinearGradient(colors: [kRwNavy, kRed], stops: [.45, 1]));
    } else {
      deco = BoxDecoration(color: _grey, borderRadius: BorderRadius.circular(3));
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 14.5),
        child: Container(height: 3, decoration: deco),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_dot(0), _line(0), _dot(1), _line(1), _dot(2)]);
}

/// Ilustrasi kendaraan di dalam cincin progres (cincin merah = progres status layanan).
class OrderStatusIllustration extends StatelessWidget {
  final Booking b;
  final double size;
  const OrderStatusIllustration(this.b, {super.key, this.size = 156});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (b.status + 1) / 4,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: kRed,
              backgroundColor: kRwBlueSoft,
            ),
          ),
          Container(
            width: size - 30,
            height: size - 30,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: kRwShadowThin),
            child: b.pack.isShop
                ? const Icon(Icons.shopping_bag_rounded, size: 52, color: kRwNavy)
                : Image.asset(b.pack.imageFor(b.vehicle), fit: BoxFit.contain, cacheWidth: 400),
          ),
        ]),
      );
}

/// Pil status saat ini (titik merah + nama status).
class OrderStatusPill extends StatelessWidget {
  final String label;
  const OrderStatusPill(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: kRwBlueSoft, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kRwText)),
        ]),
      );
}

/// Timeline vertikal: titik status, garis penghubung, nama tahap, dan waktunya.
/// Selesai = navy (centang), aktif = merah, berikutnya = abu-abu.
class OrderTimeline extends StatelessWidget {
  final int status; // status pesanan saat ini (0-3)
  final List<String> names; // nama tahap (4 item)
  final List<String> times; // waktu tiap tahap (4 item, sudah diformat)
  const OrderTimeline({super.key, required this.status, required this.names, required this.times});

  Widget _dot(int i) {
    if (i < status) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(color: kRwNavy, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }
    if (i == status) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: kRed, width: 2.2)),
        child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle))),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCBD5E8), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < 4; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 22,
                child: Column(children: [
                  _dot(i),
                  if (i < 3)
                    Expanded(
                      child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: i < status ? kRwNavy : kRwLine),
                    ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < 3 ? 18 : 0),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(names[i],
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: i == status ? FontWeight.w800 : FontWeight.w600,
                              color: i == status ? kRed : (i < status ? kRwText : kRwSub))),
                    ),
                    const SizedBox(width: 8),
                    Text(times[i],
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: i <= status ? kRwText : kRwSub)),
                  ]),
                ),
              ),
            ]),
          ),
      ]);
}

/// Kartu "Tiket Masuk": QR besar (data QR = b.code, dari sistem), nomor booking, petunjuk, badge verifikasi.
class OrderTicketCard extends StatelessWidget {
  final Booking b;
  const OrderTicketCard(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final ok = b.verified;
    return RwCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: SizedBox(
        width: double.infinity,
        child: Column(children: [
          Align(alignment: Alignment.centerLeft, child: rwCardTitle('Tiket Masuk', bottom: 14)),
          LayoutBuilder(builder: (context, c) {
            // QR besar tapi tidak pernah melebihi lebar kartu (tetap jelas dan bisa dipindai).
            final s = (c.maxWidth - 32).clamp(140.0, 210.0);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kRwLine, width: 1.2),
                boxShadow: kRwShadowThin,
              ),
              child: Opacity(
                opacity: b.cancelled ? .25 : 1,
                child: QrImageView(data: b.code, size: s, backgroundColor: Colors.white),
              ),
            );
          }),
          const SizedBox(height: 14),
          SelectableText(b.code,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1, color: kRwNavy)),
          const SizedBox(height: 4),
          Text(b.pack.isShop ? 'Tunjukkan QR ini ke kasir untuk mengambil pesanan' : 'Tunjukkan QR ini ke petugas saat tiba.',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: kRwSub, height: 1.3)),
          const SizedBox(height: 12),
          RwPill(
            ok ? 'Tiket Terverifikasi' : 'Belum diverifikasi petugas',
            bg: ok ? const Color(0xFFDDF3E8) : kRwGoldLight,
            fg: ok ? const Color(0xFF148A57) : kRwGoldDark,
            icon: ok ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
          ),
        ]),
      ),
    );
  }
}

/// Bar tombol tetap di bawah halaman (dipakai untuk "Cetak Bukti (PDF)").
class OrderBottomBar extends StatelessWidget {
  final Widget child;
  const OrderBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x1407347F), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: child),
        ),
      );
}