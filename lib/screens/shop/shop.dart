import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../home/customer.dart' show ConfirmOrderScreen;
import '../rewards/reward_ui.dart';

/// Gambar produk (dengan cadangan ikon bila file tidak ada).
class ProductImage extends StatelessWidget {
  final Product p;
  final double? height;
  final int cacheWidth;
  const ProductImage(this.p, {super.key, this.height, this.cacheWidth = 400});

  @override
  Widget build(BuildContext context) => p.image.startsWith('http')
      ? Image.network(
          p.image,
          height: height,
          fit: BoxFit.contain,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => Icon(p.category.icon, size: (height ?? 100) * .4, color: kMuted),
        )
      : Image.asset(
        p.image,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Icon(p.category.icon, size: (height ?? 100) * .4, color: kMuted),
      );
}

/// Tombol tambah / pengatur jumlah (dibatasi oleh stok).
/// Jumlah 0 = tombol "+" merah bulat; jumlah > 0 = stepper kapsul (- jumlah +).
class _QtyControl extends StatelessWidget {
  final Product p;
  const _QtyControl(this.p);

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 20, color: onTap == null ? kRwSub : kRed)),
      );

  @override
  Widget build(BuildContext context) {
    final q = app.qtyOf(p);
    final left = app.stockOf(p);
    if (q == 0) {
      final off = left <= 0;
      return Tooltip(
        message: 'Tambah',
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: off ? kRwBlueSoft : kRed,
            boxShadow: off ? null : const [BoxShadow(color: Color(0x44C62026), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: off ? null : () => app.setQty(p, 1),
              child: Icon(Icons.add_rounded, size: 22, color: off ? kRwSub : Colors.white),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: kRed, width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _btn(Icons.remove_rounded, () => app.setQty(p, q - 1)),
        Text('$q', style: const TextStyle(fontWeight: FontWeight.w800, color: kRwText)),
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
  final _search = TextEditingController();
  String _query = ''; // kata kunci pencarian (huruf kecil)

  @override
  void initState() {
    super.initState();
    app.refreshStock(); // pastikan angka stok terbaru
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Kolom pencarian putih membulat di bawah judul header.
  Widget _searchBar() => Container(
        height: 48,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: kRwShadowThin),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: kRwText, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'Cari produk di toko...',
            hintStyle: const TextStyle(color: kRwSub, fontSize: 14.5),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            suffixIcon: _query.isEmpty
                ? const Icon(Icons.search_rounded, color: kRwSub)
                : IconButton(
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.close_rounded, color: kRwSub, size: 20),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      );

  /// Pil kategori di header: aktif = MERAH + teks putih, tidak aktif = transparan + garis putih.
  Widget _chip(ProductCategory c) {
    final sel = _cat == c;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _cat = c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? kRed : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sel ? kRed : Colors.white.withValues(alpha: .75), width: 1.4),
            boxShadow: sel ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 12, offset: Offset(0, 4))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(c.icon, size: 17, color: Colors.white),
            const SizedBox(width: 6),
            Text(c.label, style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600, fontSize: 13.5, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  /// Tombol bulat transparan di header (kembali / keranjang).
  Widget _headerCircle(IconData icon, String tip, VoidCallback onTap, {int badge = 0}) => Tooltip(
        message: tip,
        child: Stack(clipBehavior: Clip.none, children: [
          Material(
            color: Colors.white.withValues(alpha: .12),
            shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: .25))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white, size: 25)),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                child: Text(badge > 99 ? '99+' : '$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );

  /// Header gradasi navy-royal seperti halaman Riwayat: judul, deskripsi, keranjang, dan pil kategori.
  Widget _header(BuildContext context, double pad) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyDark, kRwNavy, kRwNavyLight]),
        boxShadow: [BoxShadow(color: Color(0x4007347F), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _ShopWavePainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(0, top + 16, 0, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  if (!widget.embedded) ...[
                    _headerCircle(Icons.chevron_left_rounded, 'Kembali', () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                  ],
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Toko CleanDrive', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                      SizedBox(height: 3),
                      Text('Makanan, minuman, dan oli pilihan, bisa diambil langsung di kasir.',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  ListenableBuilder(
                    listenable: app,
                    builder: (context, _) => _headerCircle(
                      Icons.shopping_cart_outlined,
                      'Keranjang',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      badge: app.cartCount,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: _searchBar()),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: Row(children: [for (final c in ProductCategory.values) _chip(c)]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String t, Color bg, {Color fg = Colors.white}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800)),
      );

  void _openDetail(Product p) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(p)));

  /// Area beli di bawah kartu:
  /// - stok habis: harga + batang abu-abu nonaktif,
  /// - belum di keranjang: harga di kiri, tombol "+" merah di kanan,
  /// - sudah di keranjang: harga lalu stepper jumlah selebar kartu.
  Widget _buyArea(Product p, int left) {
    final q = app.qtyOf(p);
    final price = Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRwNavy, fontSize: 14.5));
    if (left <= 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        price,
        const SizedBox(height: 8),
        Container(
          height: 34,
          width: double.infinity,
          decoration: BoxDecoration(color: kRwBlueSoft, borderRadius: BorderRadius.circular(17)),
          child: const Icon(Icons.block_rounded, size: 18, color: kRwSub),
        ),
      ]);
    }
    if (q == 0) {
      return Row(children: [
        Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: price)),
        const SizedBox(width: 8),
        _QtyControl(p),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      price,
      const SizedBox(height: 8),
      _QtyControl(p),
    ]);
  }

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
            borderRadius: BorderRadius.circular(20),
            boxShadow: kRwShadowThin,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(children: [
                Container(
                  height: 124,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Opacity(opacity: out ? .4 : 1, child: ProductImage(p)),
                ),
                if (p.vehicleTag.isNotEmpty) Positioned(left: 8, top: 8, child: _badge(p.vehicleTag, kRwNavy)),
                if (low) Positioned(right: 8, top: 8, child: _badge('Sisa $left', kRwGold, fg: kRwText)),
                if (out) Positioned.fill(child: Center(child: _badge('Stok Habis', kRwDanger))),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2, color: kRwText)),
                  const SizedBox(height: 2),
                  Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kRwSub, fontSize: 11.5)),
                  const Spacer(),
                  _buyArea(p, left),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Catatan kecil di akhir daftar produk.
  Widget _outletNote() => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: kRwBlueSoft, borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          Icon(Icons.info_rounded, size: 18, color: kRwNavyLight),
          SizedBox(width: 10),
          Expanded(child: Text('Produk yang tersedia dapat berbeda di setiap outlet.', style: TextStyle(color: kRwText, fontSize: 12.5))),
        ]),
      );

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
                      style: FilledButton.styleFrom(backgroundColor: kRed, padding: const EdgeInsets.symmetric(horizontal: 22)),
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
    final list = productsIn(_cat)
        .where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query) || p.desc.toLowerCase().contains(_query))
        .toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // ikon status bar putih karena header berwarna gelap
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kRwBg, kRwBg]),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false, // header tetap utuh saat keyboard pencarian muncul
          body: LayoutBuilder(builder: (context, cons) {
            final pad = pagePad(cons.maxWidth);
            return Column(children: [
              _header(context, pad),
              Expanded(
                child: ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => ListView(padding: EdgeInsets.fromLTRB(pad, 16, pad, 16), children: [
                    if (_cat == ProductCategory.oli) _oilBanner(),
                    if (list.isEmpty)
                      const EmptyState(icon: Icons.search_off_rounded, title: 'Produk tidak ditemukan', message: 'Coba kata kunci lain.')
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 282,
                        ),
                        itemBuilder: (_, i) => _card(list[i]),
                      ),
                    if (list.isNotEmpty) _outletNote(),
                  ]),
                ),
              ),
              _cartBar(),
            ]);
          }),
        ),
      ),
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

  /// Tombol bulat kecil untuk mengubah jumlah.
  Widget _stepBtn(IconData icon, VoidCallback? onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap == null ? kRwBlueSoft : Colors.white,
            border: Border.all(color: onTap == null ? kRwLine : kRwNavy, width: 1.2),
          ),
          child: Icon(icon, size: 17, color: onTap == null ? kRwSub : kRwNavy),
        ),
      );

  Widget _line(Product p, int qty) {
    final left = app.stockOf(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RwCard(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: kRwBlueSoft.withValues(alpha: .6), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(6),
            child: ProductImage(p),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(p.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.25, color: kRwText)),
                ),
                const SizedBox(width: 6),
                // hapus produk dari keranjang
                Tooltip(
                  message: 'Hapus',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => app.setQty(p, 0),
                    child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.delete_outline_rounded, size: 22, color: kRwDanger)),
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Text(rp(p.price), style: const TextStyle(color: kRwSub, fontSize: 12.5)),
              const SizedBox(height: 8),
              Row(children: [
                _stepBtn(Icons.remove_rounded, () => app.setQty(p, qty - 1)),
                SizedBox(width: 34, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kRwText)))),
                _stepBtn(Icons.add_rounded, qty >= left ? null : () => app.setQty(p, qty + 1)),
                const Spacer(),
                Text(rp(p.price * qty), style: const TextStyle(color: kRwNavy, fontWeight: FontWeight.w800, fontSize: 14.5)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Ilustrasi keranjang kosong dari bentuk sederhana (tanpa file gambar baru).
  Widget _emptyIllustration() => SizedBox(
        width: 150,
        height: 130,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: kRwBlueSoft.withValues(alpha: .8)),
          ),
          const Positioned(left: 6, top: 18, child: Icon(Icons.eco_rounded, size: 26, color: Color(0xFFB9CBEA))),
          const Positioned(right: 4, bottom: 20, child: Icon(Icons.eco_rounded, size: 22, color: Color(0xFFB9CBEA))),
          const Icon(Icons.shopping_cart_outlined, size: 70, color: kRwNavy),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: AppBar(
          title: const Text('Keranjang'),
          centerTitle: true,
          backgroundColor: kRwBg,
          foregroundColor: kRwText,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded, color: kRwText),
            onPressed: () => Navigator.maybePop(context),
          ),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            if (app.cart.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _emptyIllustration(),
                    const SizedBox(height: 16),
                    const Text('Keranjang masih kosong', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: kRwText)),
                    const SizedBox(height: 6),
                    const Text('Yuk, pilih produk favoritmu\ndi Toko CleanDrive.', textAlign: TextAlign.center, style: TextStyle(color: kRwSub, fontSize: 13.5, height: 1.4)),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Lihat Produk'),
                      ),
                    ),
                  ]),
                ),
              );
            }
            return PageBox(
              maxWidth: double.infinity,
              child: Column(children: [
                Expanded(
                  child: PageList(top: 8, bottom: 16, children: [
                    for (final l in app.cart) _line(l.product, l.qty),
                    const SizedBox(height: 2),
                    // ringkasan pembayaran
                    RwCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        rwCardTitle('Ringkasan'),
                        rwKv('Subtotal (${app.cartCount} item)', rp(app.cartTotal)),
                        rwDivider(v: 8),
                        Row(children: [
                          const Expanded(child: Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwText))),
                          Text(rp(app.cartTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: kRwNavy)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.storefront_outlined, size: 16, color: kRwSub),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Beli langsung: bayar di aplikasi, lalu ambil barang di kasir CleanDrive dengan menunjukkan nomor pembelian.',
                            style: TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4)),
                      ),
                    ]),
                  ]),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(pagePad(MediaQuery.sizeOf(context).width), 12, pagePad(MediaQuery.sizeOf(context).width), 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Color(0x1A07347F), blurRadius: 18, offset: Offset(0, -6))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: RwButton('Lanjut ke Pembayaran', icon: Icons.arrow_forward_rounded, onPressed: () {
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
                    }),
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

/// Gelombang abstrak lembut di header Toko (kanan atas, kanan bawah, dan aksen gold).
class _ShopWavePainter extends CustomPainter {
  const _ShopWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = Path()
      ..moveTo(w * .62, 0)
      ..cubicTo(w * .78, h * .05, w * .90, h * .42, w, h * .30)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(a, Paint()..color = Colors.white.withValues(alpha: .07));
    final b = Path()
      ..moveTo(w * .58, h)
      ..cubicTo(w * .74, h * .62, w * .88, h * .62, w, h * .40)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(b, Paint()..color = Colors.white.withValues(alpha: .10));
    final c = Path()
      ..moveTo(w * .80, h)
      ..cubicTo(w * .88, h * .78, w * .94, h * .74, w, h * .66)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(c, Paint()..color = const Color(0x40FFB91F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}