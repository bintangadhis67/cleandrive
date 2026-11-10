import 'package:flutter/material.dart';

import 'app_state.dart';
import 'catalog.dart';
import 'customer.dart' show ConfirmOrderScreen;
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Gambar produk (dengan cadangan ikon bila file tidak ada).
class ProductImage extends StatelessWidget {
  final Product p;
  final double? height;
  const ProductImage(this.p, {super.key, this.height});

  @override
  Widget build(BuildContext context) => Image.asset(
        p.image,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: 400,
        errorBuilder: (_, __, ___) => Icon(p.category.icon, size: 40, color: kMuted),
      );
}

/// Tombol tambah / pengatur jumlah.
class _QtyControl extends StatelessWidget {
  final Product p;
  const _QtyControl(this.p);

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 20, color: kRed)),
      );

  @override
  Widget build(BuildContext context) {
    final q = app.qtyOf(p);
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
          onPressed: () => app.setQty(p, 1),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah', style: TextStyle(fontSize: 13)),
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
        _btn(Icons.add_rounded, () => app.setQty(p, q + 1)),
      ]),
    );
  }
}

// ---------- TOKO ----------
class ShopScreen extends StatefulWidget {
  final ProductCategory initial;
  const ShopScreen({super.key, this.initial = ProductCategory.makanan});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ProductCategory _cat = widget.initial;

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

  Widget _card(Product p) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kLine),
          boxShadow: const [BoxShadow(color: Color(0x0F0B1F44), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(
              height: 132,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF1F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.all(8),
              child: ProductImage(p),
            ),
            if (p.vehicleTag.isNotEmpty)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(10)),
                  child: Text(p.vehicleTag, style: const TextStyle(color: kCream, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2)),
              const SizedBox(height: 2),
              Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
              const SizedBox(height: 6),
              Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 14.5)),
              const SizedBox(height: 8),
              _QtyControl(p),
            ]),
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  icon: const Icon(Icons.shopping_cart_rounded),
                  label: const Text('Keranjang'),
                ),
              ]),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final list = productsIn(_cat).toList();
    return Scaffold(
      appBar: AppBar(
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [for (final c in ProductCategory.values) _chip(c)]),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: app,
                builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
                  if (_cat == ProductCategory.oli) _oilBanner(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 300,
                    ),
                    itemBuilder: (_, i) => _card(list[i]),
                  ),
                ]),
              ),
            ),
            _cartBar(),
          ]),
        ),
      ),
    );
  }
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
              decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(12)),
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
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(children: [
                  Expanded(
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      for (final l in app.cart) _line(l.product, l.qty),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.storefront_outlined, size: 16, color: kMuted),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Pesanan diambil di kasir CleanDrive dengan menunjukkan tiket QR.',
                              style: TextStyle(color: kMuted, fontSize: 12.5)),
                        ),
                      ]),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Checkout'),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      );
}

// ---------- CUPLIKAN TOKO DI BERANDA ----------
class ShopHomeSection extends StatelessWidget {
  const ShopHomeSection({super.key});

  Widget _mini(BuildContext context, Product p) => SizedBox(
        width: 124,
        child: Panel(
          padding: const EdgeInsets.all(8),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(initial: p.category))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: ProductImage(p),
            ),
            const SizedBox(height: 6),
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.2)),
            const Spacer(),
            Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 12.5)),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
            child: const Text('Lihat Semua'),
          )),
      SizedBox(
        height: 172,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: picks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _mini(context, picks[i]),
        ),
      ),
    ]);
  }
}
