import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../membership_models.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// MEMBERSHIP (panel terpisah dari Coins): pelanggan per tingkatan, benefit, syarat level, riwayat.
// ---------------------------------------------------------------------------
class AdminMembershipPage extends StatefulWidget {
  const AdminMembershipPage({super.key});

  @override
  State<AdminMembershipPage> createState() => _AdminMembershipPageState();
}

class _AdminMembershipPageState extends State<AdminMembershipPage> {
  int _tab = 0;
  int _tier = 0; // 0 semua, -1 belum berlangganan, 1..4 tingkat
  String _q = '';

  static final _tierItems = <int, String>{
    0: 'Semua pelanggan',
    -1: 'Belum berlangganan',
    for (final t in MembershipTier.values) t.rank: t.label,
  };

  void _detail(AdminCustomer c) {
    final m = c.membership;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [InitialAvatar(c.name, size: 44), const SizedBox(width: 12), Expanded(child: TwoLine(c.name, c.email))]),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              kv('Status', m == null ? 'Belum berlangganan' : (c.hasActiveMembership ? 'Aktif' : m.status.label)),
              if (m != null) ...[
                kv('Tingkatan', m.tier.label),
                if (m.startDate != null) kv('Mulai', fmtDate.format(m.startDate!)),
                if (m.endDate != null) kv('Berakhir', fmtDate.format(m.endDate!)),
                if (c.hasActiveMembership) kv('Sisa masa aktif', '${m.daysLeft} hari'),
                const Divider(height: 20),
                const Text('Benefit paket', style: TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
                const SizedBox(height: 6),
                for (final b in m.plan.benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_rounded, size: 16, color: kGreen),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                    ]),
                  ),
              ],
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _customers(AdminOverview ov) {
    final q = _q.trim().toLowerCase();
    final list = ov.customers.where((c) {
      if (_tier == -1 && c.membership != null) return false;
      if (_tier > 0 && c.membership?.tier.rank != _tier) return false;
      return q.isEmpty || c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q);
    }).toList();
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SearchBox(hint: 'Cari nama atau email', onChanged: (v) => setState(() => _q = v)),
          AdminDropdown<int>(value: _tier, items: _tierItems, onChanged: (v) => setState(() => _tier = v)),
        ]),
        const SizedBox(height: 14),
        AdminTable(
          minWidth: 900,
          emptyText: 'Tidak ada pelanggan yang cocok.',
          cols: const [TCol('Pelanggan', flex: 4), TCol('Tingkatan', flex: 2), TCol('Status', flex: 2), TCol('Mulai', flex: 2), TCol('Berakhir', flex: 2), TCol('Aksi', flex: 2)],
          rows: [
            for (final c in list)
              [
                PersonCell(c.name, c.email),
                leftCell(c.membership == null ? const Text('-') : StatusBadge(c.membership!.tier.label, c.membership!.tier.color)),
                leftCell(c.membership == null
                    ? const StatusBadge('Belum berlangganan', kMuted)
                    : StatusBadge(c.hasActiveMembership ? 'Aktif' : c.membership!.status.label, c.hasActiveMembership ? kGreen : c.membership!.status.color)),
                Text(c.membership?.startDate == null ? '-' : fmtDate.format(c.membership!.startDate!), style: const TextStyle(fontSize: 13)),
                TwoLine(c.membership?.endDate == null ? '-' : fmtDate.format(c.membership!.endDate!), c.hasActiveMembership ? 'Sisa ${c.membership!.daysLeft} hari' : null, false),
                leftCell(SmallOutlineButton('Detail', () => _detail(c), chevron: false)),
              ],
          ],
        ),
      ]),
    );
  }

  Widget _plans(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AutoGrid(minWidth: 250, gap: 14, children: [
          for (final p in kMembershipPlans)
            AdminCard(
              border: kBlueLine,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconBox(p.tier.icon, p.tier.color, size: 42),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy))),
                  if (p.popular) const StatusBadge('Populer', kRed),
                ]),
                const SizedBox(height: 10),
                Text(rp(p.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
                Text('Masa berlaku ${p.durationLabel}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                const Divider(height: 22),
                kv('Diskon layanan', '${p.discountPct}%'),
                kv('Prioritas', p.priority),
                kv('Promo', p.promo),
                const SizedBox(height: 6),
                for (final b in p.benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_rounded, size: 16, color: kGreen),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: const TextStyle(fontSize: 12.5))),
                    ]),
                  ),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        const AdminCard(
          color: kBlueSoft,
          border: kBlueLine,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardTitle('Syarat kenaikan level', color: kNavy),
            SizedBox(height: 8),
            Text(
              'Level tidak naik otomatis. Membership adalah produk berbayar: pelanggan naik atau pindah tingkat dengan membeli paket '
              'yang diinginkan, dan Coins tidak memengaruhi level. Masa berlaku mengikuti durasi paket dan bisa diperpanjang.',
              style: TextStyle(height: 1.5, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: RedAction('Ubah benefit tingkatan', () => showNotConnected(context, 'Pengaturan benefit'), icon: Icons.tune_rounded)),
      ]);

  Widget _history(AdminOverview ov) => AdminCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: AdminTable(
          minWidth: 880,
          emptyText: 'Belum ada pembelian atau perpanjangan membership.',
          cols: const [TCol('Waktu', flex: 2), TCol('Pelanggan', flex: 3), TCol('Paket', flex: 2), TCol('Jenis', flex: 2), TCol('Metode', flex: 2), TCol('Nominal', flex: 2)],
          rows: [
            for (final r in ov.memberTx)
              [
                TwoLine(fmtDate.format(r.tx.createdAt), fmtHm.format(r.tx.createdAt), false),
                PersonCell(r.customer),
                leftCell(StatusBadge(r.tx.tier.label, r.tx.tier.color)),
                Text(r.tx.renewal ? 'Perpanjangan' : 'Pembelian baru', style: const TextStyle(fontSize: 13)),
                Text(r.tx.method.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                Text(rp(r.tx.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => OverviewGate(builder: (ov) {
        final counts = {for (final t in MembershipTier.values) t: 0};
        for (final c in ov.customers) {
          final t = c.activeTier;
          if (t != null) counts[t] = (counts[t] ?? 0) + 1;
        }
        final active = counts.values.fold<int>(0, (s, v) => s + v);
        final inactive = ov.customers.where((c) => c.membership != null && !c.hasActiveMembership).length;
        final revenue = ov.memberTx.fold<int>(0, (s, r) => s + r.tx.amount);
        Widget content = switch (_tab) {
          0 => _customers(ov),
          1 => _plans(context),
          _ => _history(ov),
        };
        return AdminPageBody(children: [
          StatGrid([
            MiniStat(Icons.workspace_premium_rounded, kBlue, 'Total Member Aktif', fmtNum(active), bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.groups_rounded, kNavy, 'Pelanggan Terdaftar', fmtNum(ov.customers.length), bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.timer_off_outlined, kWarn, 'Tidak Aktif', fmtNum(inactive), sub: 'kedaluwarsa atau dibatalkan', bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.payments_outlined, kGreen, 'Pendapatan Membership', rp(revenue), bg: kBlueSoft, border: kBlueLine),
          ]),
          const SizedBox(height: 16),
          AdminCard(
            color: kBlueSoft,
            border: kBlueLine,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const CardTitle('Distribusi Membership', color: kNavy, leading: Icon(Icons.workspace_premium_rounded, color: kNavy)),
              const SizedBox(height: 8),
              TierBars(counts),
            ]),
          ),
          const SizedBox(height: 16),
          PillBar(labels: const ['Pelanggan', 'Tingkatan & Benefit', 'Riwayat'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 8),
          content,
        ]);
      });
}
