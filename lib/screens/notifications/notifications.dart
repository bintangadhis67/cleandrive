import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/notification_models.dart';
import '../../widgets/widgets.dart';
import '../orders/orders.dart';
import '../rewards/loyalty.dart';
import '../rewards/membership.dart';
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

// ---------- LAYAR NOTIFIKASI ----------
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _filter = 0;
  static const _labels = ['Semua', 'Pesanan', 'Pembayaran', 'Voucher', 'Coins & Promo', 'Membership'];

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

  Widget _pill(int i) => FilterPill(label: _labels[i], selected: _filter == i, onTap: () => setState(() => _filter = i));

  Widget _tile(AppNotification n) => Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => app.deleteNotification(n),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: kError, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            color: n.read ? Colors.white : const Color(0xFFFFF8F2),
            padding: const EdgeInsets.all(14),
            onTap: () => openNotification(context, n),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: n.type.color.withOpacity(.14), shape: BoxShape.circle),
                child: Icon(n.type.icon, color: n.type.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                          style: TextStyle(fontWeight: n.read ? FontWeight.w700 : FontWeight.w800, fontSize: 14.5)),
                    ),
                    if (!n.read) Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 2),
                  Text(n.body, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(_ago(n.createdAt), style: const TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi'),
          actions: [
            ListenableBuilder(
              listenable: app,
              builder: (context, _) => TextButton(
                onPressed: app.unreadCount == 0 ? null : app.markAllRead,
                child: const Text('Tandai dibaca'),
              ),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final list = app.notifications.where(_match).toList();
            final children = <Widget>[];
            String? lastGroup;
            for (final n in list) {
              final g = _group(n.createdAt);
              if (g != lastGroup) {
                children.add(Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(g, style: const TextStyle(fontWeight: FontWeight.w800, color: kMuted, fontSize: 13)),
                ));
                lastGroup = g;
              }
              children.add(_tile(n));
            }
            return LayoutBuilder(builder: (context, cons) {
              final pad = pagePad(cons.maxWidth);
              return Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [for (var i = 0; i < _labels.length; i++) _pill(i)]),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: kRed,
                      onRefresh: app.refreshNotifications,
                      child: list.isEmpty
                          ? ListView(padding: EdgeInsets.fromLTRB(pad, 40, pad, 24), children: const [
                              EmptyState(
                                icon: Icons.notifications_off_outlined,
                                title: 'Belum ada notifikasi',
                                message: 'Info pesanan, pembayaran, Coins, membership, dan promo muncul di sini.',
                              ),
                            ])
                          : ListView(padding: EdgeInsets.fromLTRB(pad, 0, pad, 24), children: children),
                    ),
                  ),
                ]);
            });
          },
        ),
      );
}