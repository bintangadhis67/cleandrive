import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/hero_car.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../orders/orders.dart';
import '../outlet/outlet.dart';
import '../profile/profile_widgets.dart' show kProNavy, kProRoyal, kProGold;
import '../rewards/voucher.dart';
import '../shop/shop.dart' show ProductImage;
import 'desktop_shell.dart' show kWidePad;

// ===========================================================================
// WIDGET REUSABLE BERANDA (redesign).
// Dipakai oleh BerandaTab di beranda_tab.dart.
// ===========================================================================

const _kShadow = [BoxShadow(color: Color(0x1A08265C), blurRadius: 22, offset: Offset(0, 8))];

// ---------------------------------------------------------------------------
// HERO: sapaan + notifikasi + pengaturan + banner "Drive Cleaner, Go Further."
// ---------------------------------------------------------------------------
class HomeHero extends StatelessWidget {
  final VoidCallback onBooking, onAvatar, onNotif, onSettings;

  /// true = layar lebar (laptop/desktop): hero berbentuk kartu bulat dengan margin, teks dan mobil lebih besar.
  final bool wide;
  const HomeHero({
    super.key,
    required this.onBooking,
    required this.onAvatar,
    required this.onNotif,
    required this.onSettings,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = wide ? 4.0 : MediaQuery.paddingOf(context).top;
    final name = (app.user ?? '').trim();
    final first = name.isEmpty ? 'Pengguna' : name.split(' ').first;
    final unread = app.unreadCount;
    final radius = wide ? BorderRadius.circular(32) : const BorderRadius.vertical(bottom: Radius.circular(30));

    return Container(
      margin: wide ? const EdgeInsets.fromLTRB(kWidePad, 24, kWidePad, 0) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kProNavy, Color(0xFF0B3380), kProRoyal],
        ),
        boxShadow: const [BoxShadow(color: Color(0x4008265C), blurRadius: 26, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.8, -.6),
                  radius: 1.1,
                  colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          // mobil + percikan air: sama seperti header Booking (besar, memenuhi tinggi header, tepi menyatu)
          const Positioned.fill(child: HeroCarBackdrop()),
          Padding(
            padding: wide ? const EdgeInsets.fromLTRB(26, 22, 20, 30) : EdgeInsets.fromLTRB(16, top + 10, 12, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ---- sapaan ----
              Row(children: [
                GestureDetector(
                  onTap: onAvatar,
                  // logo aplikasi CleanDrive (menggantikan lingkaran inisial)
                  child: SizedBox(
                    width: wide ? 54 : 46,
                    height: wide ? 54 : 46,
                    child: Image.asset('assets/images/profile_logo_mark.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Halo, $first!',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: wide ? 24 : 20, fontWeight: FontWeight.w800)),
                    Text(
                        app.isNewUser
                            ? 'Selamat datang di CleanDrive! 🎉 Yuk klaim bonus Coins dan booking cuci pertamamu.'
                            : 'Selamat datang kembali 👋 Kendaraanmu siap kinclong lagi, yuk booking cuci hari ini!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: wide ? 14 : 12.5, height: 1.25)),
                  ]),
                ),
                IconButton(
                  tooltip: 'Notifikasi',
                  onPressed: onNotif,
                  icon: Stack(clipBehavior: Clip.none, children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 29),
                    if (unread > 0)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFE72F3B), borderRadius: BorderRadius.circular(10)),
                          child: Text(unread > 9 ? '9+' : '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
                ),
                IconButton(
                  tooltip: 'Pengaturan',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                ),
              ]),
              SizedBox(height: wide ? 30 : 18),
              // ---- banner ----
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: wide ? 'Drive Cleaner,\nGo ' : 'Drive\nCleaner,\nGo '),
                  const TextSpan(text: 'Further.', style: TextStyle(color: kProGold)),
                ]),
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: wide ? 40 : 23, fontWeight: FontWeight.w800, height: 1.2),
              ),
              SizedBox(height: wide ? 22 : 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, wide ? 54 : 46),
                  padding: EdgeInsets.symmetric(horizontal: wide ? 26 : 18),
                  shape: const StadiumBorder(),
                  textStyle: TextStyle(fontSize: wide ? 16 : 14.5, fontWeight: FontWeight.w800),
                ),
                onPressed: onBooking,
                icon: const Icon(Icons.event_available_rounded, size: 21),
                label: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Booking Sekarang'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// JUDUL SECTION (garis biru + judul + tombol "Lihat Semua")
// ---------------------------------------------------------------------------
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const HomeSectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 0, 12),
        child: Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: kProRoyal, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kProNavy)),
          ),
          if (onAction != null)
            Material(
              color: kRed.withValues(alpha: .10),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(actionLabel ?? 'Lihat Semua',
                        style: const TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const Icon(Icons.chevron_right_rounded, color: kRed, size: 18),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// AKSES CEPAT: Booking, Riwayat, Voucher, Toko, Ganti Oli
// ---------------------------------------------------------------------------
class QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const QuickItem(this.icon, this.label, this.color, this.onTap);
}

class HomeQuickAccess extends StatelessWidget {
  final List<QuickItem> items;

  /// true = layar lebar: tiap tombol berbentuk kartu horizontal (ikon di kiri, label di kanan).
  final bool wide;
  const HomeQuickAccess({super.key, required this.items, this.wide = false});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _tile(items[i])),
          ],
        ]),
      );

  Widget _tile(QuickItem it) => Pressable(
      scale: 0.94,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kLineSoft),
          boxShadow: _kShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: it.onTap,
            child: Padding(
              padding: wide ? const EdgeInsets.symmetric(vertical: 16, horizontal: 16) : const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              child: wide
                  ? Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: it.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
                        child: Icon(it.icon, color: it.color, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(it.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kProNavy)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: kRed),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: it.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
                        child: Icon(it.icon, color: it.color, size: 24),
                      ),
                      const SizedBox(height: 7),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(it.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kProNavy)),
                      ),
                    ]),
            ),
          ),
        ),
      ));
}

// ---------------------------------------------------------------------------
// FITUR BARU: strip voucher (siap diklaim / siap dipakai)
// ---------------------------------------------------------------------------
class VoucherPromoStrip extends StatelessWidget {
  const VoucherPromoStrip({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _buildStrip(context));

  Widget _buildStrip(BuildContext context) {
    final v = app.claimable;
    final mine = app.usableVouchers;
    if (v == null && mine.isEmpty) return const SizedBox.shrink();

    final String title = v != null ? 'Voucher ${v.shortValue} siap diklaim' : '${mine.length} voucher siap dipakai';
    final String sub = v != null ? 'Klaim sekarang sebelum kehabisan' : 'Pakai saat pembayaran pesananmu';
    final String cta = v != null ? 'Klaim' : 'Lihat';

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFFFFE9A8), Color(0xFFFFD25E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: const [BoxShadow(color: Color(0x33FFBE27), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => v != null ? VoucherClaimScreen(voucher: v) : const MyVouchersScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: kProNavy, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.local_offer_rounded, color: kProGold, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: kProNavy, fontSize: 14)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B5410), fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(18)),
                  child: Text(cta, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOKASI OUTLET TERDEKAT
// ---------------------------------------------------------------------------
class OutletNearbyCard extends StatelessWidget {
  const OutletNearbyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final open = kOutlet.isOpenNow;
    final tone = open ? kGreen : kError;
    return Panel(
      padding: const EdgeInsets.all(12),
      onTap: () => openOutlet(context),
      child: Row(children: [
        const SizedBox(width: 92, child: OutletMap(height: 92, radius: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kOutlet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kProNavy)),
            const SizedBox(height: 2),
            Text(kOutlet.shortAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kProRoyal, fontSize: 12.5)),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: tone.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                child: Text(open ? 'Buka' : 'Tutup', style: TextStyle(color: tone, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.schedule_rounded, size: 15, color: kProRoyal),
              const SizedBox(width: 4),
              Flexible(
                child: Text(kOutlet.hoursLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kProRoyal, fontSize: 12)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// FITUR BARU: pengingat perawatan (muncul bila cuci terakhir >= 14 hari lalu)
// ---------------------------------------------------------------------------
class CareReminderCard extends StatelessWidget {
  final VoidCallback onBooking;
  const CareReminderCard({super.key, required this.onBooking});

  @override
  Widget build(BuildContext context) {
    final hasActive = app.bookings.any((b) => b.active && !b.pack.isShop);
    if (hasActive) return const SizedBox.shrink();
    final done = app.bookings.where((b) => !b.pack.isShop && !b.cancelled && b.status == 3).toList()
      ..sort((a, b) => b.slot.compareTo(a.slot));
    if (done.isEmpty) return const SizedBox.shrink();
    final days = DateTime.now().difference(done.first.slot).inDays;
    if (days < 14) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Panel(
        onTap: onBooking,
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: kWarn.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.schedule_rounded, color: kWarn, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Saatnya cuci kendaraanmu', style: TextStyle(fontWeight: FontWeight.w800, color: kProNavy)),
              Text('Perawatan terakhir $days hari lalu. Booking sekarang agar tetap kinclong.',
                  style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.3)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: kProNavy),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PESANAN AKTIF
// ---------------------------------------------------------------------------
class ActiveOrderCard extends StatelessWidget {
  final Booking b;
  const ActiveOrderCard(this.b, {super.key});

  static String eta(Booking b) {
    if (b.pack.isShop) return 'Menunggu pembayaran';
    final m = b.estFinish.difference(DateTime.now()).inMinutes;
    if (m <= 0) return 'Estimasi selesai: segera';
    if (m >= 60) return 'Estimasi selesai: ${m ~/ 60} jam ${m % 60} menit lagi';
    return 'Estimasi selesai: $m menit lagi';
  }

  @override
  Widget build(BuildContext context) => Panel(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _ActiveThumb(b, width: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.code, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: kProNavy)),
                Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ]),
            ),
            const SizedBox(width: 6),
            StatusChip(b),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (b.status + 1) / 4,
              minHeight: 8,
              color: kProRoyal,
              backgroundColor: kProRoyal.withValues(alpha: .12),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: kProRoyal),
            const SizedBox(width: 6),
            Expanded(child: Text(eta(b), style: const TextStyle(fontSize: 12.5, color: kProRoyal, fontWeight: FontWeight.w600))),
            PayChip(b),
          ]),
        ]),
      );
}

// ---------------------------------------------------------------------------
// GAMBAR PESANAN AKTIF
// Pembelian Toko memakai foto produk yang dibeli (sama seperti kartu di tab Riwayat),
// badge "+N" muncul bila ada lebih dari satu jenis produk.
// Layanan cuci / ganti oli tetap memakai gambar layanan seperti sebelumnya.
// ---------------------------------------------------------------------------
class _ActiveThumb extends StatelessWidget {
  final Booking b;
  final double width;
  const _ActiveThumb(this.b, {required this.width});

  @override
  Widget build(BuildContext context) {
    if (!(b.pack.isShop && b.items.isNotEmpty)) return ServiceThumb(b.pack, b.vehicle, width: width);
    final h = width * .6;
    final first = b.items.first.product;
    final more = b.items.length - 1;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Container(
          width: width,
          height: h,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: kProRoyal.withValues(alpha: .07), borderRadius: BorderRadius.circular(14)),
          child: Center(child: ProductImage(first, height: h - 8)),
        ),
        if (more > 0)
          Positioned(
            right: 3,
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: kProNavy, borderRadius: BorderRadius.circular(10)),
              child: Text('+$more', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }
}