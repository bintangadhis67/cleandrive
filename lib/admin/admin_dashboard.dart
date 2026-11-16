import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../app_state.dart';
import '../data/repository.dart';
import '../membership_models.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// AKTIVITAS TERBARU (dipakai Dashboard dan lonceng notifikasi di header)
// ---------------------------------------------------------------------------
class ActivityTile extends StatelessWidget {
  final AdminActivity a;
  const ActivityTile(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (a.kind) {
      AdminActivityKind.order => (Icons.shopping_cart_outlined, kRed),
      AdminActivityKind.done => (Icons.check_circle_outline_rounded, kGreen),
      AdminActivityKind.verified => (Icons.confirmation_number_outlined, kBlue),
      AdminActivityKind.checkin => (Icons.star_outline_rounded, kGold),
      AdminActivityKind.customer => (Icons.person_outline_rounded, kPurple),
      AdminActivityKind.cancelled => (Icons.remove_shopping_cart_outlined, kError),
    };
    final time = sameDay(a.at, DateTime.now()) ? fmtHm.format(a.at).replaceAll(':', '.') : fmtDate.format(a.at);
    return Row(children: [
      IconBox(icon, color, size: 40),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kNavy)),
          Text(a.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      ),
      const SizedBox(width: 8),
      Text(time, style: const TextStyle(fontSize: 12, color: kMuted)),
    ]);
  }
}

void showAllActivities(BuildContext context) {
  final list = adminData.overview?.activities ?? const <AdminActivity>[];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(
        width: 440,
        height: 440,
        child: list.isEmpty
            ? const Center(child: Text('Belum ada aktivitas.', style: TextStyle(color: kMuted)))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: kRowLine),
                itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: ActivityTile(list[i])),
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ),
  );
}

// ---------------------------------------------------------------------------
// DASHBOARD
// ---------------------------------------------------------------------------
class AdminDashboard extends StatefulWidget {
  /// Pindah ke menu lain (indeks menu sidebar).
  final ValueChanged<int> onNavigate;
  const AdminDashboard({super.key, required this.onNavigate});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _months = 6;

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([app, adminData, adminDate]),
        builder: (context, _) {
          final all = app.bookings;
          return AdminPageBody(children: [
            _greeting(),
            const SizedBox(height: 16),
            _stats(all),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (_, c) => _main(c.maxWidth, all)),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (_, c) => _bottom(c.maxWidth)),
          ]);
        },
      );

  // ---------- sapaan ----------
  Widget _greeting() => Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: kCardLine)),
          child: const Icon(Icons.directions_car_filled_rounded, color: kRed, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_greet()}, Admin!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
            const Text('Pantau operasional CleanDrive hari ini.', style: TextStyle(color: kMuted, fontSize: 13.5)),
          ]),
        ),
      ]);

  // ---------- kartu statistik ----------
  Widget _stats(List<Booking> all) {
    final done = all.where((b) => !b.cancelled && b.status >= 3).toList();
    final paidDone = done.where((b) => b.paid).toList();
    final revenue = paidDone.fold<int>(0, (s, b) => s + b.total);
    final r = app.rating;
    return StatGrid([
      _StatCard(icon: Icons.shopping_bag_outlined, color: kRed, label: 'Total Pesanan', value: fmtNum(all.length), trend: weeklyTrend(all, (_) => 1)),
      _StatCard(icon: Icons.payments_outlined, color: kGreen, label: 'Pendapatan', value: rp(revenue), trend: weeklyTrend(paidDone, (b) => b.total)),
      _StatCard(icon: Icons.task_alt_rounded, color: kBlue, label: 'Pesanan Selesai', value: fmtNum(done.length), trend: weeklyTrend(done, (_) => 1)),
      _StatCard(
        icon: Icons.star_outline_rounded,
        color: kGold,
        label: 'Rating Pelanggan',
        value: r.count == 0 ? '-' : fmtPct(r.avg),
        suffix: r.count == 0 ? null : ' / 5',
        note: r.count == 0 ? 'Belum ada ulasan' : 'dari ${fmtNum(r.count)} ulasan',
      ),
    ]);
  }

  // ---------- area utama ----------
  Widget _main(double w, List<Booking> all) {
    final revenue = _revenueCard(all);
    final status = _statusCard(all);
    final queue = _queueCard();
    final activity = _activityCard();
    if (w >= 1100) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: revenue),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: status),
            ]),
            const SizedBox(height: 16),
            queue,
          ]),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 340, child: activity),
      ]);
    }
    return Column(children: [
      if (w >= 760)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: revenue),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: status),
        ])
      else ...[revenue, const SizedBox(height: 16), status],
      const SizedBox(height: 16),
      queue,
      const SizedBox(height: 16),
      activity,
    ]);
  }

  Widget _revenueCard(List<Booking> all) {
    final data = monthlyRevenue(all, _months);
    final fmt = DateFormat('MMM', 'id_ID');
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardTitle(
          'Pendapatan',
          trailing: AdminDropdown<int>(
            compact: true,
            value: _months,
            items: const {3: '3 Bulan Terakhir', 6: '6 Bulan Terakhir', 12: '12 Bulan Terakhir'},
            onChanged: (v) => setState(() => _months = v),
          ),
        ),
        const SizedBox(height: 14),
        RevenueLineChart(values: [for (final m in data) m.amount.toDouble()], labels: [for (final m in data) fmt.format(m.month)]),
        const SizedBox(height: 6),
        const Text('Dari pesanan yang sudah selesai dan lunas.', style: TextStyle(color: kMuted, fontSize: 11.5)),
      ]),
    );
  }

  Widget _statusCard(List<Booking> all) {
    final cnt = statusCounts(all);
    final total = all.length;
    final order = QStatus.values;
    final donut = DonutChart(
      size: 150,
      values: [for (final s in order) (cnt[s] ?? 0).toDouble()],
      colors: [for (final s in order) s.color],
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(fmtNum(total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kNavy)),
        const Text('Total', style: TextStyle(fontSize: 12, color: kMuted)),
      ]),
    );
    final legend = Column(children: [
      for (final s in order)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5))),
            Text('${fmtNum(cnt[s] ?? 0)} (${fmtPct(total == 0 ? 0 : (cnt[s] ?? 0) / total * 100)}%)',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kNavy)),
          ]),
        ),
    ]);
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CardTitle('Status Pesanan'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, c) => c.maxWidth >= 340
              ? Row(children: [donut, const SizedBox(width: 14), Expanded(child: legend)])
              : Column(children: [Center(child: donut), const SizedBox(height: 12), legend]),
        ),
        const SizedBox(height: 8),
        const Text('* Persentase dari total pesanan', style: TextStyle(color: kMuted, fontSize: 11)),
      ]),
    );
  }

  Widget _queueCard() {
    final day = adminDate.value;
    final isToday = sameDay(day, DateTime.now());
    final list = app.queue.where((b) => sameDay(b.slot, day)).take(5).toList();
    String sub(Booking b) {
      if (b.pack.isShop) return '${b.itemCount} item';
      if (b.pack.isOil) return b.items.isEmpty ? '${b.pack.minutes} menit' : b.items.first.product.name;
      return '${b.pack.minutes} menit';
    }

    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CardTitle(
          isToday ? 'Antrean Hari Ini' : 'Antrean ${fmtDate.format(day)}',
          trailing: SmallOutlineButton('Lihat Semua Antrean', () => widget.onNavigate(1)),
        ),
        const SizedBox(height: 12),
        AdminTable(
          pager: false,
          minWidth: 760,
          emptyText: isToday ? 'Belum ada antrean hari ini.' : 'Tidak ada antrean pada tanggal ini.',
          cols: const [TCol('Pelanggan', flex: 3), TCol('Layanan', flex: 3), TCol('Kendaraan', flex: 2), TCol('Jadwal', flex: 2), TCol('Status', flex: 2)],
          rows: [
            for (final b in list)
              [
                PersonCell(b.owner, b.code),
                Row(children: [
                  IconBox(serviceIcon(b.pack), kRed, size: 34),
                  const SizedBox(width: 10),
                  Expanded(child: TwoLine(b.pack.isShop ? 'Pembelian Toko' : b.pack.title, sub(b))),
                ]),
                TwoLine(b.pack.isShop ? '-' : b.vehicle.label, b.pack.isShop ? null : b.plate),
                TwoLine(fmtDate.format(b.slot), fmtHm.format(b.slot), false),
                leftCell(QBadge(b)),
              ],
          ],
        ),
      ]),
    );
  }

  Widget _activityCard() {
    final ov = adminData.overview;
    final acts = ov?.activities.take(5).toList() ?? const <AdminActivity>[];
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CardTitle('Aktivitas Terbaru'),
        const SizedBox(height: 10),
        if (ov == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Skeleton(height: 150, radius: 14))
        else if (acts.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Belum ada aktivitas.', style: TextStyle(color: kMuted))))
        else
          for (var i = 0; i < acts.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: kRowLine),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: ActivityTile(acts[i])),
          ],
        const SizedBox(height: 10),
        WideLinkButton('Lihat Semua Aktivitas', () => showAllActivities(context)),
      ]),
    );
  }

  // ---------- Coins dan Membership (dua panel terpisah) ----------
  Widget _bottom(double w) {
    final coins = _coinsCard();
    final member = _membershipCard();
    if (w >= 860) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: coins),
        const SizedBox(width: 16),
        Expanded(child: member),
      ]);
    }
    return Column(children: [coins, const SizedBox(height: 16), member]);
  }

  Widget _coinsCard() {
    final s = adminData.overview?.coins;
    String v(int? n) => n == null ? '-' : fmtNum(n);
    Widget tile(String label, IconData icon, String value, String unit) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCreamLine)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: kMuted)),
            const SizedBox(height: 6),
            Icon(icon, color: kGold, size: 20),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy))),
            Text(unit, style: const TextStyle(fontSize: 12, color: kMuted)),
          ]),
        );
    return AdminCard(
      color: kCreamSoft,
      border: kCreamLine,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFF6C453), Color(0xFFE08A00)])),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('CleanDrive Coins', style: TextStyle(color: kGoldDeep, fontWeight: FontWeight.w800, fontSize: 18))),
        ]),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, c) => ColumnsGrid(cols: c.maxWidth >= 520 ? 4 : 2, gap: 10, children: [
            tile('Total Coins Beredar', Icons.savings_outlined, v(s?.circulating), 'Coins'),
            tile('Check-in Hari Ini', Icons.event_available_outlined, v(s?.checkinsToday), 'Pengguna'),
            tile('Penukaran Coins', Icons.card_giftcard_rounded, v(s?.redeemCount), 'Transaksi'),
            tile('Coins Terpakai', Icons.monetization_on_outlined, v(s?.redeemedCoins), 'Coins'),
          ]),
        ),
        const SizedBox(height: 4),
        WideLinkButton('Lihat Detail Coins', () => widget.onNavigate(6), color: kGoldDeep, border: kCreamLine, fill: Colors.white.withValues(alpha: .6)),
      ]),
    );
  }

  Widget _membershipCard() {
    final ov = adminData.overview;
    final counts = {for (final t in MembershipTier.values) t: 0};
    for (final c in ov?.customers ?? const <AdminCustomer>[]) {
      final t = c.activeTier;
      if (t != null) counts[t] = (counts[t] ?? 0) + 1;
    }
    final active = counts.values.fold<int>(0, (s, v) => s + v);
    final registered = ov?.customers.length ?? 0;

    final left = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBlueLine)),
      child: Row(children: [
        const Icon(Icons.groups_rounded, color: kBlue, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Member Aktif', style: TextStyle(fontSize: 12.5, color: kNavy)),
            Text(ov == null ? '-' : fmtNum(active), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kNavy)),
            Text(ov == null ? '' : 'dari ${fmtNum(registered)} pelanggan terdaftar', style: const TextStyle(fontSize: 11.5, color: kMuted)),
          ]),
        ),
      ]),
    );
    final right = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBlueLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Distribusi Member Aktif', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kNavy)),
        const SizedBox(height: 6),
        TierBars(counts),
      ]),
    );

    return AdminCard(
      color: kBlueSoft,
      border: kBlueLine,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Icon(Icons.workspace_premium_rounded, color: kNavy, size: 30),
          SizedBox(width: 10),
          Expanded(child: Text('Membership', style: TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 18))),
        ]),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (_, c) => c.maxWidth >= 520
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 4, child: left),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: right),
                ])
              : Column(children: [left, const SizedBox(height: 12), right]),
        ),
        const SizedBox(height: 14),
        WideLinkButton('Lihat Detail Membership', () => widget.onNavigate(7), color: kNavy, border: kBlueLine, fill: Colors.white.withValues(alpha: .6)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final String? suffix, note;
  final Trend? trend;
  const _StatCard({required this.icon, required this.color, required this.label, required this.value, this.suffix, this.note, this.trend});

  @override
  Widget build(BuildContext context) {
    Widget bottom;
    if (trend != null) {
      final c = trend!.up ? kGreen : kError;
      bottom = Row(children: [
        Icon(trend!.up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: c),
        const SizedBox(width: 3),
        Expanded(child: Text(trend!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: c))),
      ]);
    } else {
      bottom = Text(note ?? 'Belum ada pembanding', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: kMuted));
    }
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconBox(icon, color, size: 54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: kNavy)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kNavy)),
                if (suffix != null) Text(suffix!, style: const TextStyle(fontSize: 15, color: kMuted)),
              ]),
            ),
            const SizedBox(height: 4),
            bottom,
          ]),
        ),
      ]),
    );
  }
}
