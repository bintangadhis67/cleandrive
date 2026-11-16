import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/catalog.dart';
import '../../models/loyalty_models.dart';
import '../../models/membership_models.dart';
import '../../models/models.dart';
import '../../models/notification_models.dart';
import '../../widgets/widgets.dart';
import '../garage/garage.dart';
import '../notifications/notifications.dart';
import '../orders/orders.dart';
import '../outlet/outlet.dart';
import '../payment/payment.dart';
import '../profile/help.dart';
import '../profile/settings.dart';
import '../rewards/loyalty.dart';
import '../rewards/membership.dart';
import '../rewards/voucher.dart';
import '../shop/shop.dart';
import 'home_rewards.dart';

typedef GoFn = void Function(int, {WashPackage? pack, VehicleType? vehicle, Product? oil});

const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _creamMuted = Color(0xB3F7F1E7);

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
        );
      case 3:
        page = const ShopScreen(embedded: true);
      default:
        page = AkunTab(onGo: _go);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(_idx), child: page),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final on = _idx == i;
    final c = on ? kRed : kMuted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _go(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: on ? kRed.withValues(alpha: .10) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: c, size: 23),
          ),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: c)),
        ]),
      ),
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
                              fontSize: 10.5, fontWeight: _idx == 2 ? FontWeight.w700 : FontWeight.w500, color: _idx == 2 ? kRed : kMuted)),
                    ),
                  ),
                ),
                _navItem(3, Icons.storefront_rounded, 'Toko'),
                _navItem(4, Icons.person_rounded, 'Akun'),
              ]),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => _go(2),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE5393F), kRed]),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x66C62026), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );

  Widget _phoneShell() => Scaffold(
        body: Stack(children: [
          // Bola warna lembut di latar supaya halaman tidak terasa datar.
          IgnorePointer(
            child: Stack(children: [
              Positioned(top: -90, right: -70, child: _blob(kRed.withValues(alpha: .07), 280)),
              Positioned(top: 300, left: -110, child: _blob(kNavy.withValues(alpha: .05), 320)),
              Positioned(bottom: 140, right: -90, child: _blob(kGold.withValues(alpha: .08), 260)),
            ]),
          ),
          SafeArea(bottom: false, child: _body()),
        ]),
        bottomNavigationBar: _floatingNav(),
      );

  @override
  Widget build(BuildContext context) => _phoneShell(); // Boxed Layout: satu tampilan untuk semua lebar layar
}

// ---------- BERANDA ----------
class BerandaTab extends StatelessWidget {
  final GoFn onGo;
  const BerandaTab({super.key, required this.onGo});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _quick(IconData icon, String label, VoidCallback onTap, List<Color> colors, {Color iconColor = Colors.white}) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                  boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _hero(BuildContext context) => NavyCard(
        radius: 26,
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: Stack(children: [
            Positioned(right: -4, bottom: 10, height: 140, child: Image.asset('assets/images/hero.png', fit: BoxFit.contain)),
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 5, color: kRed)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Drive\nCleaner,\nGo Further.',
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: () => onGo(2),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Booking Sekarang'),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _quickPanel(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Row(children: [
            _quick(Icons.event_available_rounded, 'Booking', () => onGo(2), const [Color(0xFFE5393F), kRed]),
            _quick(Icons.history_rounded, 'Riwayat', () => onGo(1), const [kNavyLight, kNavy]),
            _quick(Icons.local_offer_rounded, 'Voucher', () => _push(context, const MyVouchersScreen()), const [kCream, Color(0xFFEBDDC6)],
                iconColor: kRed),
            _quick(Icons.opacity_rounded, 'Ganti Oli', () => onGo(2, pack: oilChangePackage), const [kNavySoft, kNavyDark]),
          ]),
        ]),
      );

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
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const Text('Selamat datang kembali!', style: TextStyle(color: kMuted)),
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
                      style: const TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ),
            ]),
          );

          final activeSection = <Widget>[
            sec('Pesanan Aktif', trailing: TextButton(onPressed: () => onGo(1), child: const Text('Lihat Semua'))),
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
              for (final b in active.take(3)) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ActiveCard(b)),
          ];

          final reviewCard = toReview == null
              ? <Widget>[]
              : <Widget>[
                  const SizedBox(height: 16),
                  Panel(
                    onTap: () => _push(context, ReviewScreen(bookingId: toReview.id)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded, color: kGold, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Bagaimana hasil layanannya?', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('${toReview.label}. Beri ulasan dan dapat +$kReviewCoins Coins.',
                              style: const TextStyle(fontSize: 12.5, color: kMuted)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: kMuted),
                    ]),
                  ),
                ];

          return PageList(
            onRefresh: () async {
              try {
                await app.refreshAll();
              } catch (_) {}
            },
            children: [
              header,
              _hero(context),
              const SizedBox(height: 16),
              const RewardsHomeCard(),
              const SizedBox(height: 16),
              _quickPanel(context),
              const SizedBox(height: 16),
              const OutletHomeCard(),
              ...reviewCard,
              ...activeSection,
              ShopHomeSection(onSeeAll: () => onGo(3)),
            ],
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
                Text(b.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(b.subtitle, style: const TextStyle(fontSize: 12.5, color: kMuted)),
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
            backgroundColor: const Color(0x1410264C),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: kMuted),
            const SizedBox(width: 6),
            Text(b.pack.isShop ? 'Menunggu pembayaran' : 'Estimasi selesai ${fmtHm.format(b.estFinish)}',
                style: const TextStyle(fontSize: 12.5, color: kMuted)),
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
  final Product? initialOil; // oli yang sudah dipilih di toko
  const BookingScreen({super.key, this.initialPack, this.initialVehicle, this.initialOil});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late VehicleType _v = widget.initialVehicle ?? VehicleType.mobil;
  late WashPackage _p = widget.initialPack ?? packages[1];
  late Product? _oil = widget.initialOil; // oli yang dipilih (jasa ganti oli)
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
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
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

  Widget _dayTile(int i) {
    final d = DateTime.now().add(Duration(days: i));
    final sel = _dayOffset == i;
    final fg = sel ? Colors.white : kNavy;
    return SizedBox(
      width: 78,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
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
    final oilReady = !_isOil || _oil != null;
    final ready = slot != null && _plate.text.trim().isNotEmpty && oilReady;
    final hint = !oilReady
        ? 'Pilih oli dulu'
        : (slot == null ? 'Pilih jam kedatangan' : 'Selesai sekitar ${fmtHm.format(_estimate(slot))}');
    return Container(
      padding: EdgeInsets.fromLTRB(pagePad(MediaQuery.sizeOf(context).width), 12, pagePad(MediaQuery.sizeOf(context).width), 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(rp(_price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(hint, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28)),
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
      ListenableBuilder(
        listenable: app,
        builder: (context, _) => app.garage.isEmpty
            ? const SizedBox(height: 12)
            : Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pilih dari garasi', style: TextStyle(color: kMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in app.garage)
                      ActionChip(
                        avatar: Icon(vehicleIcon(g.type), size: 18, color: kNavy),
                        label: Text('${g.title} • ${g.plate}'),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kLine),
                        onPressed: () => setState(() {
                          _v = g.type;
                          _plate.text = g.plate;
                          final o = _oil;
                          if (o != null && !o.fits(g.type)) _oil = null;
                        }),
                      ),
                  ]),
                ]),
              ),
      ),
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
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 15, color: kMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text('Oli wajib dibeli dari CleanDrive. Oli dari luar tidak diperbolehkan.',
                  style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
            ),
          ]),
        ),
      ] else ...[
        sec('Paket cuci'),
        for (final p in packages) _packTile(p),
      ],
    ];

    List<Widget> right(double top) => [
          sec('Tanggal', top: top),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (var i = 0; i < 7; i++) _dayTile(i)])),
          sec('Jam kedatangan'),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Jam operasional 08.00 - 17.00 WIB. Jam yang penuh atau sudah lewat tidak bisa dipilih.',
                style: TextStyle(color: kMuted, fontSize: 12.5)),
          ),
          if (_loadingSlots)
            Wrap(spacing: 8, runSpacing: 8, children: [for (var h = 8; h <= 17; h++) const Skeleton(width: 82, height: 52, radius: 16)])
          else
            Wrap(spacing: 8, runSpacing: 8, children: [for (var h = 8; h <= 17; h++) _hourTile(h)]),
          sec('Ringkasan pesanan'),
          Panel(
            child: Column(children: [
              kv(_isOil ? 'Layanan' : 'Paket', _p.title),
              kv('Kendaraan', _v.label),
              kv('Nomor polisi', _plate.text.trim().isEmpty ? '-' : _plate.text.trim().toUpperCase()),
              kv('Lokasi', kOutlet.name),
              kv('Jadwal', slot == null ? 'Belum dipilih' : fmtDateTime.format(slot)),
              if (_isOil) kv('Oli', _oil?.name ?? 'Belum dipilih'),
              const Divider(height: 18),
              kv('Perkiraan harga', rp(_price), bold: true),
            ]),
          ),
        ];

    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, cons) {
          final two = cons.maxWidth - pagePad(cons.maxWidth) * 2 >= 900; // dua kolom aktif di laptop (kPageMax = 1280)
          final pad = pagePad(cons.maxWidth);
          return ListView(padding: EdgeInsets.fromLTRB(pad, 8, pad, 16), children: [
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
              color: selected ? kRed.withValues(alpha: .06) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? kRed : kLine, width: selected ? 2 : 1),
            ),
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: selected ? kRed : kNavy, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.3)),
                  ]),
                ),
                const SizedBox(width: 8),
                Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? kRed : kMuted),
              ]),
            ),
          ),
        ),
      );

  Widget _servicePanel() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sec('Jasa Penggantian Oli'),
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
      sec('Perkiraan Biaya', top: 0),
      Panel(
        child: Column(children: [
          kv(oil.name, rp(oil.price)),
          kv('Jasa penggantian (${_oilVehicle(oil).label})', rp(_serviceFee)),
          const Divider(height: 22),
          Row(children: [
            const Expanded(child: Text('Perkiraan Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Text(rp(oil.price + _serviceFee), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ]),
          const SizedBox(height: 8),
          const Text('Voucher dan diskon membership dihitung di konfirmasi booking. Pembayaran setelah jadwal dipilih.',
              style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
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
    return Panel(
      color: ok ? const Color(0xFFEAF6F0) : Colors.white,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.card_giftcard_rounded : Icons.info_outline_rounded, color: ok ? kGreen : kMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ok ? 'Pakai Cuci Gratis ${plan.name}' : 'Cuci Gratis ${plan.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              ok
                  ? 'Sisa ${m.freeLeft} jatah ${plan.freePackage} Wash • maksimal 1x per minggu. Total jadi Rp 0 dan tidak bisa digabung voucher atau Coins.'
                  : (block ?? ''),
              style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.35),
            ),
          ]),
        ),
        if (ok)
          Switch(
            value: _useFree,
            activeColor: kGreen,
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
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pilih voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
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
      appBar: AppBar(title: Text(pack.isShop ? 'Konfirmasi Pembelian' : 'Konfirmasi Pesanan')),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            leftFlex: 5,
            rightFlex: 6,
            left: [
              sec('Detail Pesanan', top: 0),
              Panel(
                child: Column(children: [
                  if (pack.isShop) ...[
                    kv('Jenis', 'Pembelian Langsung'),
                    kv('Jumlah', '${widget.items.fold(0, (s, l) => s + l.qty)} item'),
                    kv('Ambil di', 'Kasir ${kOutlet.name}'),
                  ] else ...[
                    kv(pack.isOil ? 'Layanan' : 'Paket', pack.title),
                    kv('Kendaraan', widget.vehicle.label),
                    kv('Nomor Polisi', widget.plate.toUpperCase()),
                    kv('Lokasi', '${kOutlet.name}, ${kOutlet.shortAddress}'),
                    kv('Tanggal', fmtDate.format(widget.slot)),
                    kv('Jam', '${fmtHm.format(widget.slot)} WIB'),
                    kv('Estimasi Selesai', '${fmtHm.format(widget.estimate)} WIB'),
                  ],
                ]),
              ),
              if (_hasOil) _servicePanel(),
            ],
            right: [
              if (_serviceMode) ..._serviceSummary() else ...[
              if (_showFreePanel) ...[_freeWashPanel(), sec('Rincian Pembayaran')] else sec('Rincian Pembayaran', top: 0),
              Panel(
                child: Column(children: [
                  if (widget.items.isNotEmpty) ...[
                    if (!pack.isShop) kv(pack.title, rp(_servicePrice)),
                    for (final l in widget.items) kv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
                    const Divider(height: 18),
                  ],
                  kv('Total Harga', rp(_price), bold: true),
                  if (!pack.isShop)
                    kv(
                      _useFree
                          ? 'Cuci Gratis ${mem.current!.plan.name}'
                          : (mem.hasActive ? 'Diskon Membership ${mem.current!.plan.name} ${mem.current!.plan.discountPct}%' : 'Diskon Membership'),
                      _memberDiscount > 0 ? '- ${rp(_memberDiscount)}' : '-',
                      valueColor: _memberDiscount > 0 ? kGreen : kNavy,
                    ),
                  kv('Voucher', _voucherDiscount > 0 ? '- ${rp(_voucherDiscount)}' : '-', valueColor: _voucherDiscount > 0 ? kGreen : kNavy),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickVoucher,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: _voucher != null ? const Color(0x1F249B62) : const Color(0x0F10264C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.local_offer_outlined, size: 18, color: _voucher != null ? kGreen : kMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _voucher != null ? _voucher!.code : (app.usableVouchers.isEmpty ? 'Belum ada voucher tersedia' : 'Pilih voucher'),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _voucher != null ? kGreen : kNavy),
                          ),
                        ),
                        if (_voucher != null)
                          Text('(Hemat ${rp(_voucherDiscount)})', style: const TextStyle(fontSize: 12.5, color: kGreen, fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right, size: 20, color: kMuted),
                      ]),
                    ),
                  ),
                  const Divider(height: 26),
                  Row(children: [
                    const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    Text(rp(_total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  ]),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.monetization_on_rounded, size: 18, color: kGold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          estCoins > 0
                              ? 'Perkiraan dapat +$estCoins Coins setelah pembayaran. Coins bisa ditukar jadi potongan di langkah pembayaran.'
                              : (_useFree
                                  ? 'Cuci gratis membership tidak mendapat Coins.'
                                  : (pack.isShop
                                      ? 'Belanja minimal ${rp(kShopCoinStepRp)} untuk dapat +$kShopCoinReward Coins (berlaku kelipatan).'
                                      : 'Belum ada Coins untuk transaksi ini.')),
                          style: const TextStyle(color: kMuted, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.35)),
                    ),
                  ]),
                ]),
              ),
              ],
              const SizedBox(height: 18),
              if (_serviceMode)
                RedButton('Lanjut Pilih Jadwal', icon: Icons.event_available_rounded, onPressed: _goService)
              else
                RedButton(pack.isShop ? 'Lanjut ke Pembayaran' : (_useFree ? 'Konfirmasi Cuci Gratis' : 'Konfirmasi Pesanan'),
                    busy: _busy, onPressed: _confirm),
              const SizedBox(height: 12),
              Text(
                pack.isShop
                    ? 'Pembelian langsung tanpa booking. Setelah bayar, barang bisa diambil di kasir CleanDrive.'
                    : (_useFree
                        ? 'Cuci gratis langsung aktif tanpa pembayaran. Jika dibatalkan sebelum diproses, jatahmu dikembalikan.'
                        : 'Setelah dikonfirmasi, kamu diarahkan ke pembayaran. Pesanan baru aktif setelah dibayar.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- AKUN / PROFIL ----------
class AkunTab extends StatelessWidget {
  final GoFn onGo;
  const AkunTab({super.key, required this.onGo});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _menu(IconData icon, String title, VoidCallback onTap, {String? trailingText}) => ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (trailingText != null) Text(trailingText, style: const TextStyle(color: kMuted, fontSize: 12.5)),
          const Icon(Icons.chevron_right, color: kMuted),
        ]),
        onTap: onTap,
      );

  Widget _statTile({
    required IconData icon,
    required Color accent,
    required List<Color> colors,
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
    Color valueColor = Colors.white,
  }) =>
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .30), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: MotifPainter(accent))),
                  Positioned(right: -8, bottom: -12, child: Icon(icon, size: 84, color: Colors.white.withValues(alpha: .10))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), shape: BoxShape.circle),
                        child: Icon(icon, color: accent == kGold ? kGold : kCream, size: 21),
                      ),
                      const SizedBox(height: 14),
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 26, height: 1)),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _creamMuted, fontSize: 11.5)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

  /// Kartu profil: navy bergradasi dengan motif, avatar bercincin emas.
  Widget _profileCard(BuildContext context, String name, MembershipInfo mem) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavyDark]),
          boxShadow: const [BoxShadow(color: Color(0x3310264C), blurRadius: 28, offset: Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(children: [
            const Positioned.fill(child: CustomPaint(painter: MotifPainter(Colors.white))),
            const Positioned.fill(child: CustomPaint(painter: MotifPainter(kRed, flip: true))),
            Positioned(right: -10, top: -10, child: Icon(Icons.directions_car_filled_rounded, size: 120, color: Colors.white.withValues(alpha: .06))),
            SizedBox(
              width: double.infinity, // isi profil rata tengah
              child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF6CF72), kGold, kRed]),
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: kNavy,
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(color: kCream, fontSize: 36, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                if (app.email.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.mail_outline_rounded, size: 15, color: _creamMuted),
                    const SizedBox(width: 6),
                    Flexible(child: Text(app.email, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _creamMuted))),
                  ]),
                if (app.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.phone_outlined, size: 15, color: _creamMuted),
                      const SizedBox(width: 6),
                      Text(app.phone, style: const TextStyle(color: _creamMuted)),
                    ]),
                  ),
                const SizedBox(height: 12),
                if (mem.hasActive) TierBadge(mem.current!.tier) else MembershipStatusChip(mem.status),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kCream,
                    foregroundColor: kNavy,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _push(context, const SettingsScreen()),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profil'),
                ),
              ]),
            )),
          ]),
        ),
      );

  void _logout(BuildContext context) => showDialog<void>(
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
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final name = app.user ?? '';
          final mem = app.membership;
          final memText = mem.hasActive ? mem.current!.tier.label : mem.status.label;
          return PageList(
            top: 16,
            bottom: 32,
            onRefresh: app.refreshAll,
            children: [
              TwoPane(
                leftFlex: 4,
                rightFlex: 6,
                left: [
                  _profileCard(context, name, mem),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _statTile(
                      icon: Icons.monetization_on_rounded,
                      accent: kGold,
                      colors: const [kNavySoft, kNavyDark],
                      label: 'Coins saya',
                      value: '${app.loyalty.balance}',
                      hint: 'Streak ${app.loyalty.activeStreak} hari',
                      valueColor: kGold,
                      onTap: () => _push(context, const CoinsScreen()),
                    ),
                    const SizedBox(width: 12),
                    _statTile(
                      icon: mem.hasActive ? mem.current!.tier.icon : Icons.workspace_premium_rounded,
                      accent: mem.hasActive ? mem.current!.tier.color : kRed,
                      colors: [
                        mem.hasActive ? mem.current!.tier.color : kRed,
                        Color.lerp(mem.hasActive ? mem.current!.tier.color : kRed, kNavy, .7)!,
                      ],
                      label: 'Membership',
                      value: memText,
                      hint: mem.hasActive ? 'Hingga ${fmtDate.format(mem.current!.endDate!)}' : 'Lihat paket',
                      onTap: () => openMembership(context),
                    ),
                  ])),
                ],
                right: [
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _menu(Icons.directions_car_outlined, 'Kendaraan Saya', () => _push(context, const GarageScreen()),
                          trailingText: app.garage.isEmpty ? null : '${app.garage.length}'),
                      const Divider(height: 1),
                      _menu(Icons.location_on_outlined, 'Lokasi Outlet', () => openOutlet(context)),
                      const Divider(height: 1),
                      _menu(Icons.history_rounded, 'Riwayat Transaksi', () => onGo(1)),
                      const Divider(height: 1),
                      _menu(Icons.workspace_premium_outlined, 'Membership Saya', () => openMembership(context)),
                      const Divider(height: 1),
                      _menu(Icons.monetization_on_outlined, 'Coins Saya', () => _push(context, const CoinsScreen())),
                      const Divider(height: 1),
                      _menu(Icons.local_offer_outlined, 'Voucher Saya', () => _push(context, const MyVouchersScreen())),
                      const Divider(height: 1),
                      _menu(Icons.notifications_none_rounded, 'Notifikasi', () => _push(context, const NotificationScreen()),
                          trailingText: app.unreadCount > 0 ? '${app.unreadCount} baru' : null),
                      const Divider(height: 1),
                      _menu(Icons.settings_outlined, 'Pengaturan Akun', () => _push(context, const SettingsScreen())),
                      const Divider(height: 1),
                      _menu(Icons.help_outline_rounded, 'Bantuan & FAQ', () => _push(context, const HelpScreen())),
                      const Divider(height: 1),
                      _menu(
                        Icons.info_outline,
                        'Tentang CleanDrive',
                        () => showAboutDialog(
                          context: context,
                          applicationName: 'CleanDrive',
                          applicationVersion: '1.3.0',
                          applicationLegalese: 'DRIVE CLEANER. GO FURTHER.',
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Panel(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onTap: () => _logout(context),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout, color: kRed, size: 20),
                      SizedBox(width: 8),
                      Text('Keluar', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ],
          );
        },
      );
}