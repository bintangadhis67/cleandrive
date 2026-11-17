import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../models/catalog.dart';
import '../../../models/models.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// LAYANAN & PRODUK: paket cuci, jasa ganti oli, produk toko (gambar, harga, stok).
// Data dibaca dari models.dart / catalog.dart dan stok dari app.stockOf.
// Tambah/Edit/Hapus belum punya backend, jadi menampilkan dialog yang jujur.
// ---------------------------------------------------------------------------
class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({super.key});

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage> {
  int _tab = 0;
  String _q = '';
  ProductCategory? _cat;

  Widget _img(Product p) => Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
        child: Image.asset(p.image, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: kMuted, size: 20)),
      );

  Widget _stock(Product p) {
    final s = app.stockOf(p);
    if (s <= 0) return const StatusBadge('Habis', kError);
    if (s <= kLowStock) return StatusBadge('Sisa $s', kWarn);
    return StatusBadge('$s tersedia', kGreen);
  }

  Widget _actions(String what) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: () => showNotConnected(context, 'Edit $what'),
          icon: const Icon(Icons.edit_outlined, size: 19, color: kBlue),
        ),
        IconButton(
          tooltip: 'Hapus',
          visualDensity: VisualDensity.compact,
          onPressed: () => showNotConnected(context, 'Hapus $what'),
          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: kError),
        ),
      ]);

  int _orders(WashPackage p) =>
      adminData.summary?.byPackage[p.name] ?? app.bookings.where((b) => !b.cancelled && b.pack.name == p.name).length;

  Widget _washTab() => AdminCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: AdminTable(
          pager: false,
          minWidth: 900,
          cols: const [TCol('Paket', flex: 4), TCol('Durasi', flex: 2), TCol('Motor', flex: 2), TCol('Mobil', flex: 2), TCol('Pesanan', flex: 2), TCol('Aksi', flex: 2)],
          rows: [
            for (final p in packages)
              [
                Row(children: [
                  const IconBox(Icons.local_car_wash_rounded, kRed, size: 38),
                  const SizedBox(width: 10),
                  Expanded(child: TwoLine(p.title, p.desc)),
                ]),
                Text('${p.minutes} menit', style: const TextStyle(fontSize: 13)),
                Text(rp(p.priceFor(VehicleType.motor)), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(rp(p.priceFor(VehicleType.mobil)), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(fmtNum(_orders(p)), style: const TextStyle(fontSize: 13)),
                leftCell(_actions('paket cuci')),
              ],
          ],
        ),
      );

  Widget _oilTab() {
    final oils = productsIn(ProductCategory.oli).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StatGrid([
        MiniStat(Icons.two_wheeler, kBlue, 'Jasa ganti oli - Motor', rp(oilChangePackage.priceFor(VehicleType.motor)), sub: '${oilChangePackage.minutes} menit'),
        MiniStat(Icons.directions_car_filled_rounded, kRed, 'Jasa ganti oli - Mobil', rp(oilChangePackage.priceFor(VehicleType.mobil)), sub: '${oilChangePackage.minutes} menit'),
        MiniStat(Icons.receipt_long_outlined, kGoldDeep, 'Pesanan ganti oli', fmtNum(_orders(oilChangePackage))),
      ]),
      const SizedBox(height: 16),
      AdminCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardTitle('Oli yang tersedia'),
          const SizedBox(height: 12),
          AdminTable(
            pager: false,
            minWidth: 820,
            cols: const [TCol('Oli', flex: 4), TCol('Kendaraan', flex: 2), TCol('Harga', flex: 2), TCol('Stok', flex: 2), TCol('Aksi', flex: 2)],
            rows: [
              for (final p in oils)
                [
                  Row(children: [_img(p), const SizedBox(width: 10), Expanded(child: TwoLine(p.name, p.desc))]),
                  Text(p.vehicleTag.isEmpty ? 'Semua' : p.vehicleTag, style: const TextStyle(fontSize: 13)),
                  Text(rp(p.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  leftCell(_stock(p)),
                  leftCell(_actions('oli')),
                ],
            ],
          ),
        ]),
      ),
    ]);
  }

  Widget _shopTab() {
    final q = _q.trim().toLowerCase();
    final list = products.where((p) => (_cat == null || p.category == _cat) && (q.isEmpty || p.name.toLowerCase().contains(q))).toList();
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SearchBox(hint: 'Cari produk', onChanged: (v) => setState(() => _q = v)),
          AdminDropdown<ProductCategory?>(
            value: _cat,
            items: {null: 'Semua kategori', for (final c in ProductCategory.values) c: c.label},
            onChanged: (v) => setState(() => _cat = v),
          ),
        ]),
        const SizedBox(height: 14),
        AdminTable(
          minWidth: 880,
          emptyText: 'Tidak ada produk yang cocok.',
          cols: const [TCol('Produk', flex: 5), TCol('Kategori', flex: 2), TCol('Harga', flex: 2), TCol('Stok', flex: 2), TCol('Aksi', flex: 2)],
          rows: [
            for (final p in list)
              [
                Row(children: [_img(p), const SizedBox(width: 10), Expanded(child: TwoLine(p.name, p.desc))]),
                Text(p.category.label, style: const TextStyle(fontSize: 13)),
                Text(rp(p.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                leftCell(_stock(p)),
                leftCell(_actions('produk')),
              ],
          ],
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([app, adminData]),
        builder: (context, _) {
          const labels = ['Paket Cuci', 'Ganti Oli', 'Produk Toko'];
          const adds = ['Tambah Paket', 'Tambah Oli', 'Tambah Produk'];
          return AdminPageBody(children: [
            const InfoBanner('Daftar ini dibaca dari katalog aplikasi. Tombol tambah, edit, dan hapus belum tersambung ke backend, sehingga belum menyimpan perubahan.'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: PillBar(labels: labels, index: _tab, onChanged: (i) => setState(() => _tab = i))),
              const SizedBox(width: 12),
              RedAction(adds[_tab], () => showNotConnected(context, adds[_tab]), icon: Icons.add_rounded),
            ]),
            const SizedBox(height: 8),
            if (_tab == 0) _washTab() else if (_tab == 1) _oilTab() else _shopTab(),
          ]);
        },
      );
}