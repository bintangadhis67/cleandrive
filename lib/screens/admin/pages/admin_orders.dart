import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// PESANAN & TRANSAKSI: seluruh pesanan, nomor transaksi, total, metode, status pembayaran, filter dan pencarian.
// ---------------------------------------------------------------------------
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _q = '';
  String _pay = 'all';
  String _kind = 'all';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final all = app.bookings;
          final q = _q.trim().toLowerCase();
          final list = all.where((b) {
            if (_pay != 'all' && b.payStatus != _pay) return false;
            if (_kind != 'all' && b.pack.kind.name != _kind) return false;
            if (q.isEmpty) return true;
            return b.code.toLowerCase().contains(q) ||
                (b.trx ?? '').toLowerCase().contains(q) ||
                b.owner.toLowerCase().contains(q) ||
                b.plate.toLowerCase().contains(q);
          }).toList();

          final paid = all.where((b) => b.paid).toList();
          final unpaid = all.where((b) => !b.cancelled && b.payStatus == 'unpaid').length;
          final refunded = all.where((b) => b.payStatus == 'refunded').length;

          return AdminPageBody(children: [
            StatGrid([
              MiniStat(Icons.verified_outlined, kGreen, 'Transaksi Lunas', fmtNum(paid.length)),
              MiniStat(Icons.payments_outlined, kBlue, 'Total Pembayaran', rp(paid.fold<int>(0, (s, b) => s + b.total))),
              MiniStat(Icons.hourglass_empty_rounded, kWarn, 'Belum Dibayar', fmtNum(unpaid)),
              MiniStat(Icons.undo_rounded, kMuted, 'Dikembalikan', fmtNum(refunded)),
            ]),
            const SizedBox(height: 16),
            AdminCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SearchBox(hint: 'Cari transaksi, kode, pelanggan, plat', onChanged: (v) => setState(() => _q = v), width: 320),
                  AdminDropdown<String>(
                    value: _pay,
                    items: const {'all': 'Semua status bayar', 'paid': 'Lunas', 'unpaid': 'Belum dibayar', 'refunded': 'Dikembalikan'},
                    onChanged: (v) => setState(() => _pay = v),
                  ),
                  AdminDropdown<String>(
                    value: _kind,
                    items: const {'all': 'Semua jenis layanan', 'wash': 'Cuci kendaraan', 'oil': 'Ganti oli', 'shop': 'Toko'},
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                ]),
                const SizedBox(height: 14),
                AdminTable(
                  minWidth: 980,
                  emptyText: 'Tidak ada transaksi yang cocok.',
                  cols: const [
                    TCol('No. Transaksi', flex: 3),
                    TCol('Pelanggan', flex: 3),
                    TCol('Layanan', flex: 3),
                    TCol('Total', flex: 2),
                    TCol('Metode', flex: 2),
                    TCol('Status Bayar', flex: 2),
                    TCol('Aksi', flex: 2),
                  ],
                  rows: [
                    for (final b in list)
                      [
                        TwoLine(b.trx ?? '-', b.code),
                        PersonCell(b.owner),
                        TwoLine(b.pack.title, b.pack.isShop ? '${b.itemCount} item' : '${b.vehicle.label} • ${b.plate}'),
                        Text(rp(b.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kNavy)),
                        Text(b.payMethod?.label ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        leftCell(PayChip(b)),
                        leftCell(SmallOutlineButton('Detail', () => showBookingDetail(context, b), chevron: false)),
                      ],
                  ],
                ),
              ]),
            ),
          ]);
        },
      );
}
