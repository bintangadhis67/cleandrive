import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/loyalty_models.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../notifications/notifications.dart';
import '../orders/orders.dart';
import '../outlet/outlet.dart';
import '../profile/profile_widgets.dart';
import '../profile/settings.dart';
import '../rewards/voucher.dart';
import '../shop/shop.dart';
import 'beranda_widgets.dart';
import 'customer.dart' show GoFn;

// ===========================================================================
// BERANDA (tab ke-1 di HomeScreen).
// Dipanggil dari customer.dart:  BerandaTab(onGo: _go)
// Semua fitur lama dipertahankan: sapaan, notifikasi, booking, coins + check-in,
// membership, akses cepat (Booking/Riwayat/Voucher/Ganti Oli), outlet,
// ajakan ulasan, pesanan aktif, dan etalase Toko.
// Fitur baru: strip voucher, tombol Toko di akses cepat, pengingat perawatan,
// estimasi waktu selesai pesanan, dan status Buka/Tutup outlet.
// ===========================================================================
class BerandaTab extends StatelessWidget {
  final GoFn onGo;
  const BerandaTab({super.key, required this.onGo});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _refresh() async {
    try {
      await app.refreshAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // ikon status bar putih karena hero berwarna gelap
        value: SystemUiOverlayStyle.light,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final pad = pagePad(MediaQuery.sizeOf(context).width);
            final active = app.bookings.where((b) => b.active).toList()..sort((a, b) => a.slot.compareTo(b.slot));
            final toReview =
                app.bookings.where((b) => b.status == 3 && !b.cancelled && !b.pack.isShop && b.review == null).firstOrNull;

            return RefreshIndicator(
              color: kRed,
              edgeOffset: MediaQuery.paddingOf(context).top,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  HomeHero(
                    onBooking: () => onGo(2),
                    onAvatar: () => onGo(4),
                    onNotif: () => _push(context, const NotificationScreen()),
                    onSettings: () => _push(context, const SettingsScreen()),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      // ---- Coins + Membership ----
                      const IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(child: ProfileCoinsCard()),
                          SizedBox(width: 12),
                          Expanded(child: ProfileMembershipCard()),
                        ]),
                      ),

                      // ---- Akses Cepat ----
                      const HomeSectionTitle('Akses Cepat'),
                      HomeQuickAccess(items: [
                        QuickItem(Icons.event_available_rounded, 'Booking', kRed, () => onGo(2)),
                        QuickItem(Icons.history_rounded, 'Riwayat', kRed, () => onGo(1)),
                        QuickItem(Icons.local_offer_rounded, 'Voucher', kRed, () => _push(context, const MyVouchersScreen())),
                        QuickItem(Icons.storefront_rounded, 'Toko', kRed, () => onGo(3)),
                        QuickItem(Icons.opacity_rounded, 'Ganti Oli', kRed, () => onGo(2, pack: oilChangePackage)),
                      ]),
                      const VoucherPromoStrip(),

                      // ---- Lokasi Outlet Terdekat ----
                      HomeSectionTitle('Lokasi Outlet Terdekat', onAction: () => openOutlet(context)),
                      const OutletNearbyCard(),

                      // ---- Ajakan ulasan (fitur lama) ----
                      if (toReview != null) ...[
                        const SizedBox(height: 14),
                        Panel(
                          onTap: () => _push(context, ReviewScreen(bookingId: toReview.id)),
                          child: Row(children: [
                            const Icon(Icons.star_rounded, color: kGold, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Bagaimana hasil layanannya?', style: TextStyle(fontWeight: FontWeight.w800, color: kProNavy)),
                                Text('${toReview.label}. Beri ulasan dan dapat +$kReviewCoins Coins.',
                                    style: const TextStyle(fontSize: 12.5, color: kMuted)),
                              ]),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: kRed),
                          ]),
                        ),
                      ],

                      // ---- Pengingat perawatan (baru) ----
                      CareReminderCard(onBooking: () => onGo(2)),

                      // ---- Pesanan Aktif ----
                      HomeSectionTitle('Pesanan Aktif', onAction: () => onGo(1)),
                      if (active.isEmpty)
                        Panel(
                          child: Row(children: [
                            const Icon(Icons.local_car_wash_outlined, size: 32, color: kMuted),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Belum ada pesanan aktif.', style: TextStyle(color: kMuted))),
                            TextButton(onPressed: () => onGo(2), child: const Text('Booking')),
                          ]),
                        )
                      else
                        for (final b in active.take(3))
                          Padding(padding: const EdgeInsets.only(bottom: 10), child: ActiveOrderCard(b)),

                      // ---- Toko (fitur lama) ----
                      const SizedBox(height: 8),
                      ShopHomeSection(onSeeAll: () => onGo(3)),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      );
}