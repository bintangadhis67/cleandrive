import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/loyalty_models.dart';
import '../../models/models.dart';
import '../../models/notification_models.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../notifications/notifications.dart';
import '../orders/orders.dart';
import '../outlet/outlet.dart';
import '../payment/payment.dart';
import '../profile/akun_tab.dart';
import '../rewards/reward_ui.dart';
import '../shop/shop.dart';
import 'beranda_tab.dart';
import 'booking_screen.dart';

typedef GoFn = void Function(int, {WashPackage? pack, VehicleType? vehicle, Product? oil});


// ---------- HOME KONSUMEN ----------
// HP (< 720px): menu bawah + tombol Booking di tengah.
// Tablet / laptop (>= 720px): menu samping (NavigationRail). Isi selalu selebar layar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0; // 0 Beranda, 1 Riwayat, 2 Booking, 3 Toko, 4 Akun
  WashPackage? _pack;
  VehicleType? _vehicle;
  Product? _oil;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    app.addListener(_onApp);
    // Pengganti push notification: cek notifikasi baru berkala (dengan backend sungguhan,
    // bagian ini diganti Firebase Cloud Messaging).
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => app.refreshNotifications());
  }

  @override
  void dispose() {
    _poll?.cancel();
    app.removeListener(_onApp);
    super.dispose();
  }

  /// Layar lain (voucher, pembayaran, toko) bisa meminta pindah tab lewat app.requestTab().
  void _onApp() {
    final t = app.requestedTab;
    if (t != null) {
      final p = app.requestedPack, v = app.requestedVehicle, o = app.requestedOil;
      app.requestedTab = null;
      app.requestedPack = null;
      app.requestedVehicle = null;
      app.requestedOil = null;
      if (mounted) {
        setState(() {
          _idx = t;
          _pack = p;
          _vehicle = v;
          _oil = o;
        });
      }
    }
    final n = app.banner;
    if (n != null) {
      app.banner = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showBanner(n);
      });
    }
  }

  /// Banner notifikasi di dalam aplikasi: popup di atas layar, ketuk untuk membuka.
  void _showBanner(AppNotification n) {
    showTopToast(
      context,
      title: n.title,
      subtitle: n.body,
      accent: n.type.color == const Color(0xFFD08A00) ? kGold : n.type.color,
      duration: const Duration(seconds: 6),
      actionLabel: 'Lihat',
      onTap: () => openNotification(context, n),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .14)),
        child: Icon(n.type.icon, color: kGold, size: 23),
      ),
    );
  }

  void _go(int i, {WashPackage? pack, VehicleType? vehicle, Product? oil}) => setState(() {
        _idx = i;
        _pack = pack;
        _vehicle = vehicle;
        _oil = oil;
      });

  Widget _body() {
    final Widget page;
    switch (_idx) {
      case 0:
        page = BerandaTab(onGo: _go);
      case 1:
        page = const OrdersScreen();
      case 2:
        page = BookingScreen(
          key: ValueKey('${_pack?.name}-${_vehicle?.name}-${_oil?.id}'),
          initialPack: _pack,
          initialVehicle: _vehicle,
          initialOil: _oil,
          onBack: () => _go(0),
        );
      case 3:
        page = const ShopScreen(embedded: true);
      default:
        page = AkunTab(onGo: _go);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      // Pindah tab: halaman baru memudar sambil bergeser tipis dari kanan.
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_idx), child: page),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final on = _idx == i;
    final c = on ? kRed : kRwSub;
    return Expanded(
      child: Pressable(
        scale: 0.9,
        child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _go(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c, size: 26),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: c)),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? 30 : 0,
            height: 3,
            decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(3)),
          ),
        ]),
      )),
    );
  }

  /// Menu bawah melayang (pill) dengan tombol Booking menonjol di tengah.
  Widget _floatingNav() {
    final pad = pagePad(MediaQuery.sizeOf(context).width);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 0, pad, 10),
        child: SizedBox(
          height: 80,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            Container(
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(33),
                boxShadow: const [BoxShadow(color: Color(0x2610264C), blurRadius: 26, offset: Offset(0, 10))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _navItem(0, Icons.home_rounded, 'Beranda'),
                _navItem(1, Icons.history_rounded, 'Riwayat'),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text('Booking',
                          style: TextStyle(
                              fontSize: 11, fontWeight: _idx == 2 ? FontWeight.w700 : FontWeight.w500, color: _idx == 2 ? kRed : kRwSub)),
                    ),
                  ),
                ),
                _navItem(3, Icons.storefront_rounded, 'Toko'),
                _navItem(4, Icons.person_rounded, 'Akun'),
              ]),
            ),
            Positioned(
              top: 0,
              child: Pressable(
                scale: 0.9,
                child: GestureDetector(
                onTap: () => _go(2),
                child: Container(
                  width: 58,
                  height: 58,
                  // Lingkaran navy blue; status aktif ditandai label Booking berwarna merah.
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyLight, kRwNavy]),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x6607347F), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 30),
                ),
              )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _phoneShell() => Scaffold(
        body: SafeArea(top: false, bottom: false, child: _body()), // semua tab punya header gradasi yang menembus status bar
        bottomNavigationBar: _floatingNav(),
      );

  @override
  Widget build(BuildContext context) => _phoneShell(); // Boxed Layout: satu tampilan untuk semua lebar layar
}

// ---------- KONFIRMASI PESANAN ----------
// Total = harga - diskon membership - voucher. Coins ditukar di langkah pembayaran (bukan di sini).
class ConfirmOrderScreen extends StatefulWidget {
  final VehicleType vehicle;
  final WashPackage pack;
  final String plate;
  final DateTime slot, estimate;
  final List<OrderLine> items;
  const ConfirmOrderScreen({
    super.key,
    required this.vehicle,
    required this.pack,
    required this.plate,
    required this.slot,
    required this.estimate,
    this.items = const [],
  });
  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  Voucher? _voucher;
  bool _busy = false;
  bool _useFree = false; // pakai jatah cuci gratis membership (total Rp 0, tidak bisa digabung voucher/diskon/Coins)
  bool _withService = false; // pembelian oli: pakai jasa penggantian oli?

  // ----- pembelian oli di toko: opsi jasa penggantian -----
  List<OrderLine> get _oilLines => widget.items.where((l) => l.product.category == ProductCategory.oli).toList();
  bool get _hasOil => widget.pack.isShop && _oilLines.isNotEmpty;

  /// Jasa penggantian hanya untuk tepat 1 oli (jumlah 1), karena satu booking = satu penggantian.
  bool get _serviceEligible => _oilLines.length == 1 && _oilLines.first.qty == 1;
  bool get _serviceMode => _hasOil && _withService && _serviceEligible;

  VehicleType _oilVehicle(Product p) => p.vehicles.isEmpty ? VehicleType.mobil : p.vehicles.first;
  int get _serviceFee => oilChangePackage.priceFor(_oilVehicle(_oilLines.first.product));

  /// Oli dipindah dari keranjang ke booking jasa, lalu pengguna memilih jadwal.
  void _goService() {
    final line = _oilLines.first;
    final v = _oilVehicle(line.product);
    final nav = Navigator.of(context);
    app.setQty(line.product, 0);
    toast(context, 'Oli dipindah ke booking jasa. Pilih jadwal untuk melanjutkan.');
    nav.popUntil((r) => r.isFirst);
    app.requestTab(2, pack: oilChangePackage, vehicle: v, oil: line.product);
  }

  Widget _choiceTile({
    required bool selected,
    required bool enabled,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? kRwBlueSoft : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? kRwNavy : kRwLine, width: selected ? 1.8 : 1),
            ),
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: selected ? kRwNavy : kRwNavyLight, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kRwText)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.3)),
                  ]),
                ),
                const SizedBox(width: 8),
                Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? kRwNavy : kRwSub),
              ]),
            ),
          ),
        ),
      );

  Widget _servicePanel() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const RwSectionTitle('Jasa Penggantian Oli'),
        _choiceTile(
          selected: !_serviceMode,
          enabled: true,
          icon: Icons.storefront_rounded,
          title: 'Beli oli saja',
          subtitle: 'Tanpa jasa. Oli diambil di kasir ${kOutlet.name}.',
          onTap: () => setState(() => _withService = false),
        ),
        _choiceTile(
          selected: _serviceMode,
          enabled: _serviceEligible,
          icon: Icons.build_circle_rounded,
          title: 'Beli oli + jasa penggantian',
          subtitle: _serviceEligible
              ? 'Dipasang teknisi CleanDrive. Jasa ${rp(_serviceFee)}, lalu pilih jadwal dan nomor polisi di langkah berikutnya.'
              : 'Jasa hanya untuk 1 oli. Kurangi jumlah oli di keranjang menjadi 1.',
          onTap: () => setState(() => _withService = true),
        ),
      ]);

  /// Ringkasan bila memilih oli + jasa (pembayaran dilakukan setelah memilih jadwal).
  List<Widget> _serviceSummary() {
    final oil = _oilLines.first.product;
    return [
      RwCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          rwCardTitle('Perkiraan Biaya'),
          rwKv(oil.name, rp(oil.price)),
          rwKv('Jasa penggantian (${_oilVehicle(oil).label})', rp(_serviceFee)),
          rwDivider(v: 12),
          Row(children: [
            const Expanded(child: Text('Perkiraan Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kRwText))),
            Text(rp(oil.price + _serviceFee), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: kRwNavy)),
          ]),
          const SizedBox(height: 10),
          const Text('Voucher dan diskon membership dihitung di konfirmasi booking. Pembayaran setelah jadwal dipilih.',
              style: TextStyle(color: kRwSub, fontSize: 12.5, height: 1.35)),
        ]),
      ),
    ];
  }

  int get _servicePrice => widget.pack.priceFor(widget.vehicle);
  int get _itemsTotal => widget.items.fold(0, (s, l) => s + l.subtotal);
  int get _price => _servicePrice + _itemsTotal;
  int get _voucherDiscount => _useFree ? 0 : (_voucher?.discountFor(_price) ?? 0);

  /// Cuci gratis hanya untuk paket cuci (bukan toko / ganti oli) milik member yang paketnya punya jatah cuci gratis.
  bool get _showFreePanel =>
      !widget.pack.isShop &&
      widget.pack.kind == ServiceKind.wash &&
      app.membership.hasActive &&
      app.membership.current!.plan.hasFreeWash;

  /// Alasan cuci gratis tidak bisa dipakai untuk pesanan ini (null = bisa).
  String? get _freeBlock => app.membership.freeWashBlock(widget.pack, widget.vehicle, widget.slot);

  /// Diskon membership aktif hanya untuk jasa layanan (bukan pembelian toko). Server menghitung ulang.
  int get _memberDiscount {
    if (widget.pack.isShop) return 0;
    if (_useFree) return _price; // cuci gratis: seluruh harga ditanggung membership
    final d = app.memberDiscountFor(_servicePrice);
    final cap = _price - _voucherDiscount;
    return d > cap ? cap : d;
  }

  int get _total => _price - _voucherDiscount - _memberDiscount;

  @override
  void initState() {
    super.initState();
    final ok = app.usableVouchers.where((v) => v.eligible(_price)).toList();
    final pend = app.pendingVoucher;
    if (pend != null && ok.any((v) => v.id == pend.id)) {
      _voucher = ok.firstWhere((v) => v.id == pend.id);
    } else if (ok.isNotEmpty) {
      ok.sort((a, b) => b.discountFor(_price).compareTo(a.discountFor(_price)));
      _voucher = ok.first; // otomatis pakai voucher paling hemat
    }
    // Bila jatah cuci gratis tersedia, otomatis dipakai (voucher tidak bisa digabung).
    if (_showFreePanel && _freeBlock == null) {
      _useFree = true;
      _voucher = null;
    }
  }

  /// Kartu cuci gratis membership: saklar bila tersedia, atau alasan kenapa belum bisa dipakai.
  Widget _freeWashPanel() {
    final m = app.membership.current!;
    final plan = m.plan;
    final block = _freeBlock;
    final ok = block == null;
    return RwCard(
      color: ok ? const Color(0xFFEAF6F0) : Colors.white,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.card_giftcard_rounded : Icons.info_outline_rounded, color: ok ? kRwGreen : kRwSub),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ok ? 'Pakai Cuci Gratis ${plan.name}' : 'Cuci Gratis ${plan.name}', style: const TextStyle(fontWeight: FontWeight.w800, color: kRwText)),
            const SizedBox(height: 2),
            Text(
              ok
                  ? 'Sisa ${m.freeLeft} jatah ${plan.freePackage} Wash • maksimal 1x per minggu. Total jadi Rp 0 dan tidak bisa digabung voucher atau Coins.'
                  : block,
              style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.35),
            ),
          ]),
        ),
        if (ok)
          Switch(
            value: _useFree,
            activeThumbColor: Colors.white,
            activeTrackColor: kRwGreen,
            onChanged: (v) => setState(() {
              _useFree = v;
              if (v) _voucher = null;
            }),
          ),
      ]),
    );
  }

  Future<void> _pickVoucher() async {
    if (_useFree) {
      toast(context, 'Voucher tidak bisa digabung dengan cuci gratis membership.', error: true);
      return;
    }
    final claimed = app.vouchers.where((v) => v.claimed).toList();
    final picked = await showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      // Pop up muncul di BAGIAN ATAS layar.
      pageBuilder: (ctx, _, __) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(ctx).size.height * .8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Expanded(child: Text('Pilih voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                    ]),
                    const SizedBox(height: 6),
                    if (claimed.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Kamu belum punya voucher. Klaim voucher di beranda.', style: TextStyle(color: kMuted)),
                      ),
                    for (final v in claimed)
                      Builder(builder: (_) {
                        final reason = v.used
                            ? 'Sudah dipakai'
                            : (v.expired ? 'Kedaluwarsa' : (!v.eligible(_price) ? 'Min. transaksi ${rp(v.minTransaction)}' : null));
                        return ListTile(
                          enabled: reason == null,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_offer_rounded, color: kRed),
                          title: Text(v.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(reason ?? 'Hemat ${rp(v.discountFor(_price))}'),
                          trailing: _voucher?.id == v.id ? const Icon(Icons.check_circle, color: kRed) : null,
                          onTap: reason == null ? () => Navigator.pop(ctx, v) : null,
                        );
                      }),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block, color: kMuted),
                      title: const Text('Tanpa voucher'),
                      onTap: () => Navigator.pop(ctx, 'none'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _voucher = picked is Voucher ? picked : null);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final b = await guard(
      context,
      () => app.create(
        vehicle: widget.vehicle,
        pack: widget.pack,
        plate: widget.plate,
        slot: widget.slot,
        voucherCode: _useFree ? null : _voucher?.code,
        items: widget.items,
        useFreeWash: _useFree,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (b == null) return;
    final nav = Navigator.of(context);
    app.requestTab(1);
    nav.popUntil((r) => r.isFirst);
    if (b.freeWash) {
      // Cuci gratis sudah lunas otomatis: langsung ke detail pesanan (tiket).
      toast(context, 'Cuci gratis membership dipakai. Pesananmu sudah aktif.');
      nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: b.id)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => PaymentMethodScreen(bookingId: b.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estCoins = coinsForPayment(shop: widget.pack.isShop, paid: _total);
    final pack = widget.pack;
    final mem = app.membership;
    return Scaffold(
      backgroundColor: kRwBg,
      appBar: AppBar(
        title: Text(pack.isShop ? 'Konfirmasi Pembelian' : 'Konfirmasi Pesanan'),
        backgroundColor: kRwBg,
        foregroundColor: kRwText,
        iconTheme: const IconThemeData(color: kRwText),
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
      ),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            leftFlex: 5,
            rightFlex: 6,
            left: [
              RwCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  rwCardTitle('Detail Pesanan'),
                  if (pack.isShop) ...[
                    rwKv('Jenis', 'Pembelian Langsung'),
                    rwKv('Jumlah', '${widget.items.fold(0, (s, l) => s + l.qty)} item'),
                    rwKv('Ambil di', 'Kasir ${kOutlet.name}'),
                  ] else ...[
                    rwKv(pack.isOil ? 'Layanan' : 'Paket', pack.title),
                    rwKv('Kendaraan', widget.vehicle.label),
                    rwKv('Nomor Polisi', widget.plate.toUpperCase()),
                    rwKv('Lokasi', '${kOutlet.name}, ${kOutlet.shortAddress}'),
                    rwKv('Tanggal', fmtDate.format(widget.slot)),
                    rwKv('Jam', '${fmtHm.format(widget.slot)} WIB'),
                    rwKv('Estimasi Selesai', '${fmtHm.format(widget.estimate)} WIB'),
                  ],
                ]),
              ),
              if (_hasOil) _servicePanel(),
            ],
            right: [
              const SizedBox(height: 14),
              if (_serviceMode) ..._serviceSummary() else ...[
                if (_showFreePanel) ...[_freeWashPanel(), const SizedBox(height: 14)],
                RwCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    rwCardTitle('Rincian Pembayaran'),
                    if (widget.items.isNotEmpty) ...[
                      if (!pack.isShop) rwKv(pack.title, rp(_servicePrice)),
                      for (final l in widget.items) rwKv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
                      rwDivider(v: 8),
                    ],
                    rwKv('Total Harga', rp(_price), bold: true),
                    if (!pack.isShop)
                      rwKv(
                        _useFree
                            ? 'Cuci Gratis ${mem.current!.plan.name}'
                            : (mem.hasActive ? 'Diskon Membership ${mem.current!.plan.name} ${mem.current!.plan.discountPct}%' : 'Diskon Membership'),
                        _memberDiscount > 0 ? '- ${rp(_memberDiscount)}' : '-',
                        valueColor: _memberDiscount > 0 ? kRwGreen : kRwText,
                      ),
                    rwKv('Voucher', _voucherDiscount > 0 ? '- ${rp(_voucherDiscount)}' : '-', valueColor: _voucherDiscount > 0 ? kRwGreen : kRwText),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickVoucher,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: _voucher != null ? const Color(0x1F19A66A) : kRwBlueSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Icon(Icons.confirmation_number_outlined, size: 22, color: _voucher != null ? kRwGreen : kRwNavy),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _voucher != null ? _voucher!.code : (app.usableVouchers.isEmpty ? 'Belum ada voucher tersedia' : 'Pilih voucher'),
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _voucher != null ? kRwGreen : kRwText),
                            ),
                          ),
                          if (_voucher != null)
                            Text('(Hemat ${rp(_voucherDiscount)})', style: const TextStyle(fontSize: 12.5, color: kRwGreen, fontWeight: FontWeight.w700)),
                          const Icon(Icons.chevron_right_rounded, size: 24, color: kRwSub),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                RwCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kRwText))),
                      Text(rp(_total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: kRwNavy, letterSpacing: -.3)),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(14)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.monetization_on_rounded, size: 19, color: kRwGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              estCoins > 0
                                  ? 'Perkiraan dapat +$estCoins Coins setelah pembayaran. Coins bisa ditukar jadi potongan di langkah pembayaran.'
                                  : (_useFree
                                      ? 'Cuci gratis membership tidak mendapat Coins.'
                                      : (pack.isShop
                                          ? 'Belanja minimal ${rp(kShopCoinStepRp)} untuk dapat +$kShopCoinReward Coins (berlaku kelipatan).'
                                          : 'Belum ada Coins untuk transaksi ini.')),
                              style: const TextStyle(color: kRwSub, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4)),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              if (_serviceMode)
                RwButton('Lanjut Pilih Jadwal', icon: Icons.event_available_rounded, onPressed: _goService)
              else
                RwButton(pack.isShop ? 'Lanjut ke Pembayaran' : (_useFree ? 'Konfirmasi Cuci Gratis' : 'Konfirmasi Pesanan'),
                    busy: _busy, onPressed: _confirm),
              const SizedBox(height: 12),
              Text(
                pack.isShop
                    ? 'Pembelian langsung tanpa booking. Setelah bayar, barang bisa diambil di kasir CleanDrive.'
                    : (_useFree
                        ? 'Cuci gratis langsung aktif tanpa pembayaran. Jika dibatalkan sebelum diproses, jatahmu dikembalikan.'
                        : 'Setelah dikonfirmasi, kamu diarahkan ke pembayaran. Pesanan baru aktif setelah dibayar.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}