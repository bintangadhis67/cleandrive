import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:image_picker/image_picker.dart';

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/repository.dart' show ApiException;
import '../../../models/catalog.dart';
import '../../../models/catalog_remote.dart';
import '../../../models/models.dart';
import '../../shop/shop.dart' show ProductImage;
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// LAYANAN & PRODUK: paket cuci, jasa ganti oli, produk toko (foto, harga, stok).
// Produk (oli dan Toko): tambah, ubah, hapus, stok, dan foto tersimpan di backend.
// Paket cuci dan jasa ganti oli: deskripsi, durasi, dan harga motor/mobil bisa diubah dan tersimpan di backend.
// Menambah atau menghapus paket belum didukung (paket baru butuh ilustrasi per kendaraan).
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

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _img(Product p) => Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
        child: ProductImage(p, height: 38, cacheWidth: 120),
      );

  Widget _stock(Product p) {
    final s = app.stockOf(p);
    if (s <= 0) return const StatusBadge('Habis', kError);
    if (s <= kLowStock) return StatusBadge('Sisa $s', kWarn);
    return StatusBadge('$s tersedia', kGreen);
  }

  /// Paket cuci: ubah tersambung ke backend; hapus belum didukung.
  Widget _pkgActions(WashPackage p) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: () => _editPackage(p),
          icon: const Icon(Icons.edit_outlined, size: 19, color: kBlue),
        ),
        IconButton(
          tooltip: 'Hapus',
          visualDensity: VisualDensity.compact,
          onPressed: _packageInfo,
          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: kError),
        ),
      ]);

  Future<void> _editPackage(WashPackage p) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PackageDialog(p),
    );
    if (saved == true) _toast('Perubahan ${p.title} disimpan.');
  }

  void _packageInfo() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Belum didukung'),
          content: const Text(
              'Menambah atau menghapus paket layanan belum didukung, karena paket baru membutuhkan ilustrasi untuk setiap kendaraan. Deskripsi, durasi, dan harga paket yang ada bisa diubah lewat tombol Edit.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );

  /// Produk: sudah tersambung ke backend.
  Widget _productActions(Product p) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: () => _editProduct(product: p),
          icon: const Icon(Icons.edit_outlined, size: 19, color: kBlue),
        ),
        IconButton(
          tooltip: 'Hapus',
          visualDensity: VisualDensity.compact,
          onPressed: () => _deleteProduct(p),
          icon: const Icon(Icons.delete_outline_rounded, size: 19, color: kError),
        ),
      ]);

  Future<void> _editProduct({Product? product, ProductCategory? fixed}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductDialog(product: product, fixedCategory: fixed),
    );
    if (saved == true) _toast(product == null ? 'Produk ditambahkan.' : 'Perubahan disimpan.');
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('${p.name} akan dihapus dari Toko. Produk yang sudah pernah dipesan hanya dinonaktifkan supaya riwayat pesanan tetap utuh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final msg = await app.repo.deleteProduct(p.id);
      await app.loadCatalog(force: true);
      await app.refreshAll();
      _toast(msg);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

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
                leftCell(_pkgActions(p)),
              ],
          ],
        ),
      );

  Widget _oilTab() {
    final oils = productsIn(ProductCategory.oli).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () => _editPackage(oilChangePackage),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Ubah harga jasa'),
        ),
      ),
      const SizedBox(height: 12),
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
            emptyText: 'Belum ada oli. Tekan "Tambah Oli" untuk menambahkan.',
            cols: const [TCol('Oli', flex: 4), TCol('Kendaraan', flex: 2), TCol('Harga', flex: 2), TCol('Stok', flex: 2), TCol('Aksi', flex: 2)],
            rows: [
              for (final p in oils)
                [
                  Row(children: [_img(p), const SizedBox(width: 10), Expanded(child: TwoLine(p.name, p.desc))]),
                  Text(p.vehicleTag.isEmpty ? 'Semua' : p.vehicleTag, style: const TextStyle(fontSize: 13)),
                  Text(rp(p.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  leftCell(_stock(p)),
                  leftCell(_productActions(p)),
                ],
            ],
          ),
        ]),
      ),
    ]);
  }

  Widget _shopTab() {
    final q = _q.trim().toLowerCase();
    final list = catalogProducts.where((p) => p.active && (_cat == null || p.category == _cat) && (q.isEmpty || p.name.toLowerCase().contains(q))).toList();
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
                leftCell(_productActions(p)),
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
            const InfoBanner('Produk (oli dan Toko) serta deskripsi, durasi, dan harga paket sudah tersambung ke backend dan tersimpan di server. Menambah atau menghapus paket cuci belum didukung.'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: PillBar(labels: labels, index: _tab, onChanged: (i) => setState(() => _tab = i))),
              const SizedBox(width: 12),
              RedAction(adds[_tab], () {
                if (_tab == 0) {
                  _packageInfo();
                } else if (_tab == 1) {
                  _editProduct(fixed: ProductCategory.oli);
                } else {
                  _editProduct();
                }
              }, icon: Icons.add_rounded),
            ]),
            const SizedBox(height: 8),
            if (_tab == 0) _washTab() else if (_tab == 1) _oilTab() else _shopTab(),
          ]);
        },
      );
}

// ---------------------------------------------------------------------------
// Form tambah / ubah produk, termasuk memilih foto dari perangkat.
// ---------------------------------------------------------------------------
class _ProductDialog extends StatefulWidget {
  final Product? product;

  /// Tab Ganti Oli mengunci kategori ke Oli.
  final ProductCategory? fixedCategory;
  const _ProductDialog({this.product, this.fixedCategory});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.product?.desc ?? '');
  late final TextEditingController _details = TextEditingController(text: widget.product?.details ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.product == null ? '' : '${widget.product!.price}');
  late final TextEditingController _stock = TextEditingController(text: widget.product == null ? '20' : '${app.stockOf(widget.product!)}');
  late ProductCategory _cat = widget.product?.category ?? widget.fixedCategory ?? ProductCategory.makanan;
  late final Set<VehicleType> _vehicles = <VehicleType>{...?widget.product?.vehicles};
  PickedImage? _picked;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _details.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        setState(() => _error = 'Ukuran foto maksimal 2 MB.');
        return;
      }
      setState(() {
        _picked = PickedImage(bytes, x.name);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Foto tidak dapat dibuka.');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Nama produk wajib diisi.');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _error = 'Harga harus berupa angka lebih dari 0.');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() => _error = 'Stok harus berupa angka 0 atau lebih.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final p = Product(
        widget.product?.id ?? '',
        name,
        _desc.text.trim(),
        price,
        _cat,
        widget.product?.image ?? '',
        vehicles: _cat == ProductCategory.oli ? _vehicles : const <VehicleType>{},
        stock: stock,
        detailsText: _details.text.trim(),
      );
      await app.repo.saveProduct(p, image: _picked);
      await app.loadCatalog(force: true);
      await app.refreshAll();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan. Periksa koneksi ke server lalu coba lagi.';
        });
      }
    }
  }

  Widget _photo() {
    final Widget preview;
    if (_picked != null) {
      preview = Image.memory(_picked!.bytes, fit: BoxFit.contain);
    } else if (widget.product != null && widget.product!.image.isNotEmpty) {
      preview = ProductImage(widget.product!, height: 100);
    } else {
      preview = const Icon(Icons.add_photo_alternate_outlined, size: 40, color: kMuted);
    }
    return Row(children: [
      Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16)),
        child: Center(child: preview),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OutlinedButton.icon(
            onPressed: _saving ? null : _pick,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: Text(_picked == null ? 'Pilih foto' : 'Ganti foto'),
          ),
          const SizedBox(height: 6),
          Text(
            _picked != null ? _picked!.name : 'PNG, JPG, atau WEBP, maksimal 2 MB. Foto dengan latar transparan paling bagus.',
            style: const TextStyle(color: kMuted, fontSize: 12),
          ),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    return AlertDialog(
      title: Text(editing ? 'Ubah produk' : 'Tambah produk', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _photo(),
            const SizedBox(height: 16),
            TextField(controller: _name, enabled: !_saving, decoration: const InputDecoration(labelText: 'Nama produk')),
            const SizedBox(height: 10),
            TextField(controller: _desc, enabled: !_saving, decoration: const InputDecoration(labelText: 'Deskripsi singkat')),
            const SizedBox(height: 10),
            TextField(controller: _details, enabled: !_saving, maxLines: 3, decoration: const InputDecoration(labelText: 'Keterangan lengkap')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stock,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Stok'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            const Text('Kategori', style: TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final c in ProductCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _cat == c,
                  onSelected: (_saving || widget.fixedCategory != null) ? null : (_) => setState(() => _cat = c),
                ),
            ]),
            if (_cat == ProductCategory.oli) ...[
              const SizedBox(height: 14),
              const Text('Cocok untuk kendaraan', style: TextStyle(fontSize: 12.5, color: kMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final v in VehicleType.values)
                  FilterChip(
                    label: Text(v.label),
                    selected: _vehicles.contains(v),
                    onSelected: _saving
                        ? null
                        : (s) => setState(() {
                              if (s) {
                                _vehicles.add(v);
                              } else {
                                _vehicles.remove(v);
                              }
                            }),
                  ),
              ]),
              const SizedBox(height: 4),
              const Text('Tidak dipilih = cocok untuk semua kendaraan.', style: TextStyle(fontSize: 12, color: kMuted)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: kError, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form ubah paket: deskripsi, durasi, harga motor, dan harga mobil.
// ---------------------------------------------------------------------------
class _PackageDialog extends StatefulWidget {
  final WashPackage pack;
  const _PackageDialog(this.pack);

  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  late final TextEditingController _desc = TextEditingController(text: widget.pack.desc);
  late final TextEditingController _minutes = TextEditingController(text: '${widget.pack.minutes}');
  late final TextEditingController _motor = TextEditingController(text: '${widget.pack.priceFor(VehicleType.motor)}');
  late final TextEditingController _mobil = TextEditingController(text: '${widget.pack.priceFor(VehicleType.mobil)}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    _minutes.dispose();
    _motor.dispose();
    _mobil.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final desc = _desc.text.trim();
    final minutes = int.tryParse(_minutes.text.trim());
    final motor = int.tryParse(_motor.text.trim());
    final mobil = int.tryParse(_mobil.text.trim());
    if (desc.isEmpty) {
      setState(() => _error = 'Deskripsi paket wajib diisi.');
      return;
    }
    if (minutes == null || minutes < 5 || minutes > 600) {
      setState(() => _error = 'Durasi harus antara 5 dan 600 menit.');
      return;
    }
    if (motor == null || motor < 1000 || mobil == null || mobil < 1000) {
      setState(() => _error = 'Harga harus berupa angka minimal Rp 1.000.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.repo.savePackage(widget.pack.name, desc: desc, minutes: minutes, priceMotor: motor, priceMobil: mobil);
      await app.loadCatalog(force: true);
      await app.refreshAll();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan. Periksa koneksi ke server lalu coba lagi.';
        });
      }
    }
  }

  Widget _numberField(TextEditingController c, String label) => TextField(
        controller: c,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Ubah ${widget.pack.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: _desc, enabled: !_saving, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi')),
              const SizedBox(height: 10),
              _numberField(_minutes, 'Durasi (menit)'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _numberField(_motor, 'Harga motor (Rp)')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_mobil, 'Harga mobil (Rp)')),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Harga dan durasi baru berlaku untuk pesanan berikutnya. Pesanan yang sudah dibuat tidak berubah.',
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: kError, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ],
      );
}
