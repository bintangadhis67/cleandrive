import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'catalog.dart';
import 'data/repository.dart';
import 'loyalty.dart';
import 'loyalty_models.dart';
import 'models.dart';
import 'notification_models.dart';
import 'notifications.dart';
import 'orders.dart';
import 'payment.dart';
import 'shop.dart';
import 'theme.dart';
import 'voucher.dart';
import 'widgets.dart';

typedef GoFn = void Function(int, {WashPackage? pack, VehicleType? vehicle});

const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _creamMuted = Color(0xB3F4E8D6);

// ---------- HOME KONSUMEN (bottom bar + tombol Booking di tengah) ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0; // 0 Beranda, 1 Riwayat (termasuk Ulasan), 2 Booking (cuci / ganti oli), 4 Akun
  WashPackage? _pack;
  VehicleType? _vehicle;
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
      final p = app.requestedPack, v = app.requestedVehicle;
      app.requestedTab = null;
      app.requestedPack = null;
      app.requestedVehicle = null;
      if (mounted) {
        setState(() {
          _idx = t;
          _pack = p;
          _vehicle = v;
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

  /// Banner notifikasi di dalam aplikasi.
  void _showBanner(AppNotification n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Row(children: [
          Icon(n.type.icon, color: kGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
            ]),
          ),
        ]),
        action: SnackBarAction(label: 'Lihat', textColor: kGold, onPressed: () => openNotification(context, n)),
      ));
  }

  void _go(int i, {WashPackage? pack, VehicleType? vehicle}) => setState(() {
        _idx = i;
        _pack = pack;
        _vehicle = vehicle;
      });

  Widget _body() {
    switch (_idx) {
      case 0:
        return BerandaTab(onGo: _go);
      case 1:
        return const OrdersScreen();
      case 2:
        return BookingScreen(
          key: ValueKey('${_pack?.name}-${_vehicle?.name}'),
          initialPack: _pack,
          initialVehicle: _vehicle,
        );
      default:
        return AkunTab(onGo: _go);
    }
  }

  Widget _navItem(int i, IconData icon, String label) {
    final on = _idx == i;
    final c = on ? kRed : kMuted;
    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: c)),
        ]),
      ),
    );
  }

  /// Item menu bawah yang membuka layar baru (bukan tab), mis. Toko.
  Widget _navItemPush(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: kMuted, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: kMuted)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Tampilan satu kolom di tengah dengan menu bawah (HP dan laptop sama).
    return Scaffold(
      body: SafeArea(bottom: false, child: PageBox(maxWidth: 640, child: _body())),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _go(2),
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        height: 66,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _navItem(0, Icons.home_rounded, 'Beranda'),
          _navItem(1, Icons.history_rounded, 'Riwayat'),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Booking',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: _idx == 2 ? FontWeight.w800 : FontWeight.w600,
                        color: _idx == 2 ? kRed : kMuted)),
              ),
            ),
          ),
          _navItemPush(Icons.storefront_rounded, 'Toko', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
          _navItem(4, Icons.person_rounded, 'Akun'),
        ]),
      ),
    );
  }
}

// ---------- BERANDA ----------
class BerandaTab extends StatelessWidget {
  final GoFn onGo;
  const BerandaTab({super.key, required this.onGo});

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: kCream),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  Widget _hero() => NavyCard(
        radius: 26,
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(children: [
            Positioned(right: -4, bottom: 10, height: 128, child: Image.asset('assets/images/hero.png', fit: BoxFit.contain)),
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 5, color: kRed)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Drive\nCleaner,\nGo Further.',
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kCream,
                      foregroundColor: kNavy,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => onGo(2),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Pesan Cuci', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final name = app.user ?? '';
          final first = name.split(' ').first;
          final active = app.bookings.where((b) => b.active).toList()..sort((a, b) => a.slot.compareTo(b.slot));
          final toReview =
              app.bookings.where((b) => b.status == 3 && !b.cancelled && !b.pack.isShop && b.review == null).firstOrNull;

          final header = Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(children: [
              // Logo kecil di kiri atas, sebelum sapaan nama.
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(14)),
                child: Image.asset('assets/images/logo_transparent.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Halo, $first!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const Text('Siap cuci kendaraanmu hari ini?', style: TextStyle(color: kMuted)),
                ]),
              ),
              const NotifBell(),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onGo(4),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: kNavy,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(color: kCream, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ]),
          );

          // Kolom kiri: hero, member, voucher.
          final left = <Widget>[
            _hero(),
            const SizedBox(height: 16),
            const MemberHomeCard(),
            const SizedBox(height: 16),
            const VoucherHomeCard(),
          ];

          // Kolom kanan: akses cepat, ulasan, pesanan aktif, toko.
          final right = <Widget>[
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(children: [
                  _quick(Icons.event_available, 'Booking', () => onGo(2)),
                  _quick(Icons.opacity_rounded, 'Ganti Oli', () => onGo(2, pack: oilChangePackage)),
                  _quick(Icons.storefront_rounded, 'Toko', () => _push(context, const ShopScreen())),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _quick(Icons.history_rounded, 'Riwayat', () => onGo(1)),
                  _quick(Icons.local_offer_outlined, 'Voucher', () => _push(context, const MyVouchersScreen())),
                  _quick(Icons.workspace_premium_rounded, 'Member', () => _push(context, const LoyaltyScreen())),
                ]),
              ]),
            ),
            if (toReview != null) ...[
              const SizedBox(height: 16),
              Panel(
                onTap: () => _push(context, ReviewScreen(bookingId: toReview.id)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: kGold, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bagaimana hasil layanannya?', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text('${toReview.label}. Beri ulasan dan dapat +$kReviewCoins Coins.',
                          style: const TextStyle(fontSize: 12.5, color: kMuted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: kMuted),
                ]),
              ),
            ],
            sec('Pesanan aktif', trailing: TextButton(onPressed: () => onGo(1), child: const Text('Lihat Semua'))),
            if (active.isEmpty)
              Panel(
                child: Row(children: [
                  const Icon(Icons.local_car_wash_outlined, size: 32, color: kMuted),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Belum ada pesanan aktif.', style: TextStyle(color: kMuted))),
                  TextButton(onPressed: () => onGo(2), child: const Text('Booking')),
                ]),
              )
            else
              _ActiveCard(active.first),
            const ShopHomeSection(),
          ];

          return RefreshIndicator(
            color: kRed,
            onRefresh: () async {
              try {
                await app.refreshAll();
              } catch (_) {}
            },
            child: LayoutBuilder(builder: (context, cons) {
              final two = cons.maxWidth >= 900; // laptop: dua kolom
              return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                header,
                if (two)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                  ])
                else ...[
                  ...left,
                  const SizedBox(height: 16),
                  ...right,
                ],
              ]);
            }),
          );
        },
      );
}

class _ActiveCard extends StatelessWidget {
  final Booking b;
  const _ActiveCard(this.b);
  @override
  Widget build(BuildContext context) => Panel(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ServiceThumb(b.pack, b.vehicle, width: 92),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.code, style: const TextStyle(fontSize: 11.5, color: kMuted)),
                Text(b.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ]),
            ),
            StatusChip(b),
          ]),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (b.status + 1) / 4,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: kRed,
            backgroundColor: const Color(0x140B1F44),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: kMuted),
            const SizedBox(width: 6),
            Text(b.pack.isShop ? 'Menunggu pembayaran' : 'Estimasi selesai ${fmtHm.format(b.estFinish)}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
            const Spacer(),
            PayChip(b),
          ]),
        ]),
      );
}

// ---------- BOOKING (cuci atau ganti oli: pilih kendaraan, paket, jadwal) ----------
class BookingScreen extends StatefulWidget {
  final WashPackage? initialPack;
  final VehicleType? initialVehicle;
  const BookingScreen({super.key, this.initialPack, this.initialVehicle});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late VehicleType _v = widget.initialVehicle ?? VehicleType.mobil;
  late WashPackage _p = widget.initialPack ?? packages[1];
  Product? _oil; // oli yang dipilih (jasa ganti oli)
  bool _ownOil = false; // bawa oli sendiri
  final _plate = TextEditingController();
  int _dayOffset = 0;
  int? _hour;
  Map<int, int> _counts = {};
  bool _loadingSlots = false;

  bool get _isOil => _p.isOil;
  int get _price => _p.priceFor(_v) + (_oil?.price ?? 0);

  @override
  void initState() {
    super.initState();
    app.refreshStock();
    _loadCounts();
  }

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  DateTime get _day {
    final n = DateTime.now().add(Duration(days: _dayOffset));
    return DateTime(n.year, n.month, n.day);
  }

  int _count(int h) => _counts[h] ?? 0;

  Future<void> _loadCounts() async {
    setState(() => _loadingSlots = true);
    try {
      final m = await app.slotCounts(_day);
      if (mounted) setState(() => _counts = m);
    } catch (_) {
      // slot tetap tampil tersedia; server akan memvalidasi saat konfirmasi
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  /// Estimasi selesai = jam datang + durasi layanan + 10 menit per antrean di depan.
  DateTime _estimate(DateTime slot) => slot.add(Duration(minutes: _p.minutes + _count(slot.hour) * 10));

  void _setOilMode(bool oil) => setState(() {
        _p = oil ? oilChangePackage : packages[1];
        _oil = null;
        _ownOil = false;
      });

  void _next() {
    final slot = _day.add(Duration(hours: _hour!));
    final oil = _oil;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmOrderScreen(
          vehicle: _v,
          pack: _p,
          plate: _plate.text.trim(),
          slot: slot,
          estimate: _estimate(slot),
          items: _isOil && oil != null ? [OrderLine(oil, 1)] : const [],
        ),
      ),
    );
  }

  Widget _choice({required bool selected, required VoidCallback? onTap, required Widget child, double vertical = 14}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: vertical),
          decoration: BoxDecoration(
            color: selected ? kRed : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kRed : kLine),
          ),
          child: child,
        ),
      );

  Widget _modeTile(String label, IconData icon, bool selected, VoidCallback onTap) {
    final fg = selected ? Colors.white : kNavy;
    return _choice(
      selected: selected,
      onTap: onTap,
      vertical: 12,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
      ]),
    );
  }

  Widget _vehicleTile(VehicleType v) {
    final sel = _v == v;
    final fg = sel ? Colors.white : kNavy;
    return _choice(
      selected: sel,
      onTap: () => setState(() {
        _v = v;
        final o = _oil;
        if (o != null && !o.fits(v)) _oil = null; // oli harus cocok dengan kendaraan
      }),
      vertical: 16,
      child: Column(children: [
        Icon(vehicleIcon(v), size: 30, color: fg),
        const SizedBox(height: 6),
        Text(v.label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  Widget _packTile(WashPackage p) {
    final sel = _p == p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _p = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? kRed : kLine, width: sel ? 2.5 : 1),
          ),
          child: Row(children: [
            ServiceThumb(p, _v, width: 96),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
                  if (p.name == 'Reguler')
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Populer', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                ]),
                Text(p.desc, style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 14, color: kMuted),
                  const SizedBox(width: 4),
                  Text('${p.minutes} menit', style: const TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rp(p.priceFor(_v)), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed)),
              if (sel) const Icon(Icons.check_circle, color: kRed, size: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _oilTile(Product o) {
    final sel = _oil?.id == o.id;
    final left = app.stockOf(o);
    final out = left <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: out
            ? null
            : () => setState(() {
                  _oil = o;
                  _ownOil = false;
                }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? kRed : kLine, width: sel ? 2.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: Opacity(opacity: out ? .4 : 1, child: ProductImage(o)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text(o.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kMuted)),
                if (out)
                  const Text('Stok habis', style: TextStyle(fontSize: 12, color: Color(0xFFB3261E), fontWeight: FontWeight.w800))
                else if (left < kLowStock)
                  Text('Sisa $left', style: const TextStyle(fontSize: 12, color: Color(0xFFD08A00), fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rp(o.price), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 13.5)),
              if (sel) const Icon(Icons.check_circle, color: kRed, size: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _ownOilTile() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => setState(() {
            _ownOil = true;
            _oil = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _ownOil ? kRed : kLine, width: _ownOil ? 2.5 : 1),
            ),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 30, color: kNavy),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bawa oli sendiri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  Text('Hanya bayar jasa penggantian oli', style: TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
              if (_ownOil) const Icon(Icons.check_circle, color: kRed, size: 20),
            ]),
          ),
        ),
      );

  Widget _dayTile(int i) {
    final d = DateTime.now().add(Duration(days: i));
    final sel = _dayOffset == i;
    final fg = sel ? Colors.white : kNavy;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
        child: _choice(
          selected: sel,
          onTap: () {
            setState(() {
              _dayOffset = i;
              _hour = null;
            });
            _loadCounts();
          },
          child: Column(children: [
            Text(i == 0 ? 'Hari ini' : _dayNames[d.weekday - 1], style: TextStyle(fontSize: 12, color: fg)),
            Text('${d.day}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
            Text(_monthNames[d.month - 1], style: TextStyle(fontSize: 12, color: fg)),
          ]),
        ),
      ),
    );
  }

  Widget _hourTile(int h) {
    final past = _day.add(Duration(hours: h)).isBefore(DateTime.now());
    final full = _count(h) >= AppState.maxPerSlot;
    final off = past || full;
    final sel = _hour == h;
    final fg = sel ? Colors.white : (off ? const Color(0x4D0B1F44) : kNavy);
    return SizedBox(
      width: 82,
      child: _choice(
        selected: sel,
        onTap: off ? null : () => setState(() => _hour = h),
        vertical: 10,
        child: Column(children: [
          Text('${h.toString().padLeft(2, '0')}:00', style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
          Text(full ? 'Penuh' : (past ? 'Lewat' : 'Tersedia'),
              style: TextStyle(fontSize: 10.5, color: full ? const Color(0xFFD64545) : fg)),
        ]),
      ),
    );
  }

  Widget _bottomBar(DateTime? slot) {
    final oilReady = !_isOil || _oil != null || _ownOil;
    final ready = slot != null && _plate.text.trim().isNotEmpty && oilReady;
    final hint = !oilReady
        ? 'Pilih oli dulu'
        : (slot == null ? 'Pilih jam kedatangan' : 'Selesai sekitar ${fmtHm.format(_estimate(slot))}');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(rp(_price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(hint, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22)),
          onPressed: ready ? _next : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Lanjut'),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = _hour == null ? null : _day.add(Duration(hours: _hour!));
    final oils = productsIn(ProductCategory.oli).where((o) => o.fits(_v)).toList();

    // Kolom kiri: jenis layanan, kendaraan, paket/oli. Kolom kanan: tanggal dan jam.
    final left = <Widget>[
      Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _modeTile('Cuci', Icons.local_car_wash_rounded, !_isOil, () => _setOilMode(false)),
          ),
        ),
        Expanded(child: _modeTile('Ganti Oli', Icons.opacity_rounded, _isOil, () => _setOilMode(true))),
      ]),
      const SizedBox(height: 18),
      const Text('Jenis kendaraan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Row(children: [
        for (final v in VehicleType.values)
          Expanded(child: Padding(padding: EdgeInsets.only(right: v == VehicleType.suv ? 0 : 10), child: _vehicleTile(v))),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _plate,
        textCapitalization: TextCapitalization.characters,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Plat nomor',
          hintText: 'mis. L 1234 AB',
          prefixIcon: Icon(Icons.confirmation_number_outlined),
        ),
      ),
      if (_isOil) ...[
        sec('Pilih oli'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Jasa penggantian ${rp(_p.priceFor(_v))} untuk ${_v.label}. Harga oli ditambahkan sesuai pilihanmu.',
              style: const TextStyle(color: kMuted, fontSize: 12.5)),
        ),
        ListenableBuilder(
          listenable: app,
          builder: (context, _) => Column(children: [for (final o in oils) _oilTile(o)]),
        ),
        _ownOilTile(),
      ] else ...[
        sec('Paket cuci'),
        for (final p in packages) _packTile(p),
      ],
    ];

    List<Widget> right(double top) => [
          sec('Tanggal', top: top),
          Row(children: [for (var i = 0; i < 3; i++) _dayTile(i)]),
          sec('Jam kedatangan'),
          if (_loadingSlots)
            const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: kRed)))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [for (var h = 8; h <= 17; h++) _hourTile(h)]),
        ];

    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, cons) {
          final two = cons.maxWidth >= 900; // laptop: dua kolom
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
            pageHeader(_isOil ? 'Ganti Oli' : 'Booking Cuci',
                _isOil ? 'Pilih kendaraan, oli, dan jam kedatangan.' : 'Pilih kendaraan, paket, dan jam kedatangan.'),
            ListenableBuilder(
              listenable: app,
              builder: (context, _) => app.rating.count > 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        StarRow(app.rating.avg, size: 18),
                        const SizedBox(width: 8),
                        Text('${app.rating.avg.toStringAsFixed(1)} dari ${app.rating.count} ulasan',
                            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
            if (two)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                const SizedBox(width: 24),
                Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right(0))),
              ])
            else ...[
              ...left,
              ...right(12),
            ],
          ]);
        }),
      ),
      _bottomBar(slot),
    ]);
  }
}

// ---------- KONFIRMASI PESANAN (desain layar 8) ----------
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

  int get _servicePrice => widget.pack.priceFor(widget.vehicle);
  int get _itemsTotal => widget.items.fold(0, (s, l) => s + l.subtotal);
  int get _price => _servicePrice + _itemsTotal;
  int get _discount => _voucher?.discountFor(_price) ?? 0;

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
  }

  Future<void> _pickVoucher() async {
    final claimed = app.vouchers.where((v) => v.claimed).toList();
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pilih voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (claimed.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Kamu belum punya voucher. Klaim voucher di beranda.', style: TextStyle(color: kMuted)),
              ),
            for (final v in claimed)
              Builder(builder: (_) {
                final reason = v.used ? 'Sudah dipakai' : (v.expired ? 'Kedaluwarsa' : (!v.eligible(_price) ? 'Min. transaksi ${rp(v.minTransaction)}' : null));
                return ListTile(
                  enabled: reason == null,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_offer_rounded, color: kRed),
                  title: Text(v.code, style: const TextStyle(fontWeight: FontWeight.w800)),
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
        voucherCode: _voucher?.code,
        items: widget.items,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (b == null) return;
    final nav = Navigator.of(context);
    app.requestTab(1);
    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute(builder: (_) => PaymentMethodScreen(bookingId: b.id)));
  }

  @override
  Widget build(BuildContext context) {
    final total = _price - _discount;
    final estCoins = withTierBonus(payBandFor(total).coins, app.tier);
    final pack = widget.pack;
    return Scaffold(
      appBar: AppBar(title: Text(pack.isShop ? 'Konfirmasi Pembelian' : 'Konfirmasi Pesanan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Panel(
              child: Column(children: [
                if (pack.isShop) ...[
                  kv('Jenis', 'Pembelian Langsung'),
                  kv('Jumlah', '${widget.items.fold(0, (s, l) => s + l.qty)} item'),
                  kv('Ambil di', 'Kasir CleanDrive'),
                ] else ...[
                  kv(pack.isOil ? 'Layanan' : 'Paket', pack.title),
                  kv('Kendaraan', widget.vehicle.label),
                  kv('Nomor Polisi', widget.plate.toUpperCase()),
                  kv('Tanggal', fmtDate.format(widget.slot)),
                  kv('Jam', '${fmtHm.format(widget.slot)} WIB'),
                  kv('Estimasi Selesai', '${fmtHm.format(widget.estimate)} WIB'),
                  if (pack.isOil && widget.items.isEmpty) kv('Oli', 'Dibawa sendiri'),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(children: [
                if (widget.items.isNotEmpty) ...[
                  if (!pack.isShop) kv(pack.title, rp(_servicePrice)),
                  for (final l in widget.items) kv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
                  const Divider(height: 18),
                ],
                kv('Total Harga', rp(_price), bold: true),
                kv('Voucher', _discount > 0 ? '- ${rp(_discount)}' : '-', valueColor: _discount > 0 ? kGreen : kNavy),
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickVoucher,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: _voucher != null ? const Color(0x1F2E9E5B) : const Color(0x0F0B1F44),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.local_offer_outlined, size: 18, color: _voucher != null ? kGreen : kMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _voucher != null ? _voucher!.code : (app.usableVouchers.isEmpty ? 'Belum ada voucher tersedia' : 'Pilih voucher'),
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _voucher != null ? kGreen : kNavy),
                        ),
                      ),
                      if (_voucher != null)
                        Text('(Hemat ${rp(_discount)})', style: const TextStyle(fontSize: 12.5, color: kGreen, fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right, size: 20, color: kMuted),
                    ]),
                  ),
                ),
                const Divider(height: 26),
                Row(children: [
                  const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Text(rp(total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.monetization_on_rounded, size: 18, color: kGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Perkiraan dapat +$estCoins Coins setelah pembayaran',
                        style: const TextStyle(color: kMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            RedButton(pack.isShop ? 'Lanjut ke Pembayaran' : 'Konfirmasi Pesanan', busy: _busy, onPressed: _confirm),
            const SizedBox(height: 14),
            Text(
              pack.isShop
                  ? 'Pembelian langsung tanpa booking. Setelah bayar, pembelian selesai dan barang bisa diambil di kasir CleanDrive. Kamu juga bisa menukar Coins jadi potongan harga.'
                  : 'Setelah dikonfirmasi, kamu akan diarahkan ke pembayaran dan bisa menukar Coins jadi potongan harga. Pesanan baru aktif setelah dibayar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------- AKUN ----------
class AkunTab extends StatelessWidget {
  final GoFn onGo;
  const AkunTab({super.key, required this.onGo});

  void _editProfile(BuildContext context) {
    final name = TextEditingController(text: app.user);
    final phone = TextEditingController(text: app.phone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profil'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama lengkap')),
            const SizedBox(height: 12),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final ok = await guard(ctx, () async {
                await app.updateProfile(name.text.trim(), phone.text.trim());
                return true;
              });
              if (ok == true && ctx.mounted) {
                Navigator.pop(ctx);
                if (context.mounted) toast(context, 'Profil diperbarui');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context) {
    final oldC = TextEditingController(), newC = TextEditingController(), conC = TextEditingController();
    String? err;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ganti password'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
              const SizedBox(height: 12),
              TextField(controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
              const SizedBox(height: 12),
              TextField(controller: conC, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi password baru')),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () async {
                if (newC.text.length < 6) {
                  setS(() => err = 'Password baru minimal 6 karakter');
                } else if (newC.text != conC.text) {
                  setS(() => err = 'Konfirmasi password tidak sama');
                } else {
                  try {
                    await app.changePassword(oldC.text, newC.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) toast(context, 'Password berhasil diubah');
                  } on ApiException catch (e) {
                    setS(() => err = e.message);
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(IconData icon, String title, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, color: kMuted),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final name = app.user ?? '';
          return PageBox(
            maxWidth: 720,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            const SizedBox(height: 12),
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: kNavy,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(color: kCream, fontSize: 36, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                if (app.email.isNotEmpty) Text(app.email, style: const TextStyle(color: kMuted)),
                if (app.phone.isNotEmpty) Text(app.phone, style: const TextStyle(color: kMuted)),
                const SizedBox(height: 10),
                TierBadge(app.tier),
              ]),
            ),
            const SizedBox(height: 22),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _menu(Icons.history_rounded, 'Riwayat & Ulasan', () => onGo(1)),
                const Divider(height: 1),
                _menu(Icons.workspace_premium_outlined, 'Membership & Coins',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen()))),
                const Divider(height: 1),
                _menu(Icons.notifications_none_rounded, app.unreadCount > 0 ? 'Notifikasi (${app.unreadCount} baru)' : 'Notifikasi',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                const Divider(height: 1),
                _menu(Icons.storefront_outlined, 'Toko CleanDrive',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
                const Divider(height: 1),
                _menu(Icons.local_offer_outlined, 'Voucher Saya',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen()))),
                const Divider(height: 1),
                _menu(Icons.person_outline, 'Edit Profil', () => _editProfile(context)),
                const Divider(height: 1),
                _menu(Icons.lock_outline, 'Ganti Password', () => _changePassword(context)),
                const Divider(height: 1),
                _menu(
                  Icons.info_outline,
                  'Tentang CleanDrive',
                  () => showAboutDialog(
                    context: context,
                    applicationName: 'CleanDrive',
                    applicationVersion: '1.2.0',
                    applicationLegalese: 'Aplikasi booking dan tracking antrean cuci kendaraan.',
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar dari akun?'),
                  content: const Text('Kamu perlu masuk lagi untuk melihat pesananmu.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        app.logout();
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout, color: kRed, size: 20),
                SizedBox(width: 8),
                Text('Keluar', style: TextStyle(color: kRed, fontWeight: FontWeight.w800)),
              ]),
            ),
            ]),
          );
        },
      );
}