import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/notification_models.dart';
import '../../widgets/nav_header.dart';
import '../../widgets/widgets.dart';
import '../orders/orders.dart';
import '../rewards/loyalty.dart';
import '../rewards/membership.dart';
import '../rewards/reward_ui.dart';
import '../rewards/voucher.dart';
import '../shop/shop.dart';

/// Membuka layar tujuan sebuah notifikasi dan menandainya sudah dibaca.
void openNotification(BuildContext context, AppNotification n) {
  app.markRead(n);
  final t = n.target ?? '';
  final Widget? page = t.startsWith('order:')
      ? DetailScreen(id: t.substring(6))
      : t == 'vouchers'
          ? const MyVouchersScreen()
          : t == 'loyalty'
              ? const CoinsScreen()
              : t == 'membership'
                  ? const MembershipScreen()
                  : t == 'shop'
                      ? const ShopScreen()
                      : null;
  if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

String _ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24 && d.day == DateTime.now().day) return '${diff.inHours} jam lalu';
  return fmtDateTime.format(d);
}

String _group(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return 'Sebelumnya';
}

/// Ikon lonceng dengan badge jumlah belum dibaca.
class NotifBell extends StatelessWidget {
  const NotifBell({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final n = app.unreadCount;
          return InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: kLine)),
                  child: const Icon(Icons.notifications_none_rounded, color: kNavy),
                ),
                if (n > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBg, width: 1.5)),
                      child: Text(n > 9 ? '9+' : '$n',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ),
          );
        },
      );
}

// ---------- LAYAR NOTIFIKASI (header navy bergelombang + kartu putih) ----------

/// Ikon dan warna tiap jenis notifikasi (hanya gaya visual; model tidak diubah).
/// Pesanan = biru, Pembayaran = hijau, Coins/Promo = kuning.
(IconData, Color) _notifStyle(NotifType t) => switch (t) {
      NotifType.order => (Icons.directions_car_filled_rounded, const Color(0xFF3B5FB8)),
      NotifType.payment => (Icons.verified_rounded, kRwGreen),
      NotifType.points => (Icons.monetization_on_rounded, const Color(0xFFE39A0B)),
      NotifType.promo => (Icons.campaign_rounded, const Color(0xFFE39A0B)),
      NotifType.voucher => (Icons.local_offer_rounded, kRwDanger),
      NotifType.membership => (Icons.workspace_premium_rounded, const Color(0xFFC98F12)),
      NotifType.reminder => (Icons.alarm_rounded, const Color(0xFF3B5FB8)),
    };

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _filter = 0;
  static const _labels = ['Semua', 'Pesanan', 'Pembayaran', 'Voucher', 'Coins & Promo', 'Membership'];
  static const _icons = <IconData?>[
    null,
    Icons.shopping_bag_outlined,
    Icons.credit_card_rounded,
    Icons.confirmation_number_outlined,
    Icons.monetization_on_outlined,
    Icons.workspace_premium_outlined,
  ];

  @override
  void initState() {
    super.initState();
    app.refreshNotifications();
  }

  bool _match(AppNotification n) => switch (_filter) {
        1 => n.type == NotifType.order || n.type == NotifType.reminder,
        2 => n.type == NotifType.payment,
        3 => n.type == NotifType.voucher,
        4 => n.type == NotifType.points || n.type == NotifType.promo,
        5 => n.type == NotifType.membership,
        _ => true,
      };

  /// Pil kategori di dalam header: aktif = merah + teks putih, tidak aktif = transparan + garis putih.
  Widget _pill(int i) {
    final sel = _filter == i;
    final icon = _icons[i];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kRed : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? kRed : Colors.white.withValues(alpha: .75), width: 1.3),
            boxShadow: sel ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 10, offset: Offset(0, 4))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6)],
            Text(_labels[i], style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600, fontSize: 13, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  /// Header: kembali (kiri), judul besar di tengah, Tandai dibaca (kanan), lalu pil kategori.
  Widget _header(BuildContext context, double pad) => NavyHeader(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 48,
            child: Stack(alignment: Alignment.center, children: [
              const Text('Notifikasi',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.3)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad - 8),
                child: Row(children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: app,
                    builder: (context, _) => TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withValues(alpha: .5),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                      onPressed: app.unreadCount == 0 ? null : app.markAllRead,
                      child: const Text('Tandai dibaca'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Row(children: [for (var i = 0; i < _labels.length; i++) _pill(i)]),
          ),
        ]),
      );

  /// Kartu notifikasi. Belum dibaca: putih tegas, judul tebal, ikon penuh warna, titik merah.
  /// Sudah dibaca: latar redup, judul lebih ringan, ikon lebih pudar, tanpa titik merah.
  Widget _tile(AppNotification n) {
    final (icon, color) = _notifStyle(n.type);
    final unread = !n.read;
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => app.deleteNotification(n),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: kRwDanger, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RwCard(
          color: unread ? Colors.white : const Color(0xFFF8FAFE),
          borderColor: unread ? const Color(0xFFD7E2F6) : kRwLine,
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          onTap: () => openNotification(context, n),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: unread ? .15 : .08), shape: BoxShape.circle),
              child: Icon(icon, color: color.withValues(alpha: unread ? 1 : .65), size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title,
                    style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: unread ? kRwText : kRwText.withValues(alpha: .72))),
                const SizedBox(height: 3),
                Text(n.body, style: const TextStyle(color: kRwSub, fontSize: 13, height: 1.35)),
                const SizedBox(height: 6),
                Text(_ago(n.createdAt), style: const TextStyle(color: kRwSub, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            if (unread) ...[
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // ikon status bar putih karena header berwarna gelap
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: kRwBg,
          body: LayoutBuilder(builder: (context, cons) {
            final pad = pagePad(cons.maxWidth);
            return Column(children: [
              _header(context, pad),
              Expanded(
                child: ListenableBuilder(
                  listenable: app,
                  builder: (context, _) {
                    final list = app.notifications.where(_match).toList();
                    final children = <Widget>[];
                    String? lastGroup;
                    for (final n in list) {
                      final g = _group(n.createdAt);
                      if (g != lastGroup) {
                        children.add(Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 8, left: 2),
                          child: Text(g, style: const TextStyle(fontWeight: FontWeight.w800, color: kRwSub, fontSize: 13)),
                        ));
                        lastGroup = g;
                      }
                      children.add(_tile(n));
                    }
                    return RefreshIndicator(
                      color: kRwNavy,
                      onRefresh: app.refreshNotifications,
                      child: list.isEmpty
                          ? ListView(padding: EdgeInsets.fromLTRB(pad, 40, pad, 24), children: const [
                              EmptyState(
                                icon: Icons.notifications_off_outlined,
                                title: 'Belum ada notifikasi',
                                message: 'Info pesanan, pembayaran, Coins, membership, dan promo muncul di sini.',
                              ),
                            ])
                          : ListView(padding: EdgeInsets.fromLTRB(pad, 16, pad, 24), children: children),
                    );
                  },
                ),
              ),
            ]);
          }),
        ),
      );
}