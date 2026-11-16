import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repository.dart';
import '../loyalty_models.dart';
import '../membership_models.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// PELANGGAN: tabel pelanggan, total transaksi, status membership, saldo Coins, detail.
// Data dari repo.adminOverview(); pesanan diambil dari app.bookings.
// ---------------------------------------------------------------------------
class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  String _q = '';
  int _tier = 0; // 0 = semua, -1 = tanpa membership aktif, 1..4 = peringkat tingkat

  static final _tierItems = <int, String>{
    0: 'Semua membership',
    -1: 'Tanpa membership',
    for (final t in MembershipTier.values) t.rank: t.label,
  };

  void _detail(AdminCustomer c) {
    final orders = app.bookings.where((b) => b.owner == c.name).take(3).toList();
    final m = c.membership;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          InitialAvatar(c.name, size: 44),
          const SizedBox(width: 12),
          Expanded(child: TwoLine(c.name, c.email)),
        ]),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              kv('No. telepon', c.phone.isEmpty ? '-' : c.phone),
              kv('Bergabung', fmtDate.format(c.joinedAt)),
              kv('Total pesanan', '${c.orders} pesanan'),
              kv('Total pembayaran lunas', rp(c.spent)),
              kv('Saldo Coins', '${fmtNum(c.coins)} Coins (setara ${rp(c.coins * kCoinValue)})'),
              kv('Membership', c.activeTier != null ? c.activeTier!.label : (m == null ? 'Belum berlangganan' : m.status.label)),
              if (c.hasActiveMembership) ...[
                kv('Berlaku hingga', fmtDate.format(m!.endDate!)),
                kv('Sisa masa aktif', '${m.daysLeft} hari'),
              ],
              const Divider(height: 22),
              const Text('Pesanan terbaru', style: TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
              const SizedBox(height: 8),
              if (orders.isEmpty)
                const Text('Belum ada pesanan.', style: TextStyle(color: kMuted))
              else
                for (final b in orders)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(child: TwoLine(b.pack.title, '${b.code} • ${fmtDate.format(b.slot)}')),
                      const SizedBox(width: 8),
                      QBadge(b),
                    ]),
                  ),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OverviewGate(builder: (ov) {
        final q = _q.trim().toLowerCase();
        final list = ov.customers.where((c) {
          if (_tier == -1 && c.hasActiveMembership) return false;
          if (_tier > 0 && c.activeTier?.rank != _tier) return false;
          if (q.isEmpty) return true;
          return c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q) || c.phone.contains(q);
        }).toList();
        final members = ov.customers.where((c) => c.hasActiveMembership).length;
        final orders = ov.customers.fold<int>(0, (s, c) => s + c.orders);

        return AdminPageBody(children: [
          StatGrid([
            MiniStat(Icons.people_alt_outlined, kBlue, 'Total Pelanggan', fmtNum(ov.customers.length)),
            MiniStat(Icons.workspace_premium_outlined, kGoldDeep, 'Member Aktif', fmtNum(members)),
            MiniStat(Icons.receipt_long_outlined, kRed, 'Total Pesanan', fmtNum(orders)),
            MiniStat(Icons.monetization_on_outlined, kGold, 'Coins Beredar', fmtNum(ov.coins.circulating)),
          ]),
          const SizedBox(height: 16),
          AdminCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SearchBox(hint: 'Cari nama, email, atau telepon', onChanged: (v) => setState(() => _q = v)),
                AdminDropdown<int>(value: _tier, items: _tierItems, onChanged: (v) => setState(() => _tier = v)),
              ]),
              const SizedBox(height: 14),
              AdminTable(
                minWidth: 900,
                emptyText: 'Tidak ada pelanggan yang cocok.',
                cols: const [TCol('Pelanggan', flex: 4), TCol('Telepon', flex: 2), TCol('Total Transaksi', flex: 3), TCol('Membership', flex: 2), TCol('Coins', flex: 2), TCol('Aksi', flex: 2)],
                rows: [
                  for (final c in list)
                    [
                      PersonCell(c.name, c.email),
                      Text(c.phone.isEmpty ? '-' : c.phone, style: const TextStyle(fontSize: 13)),
                      TwoLine('${c.orders} pesanan', rp(c.spent)),
                      leftCell(c.activeTier != null
                          ? StatusBadge(c.activeTier!.label, c.activeTier!.color)
                          : StatusBadge(c.membership == null ? 'Belum berlangganan' : c.membership!.status.label, kMuted)),
                      Row(children: [
                        const Icon(Icons.monetization_on_rounded, color: kGold, size: 18),
                        const SizedBox(width: 6),
                        Text(fmtNum(c.coins), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      leftCell(SmallOutlineButton('Detail', () => _detail(c), chevron: false)),
                    ],
                ],
              ),
            ]),
          ),
        ]);
      });
}
