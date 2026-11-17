import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../home/customer.dart' show ConfirmOrderScreen;

/// Gambar produk (dengan cadangan ikon bila file tidak ada).
class ProductImage extends StatelessWidget {
  final Product p;
  final double? height;
  final int cacheWidth;
  const ProductImage(this.p, {super.key, this.height, this.cacheWidth = 400});

  @override
  Widget build(BuildContext context) => Image.asset(
        p.image,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Icon(p.category.icon, size: (height ?? 100) * .4, color: kMuted),
      );
}

/// Tombol tambah / pengatur jumlah (dibatasi oleh stok).
class _QtyControl extends StatelessWidget {
  final Product p;
  const _QtyControl(this.p);

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 20, color: onTap == null ? kMuted : kRed)),
      );

  @override
  Widget build(BuildContext context) {
    final q = app.qtyOf(p);
    final left = app.stockOf(p);
    if (q == 0) {
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: left <= 0 ? null : () => app.setQty(p, 1),
          icon: Icon(left <= 0 ? Icons.block_rounded : Icons.add_rounded, size: 18),
          label: Text(left <= 0 ? 'Stok Habis' : 'Tambah', style: const TextStyle(fontSize: 13)),
        ),
      );
    }
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRed, width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _btn(Icons.remove_rounded, () => app.setQty(p, q - 1)),
        Text('$q', style: const TextStyle(fontWeight: FontWeight.w800)),
        _btn(Icons.add_rounded, q >= left ? null : () => app.setQty(p, q + 1)),
      ]),
    );
  }
}

// ---------- TOKO ----------
class ShopScreen extends StatefulWidget {
  final ProductCategory initial;

  /// true = ditampilkan sebagai tab Toko (tanpa tombol kembali).
  final bool embedded;
  const ShopScreen({super.key, this.initial = ProductCategory.makanan, this.embedded = false});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ProductCategory _cat = widget.initial;

  @override
  void initState() {
    super.initState();
    app.refreshStock(); // pastikan angka stok terbaru
  }

  Widget _chip(ProductCategory c) {
    final sel = _cat == c;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _cat = c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kRed : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? kRed : kLine),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.icon, size: 17, color: sel ? Colors.white : kNavy),
            const SizedBox(width: 6),
            Text(c.label, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : kNavy)),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String t, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
      );

  void _openDetail(Product p) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(p)));

  Widget _card(Product p) {
    final left = app.stockOf(p);
    final out = left <= 0;
    final low = !out && left < kLowStock; // stok di bawah 5: tampilkan jumlahnya
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openDetail(p),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
        boxShadow: const [BoxShadow(color: Color(0x0F0B1F44), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Stack(children: [
            Container(
              height: 132,
              width: double.infinity,
              color: Colors.transparent,
              padding: const EdgeInsets.all(8),
              child: Opacity(opacity: out ? .4 : 1, child: ProductImage(p)),
            ),
            if (p.vehicleTag.isNotEmpty) Positioned(left: 8, top: 8, child: _badge(p.vehicleTag, kNavy)),
            if (low) Positioned(right: 8, top: 8, child: _badge('Sisa $left', kWarn)),
            if (out) Positioned.fill(child: Center(child: _badge('Stok habis', kError))),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2)),
              const SizedBox(height: 2),
              Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
              const SizedBox(height: 6),
              Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 14.5)),
              const Spacer(),
              _QtyControl(p),
            ]),
          ),
        ),
      ]),
    ),
      ),
    );
  }

  Widget _oilBanner() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
          color: const Color(0x1460BBE9),
          onTap: () {
            final nav = Navigator.of(context);
            nav.popUntil((r) => r.isFirst);
            app.requestTab(2, pack: oilChangePackage);
          },
          child: const Row(children: [
            Icon(Icons.build_circle_outlined, color: kNavy, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mau sekalian dipasangkan?', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Pesan jasa ganti oli di CleanDrive dan pilih oli langsung saat booking.',
                    style: TextStyle(fontSize: 12.5, color: kMuted)),
              ]),
            ),
            Icon(Icons.chevron_right, color: kMuted),
          ]),
        ),
      );

  Widget _cartBar() => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (app.cartCount == 0) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('${app.cartCount} item', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                        Text(rp(app.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      icon: const Icon(Icons.shopping_cart_rounded),
                      label: const Text('Keranjang'),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final list = productsIn(_cat).toList();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Toko CleanDrive'),
        actions: [
          ListenableBuilder(
            listenable: app,
            builder: (context, _) => Stack(alignment: Alignment.center, children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (app.cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10)),
                    child: Text('${app.cartCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final pad = pagePad(cons.maxWidth);
            return Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                child: Row(children: [for (final c in ProductCategory.values) _chip(c)]),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(pad, 0, pad, 16), children: [
                    if (_cat == ProductCategory.oli) _oilBanner(),
                    if (list.isEmpty)
                      const EmptyState(icon: Icons.search_off_rounded, title: 'Produk tidak ditemukan', message: 'Coba kata kunci lain.')
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 280,
                        ),
                        itemBuilder: (_, i) => _card(list[i]),
                      ),
                  ]),
                ),
              ),
            ]);
          }),
        ),
        _cartBar(),
      ]),
    );
  }
}

// ---------- DETAIL PRODUK ----------
/// Halaman detail produk: gambar besar, nama, harga, stok, deskripsi, informasi, dan tombol keranjang.
class ProductDetailScreen extends StatelessWidget {
  final Product p;
  const ProductDetailScreen(this.p, {super.key});

  Widget _chip(String t, {Color bg = const Color(0x1410264C), Color fg = kNavy, IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 5)],
          Text(t, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: kMuted, fontSize: 13.5))),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
        ]),
      );

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, size: 22, color: onTap == null ? kMuted : kRed)),
      );

  Widget _bottomBar(BuildContext context, int left) {
    final q = app.qtyOf(p);
    final out = left <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          if (q > 0) ...[
            Container(
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: kRed, width: 1.5)),
              child: Row(children: [
                _stepBtn(Icons.remove_rounded, () => app.setQty(p, q - 1)),
                SizedBox(width: 34, child: Center(child: Text('$q', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))),
                _stepBtn(Icons.add_rounded, q >= left ? null : () => app.setQty(p, q + 1)),
              ]),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: q == 0
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    onPressed: out ? null : () => app.setQty(p, 1),
                    icon: Icon(out ? Icons.block_rounded : Icons.add_shopping_cart_rounded),
                    label: Text(out ? 'Stok Habis' : 'Tambah ke Keranjang  •  ${rp(p.price)}'),
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                    icon: const Icon(Icons.shopping_cart_rounded),
                    label: Text('Lihat Keranjang  •  ${rp(app.cartTotal)}'),
                  ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Produk'),
          actions: [
            ListenableBuilder(
              listenable: app,
              builder: (context, _) => Stack(alignment: Alignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                ),
                if (app.cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10)),
                      child: Text('${app.cartCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final left = app.stockOf(p);
            final out = left <= 0;
            final low = !out && left < kLowStock;
            return Column(children: [
              Expanded(
                child: LayoutBuilder(builder: (context, cons) {
                  final pad = pagePad(cons.maxWidth);
                  return ListView(padding: EdgeInsets.fromLTRB(pad, 4, pad, 20), children: [
                    Panel(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Opacity(opacity: out ? .45 : 1, child: ProductImage(p, height: 300, cacheWidth: 900)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _chip(p.category.label, icon: p.category.icon),
                          if (p.vehicleTag.isNotEmpty) _chip('Untuk ${p.vehicleTag}', icon: Icons.directions_car_filled_rounded),
                          if (out)
                            _chip('Stok habis', bg: const Color(0x1AD92D35), fg: kError, icon: Icons.block_rounded)
                          else if (low)
                            _chip('Sisa $left', bg: const Color(0x1AE9A23B), fg: kWarn, icon: Icons.warning_amber_rounded)
                          else
                            _chip('Tersedia', bg: const Color(0x1A249B62), fg: kGreen, icon: Icons.check_circle_outline_rounded),
                        ]),
                        const SizedBox(height: 14),
                        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 6),
                        Text(p.desc, style: const TextStyle(color: kMuted, fontSize: 14)),
                        const SizedBox(height: 12),
                        Text(rp(p.price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kRed)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text(p.details, style: const TextStyle(fontSize: 14.5, height: 1.55)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Informasi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        _infoRow('Nama produk', p.name),
                        const Divider(height: 1, color: kLine),
                        _infoRow('Kategori', p.category.label),
                        const Divider(height: 1, color: kLine),
                        _infoRow('Ringkasan', p.desc),
                        if (p.vehicleTag.isNotEmpty) ...[
                          const Divider(height: 1, color: kLine),
                          _infoRow('Cocok untuk', p.vehicleTag),
                        ],
                        const Divider(height: 1, color: kLine),
                        _infoRow('Ketersediaan', out ? 'Stok habis' : (low ? 'Sisa $left item' : 'Tersedia')),
                        const Divider(height: 1, color: kLine),
                        _infoRow('Harga', rp(p.price)),
                      ]),
                    ),
                  ]);
                }),
              ),
              _bottomBar(context, left),
            ]);
          },
        ),
      );
}

// ---------- KERANJANG ----------
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Widget _line(Product p, int qty) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: ProductImage(p),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(rp(p.price), style: const TextStyle(color: kMuted, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(rp(p.price * qty), style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              ]),
            ),
            SizedBox(width: 108, child: _QtyControl(p)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Keranjang')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            if (app.cart.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_cart_outlined, size: 56, color: kMuted),
                    const SizedBox(height: 10),
                    const Text('Keranjang masih kosong', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Lihat Produk')),
                  ]),
                ),
              );
            }
            // Selebar layar penuh: PageList dan bilah bawah memusatkan isinya sendiri lewat pagePad.
            return PageBox(
              maxWidth: double.infinity,
              child: Column(children: [
                Expanded(
                  child: PageList(top: 16, children: [
                    AutoGrid(minWidth: 440, gap: 0, children: [for (final l in app.cart) _line(l.product, l.qty)]),
                    const SizedBox(height: 4),
                    const Row(children: [
                      Icon(Icons.storefront_outlined, size: 16, color: kMuted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Beli langsung: bayar di aplikasi, lalu ambil barang di kasir CleanDrive dengan menunjukkan nomor pembelian.',
                            style: TextStyle(color: kMuted, fontSize: 12.5)),
                      ),
                    ]),
                  ]),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(pagePad(MediaQuery.sizeOf(context).width), 12, pagePad(MediaQuery.sizeOf(context).width), 12),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
                  child: SafeArea(
                    top: false,
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text('${app.cartCount} item', style: const TextStyle(fontSize: 12.5, color: kMuted)),
                          Text(rp(app.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22)),
                        onPressed: () {
                          final now = DateTime.now();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmOrderScreen(
                                vehicle: VehicleType.mobil,
                                pack: shopPackage,
                                plate: '',
                                slot: now,
                                estimate: now.add(Duration(minutes: shopPackage.minutes)),
                                items: List.of(app.cart),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_rounded),
                        label: const Text('Beli Sekarang'),
                      ),
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
      );
}

// ---------- CUPLIKAN TOKO DI BERANDA ----------
class ShopHomeSection extends StatelessWidget {
  /// Dipanggil saat "Lihat Semua" ditekan (beranda membukanya sebagai tab Toko).
  final VoidCallback? onSeeAll;
  const ShopHomeSection({super.key, this.onSeeAll});

  Widget _mini(BuildContext context, Product p) => SizedBox(
        width: 176,
        child: Panel(
          padding: const EdgeInsets.all(12),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(p))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: ProductImage(p),
            ),
            const SizedBox(height: 8),
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.2)),
            const Spacer(),
            Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 15)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final picks = [
      for (final c in ProductCategory.values) ...productsIn(c).take(c == ProductCategory.oli ? 2 : 3),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sec('Toko CleanDrive',
          trailing: TextButton(
            onPressed: onSeeAll ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
            child: const Text('Lihat Semua'),
          )),
      SizedBox(
        height: 236,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: picks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _mini(context, picks[i]),
        ),
      ),
    ]);
  }
}