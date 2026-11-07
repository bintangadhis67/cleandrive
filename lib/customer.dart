import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'models.dart';
import 'orders.dart';
import 'payment.dart';
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
  int _idx = 0; // 0 Beranda, 1 Pesanan, 2 Booking, 3 Layanan, 4 Akun
  WashPackage? _pack;
  VehicleType? _vehicle;

  @override
  void initState() {
    super.initState();
    app.addListener(_onApp);
  }

  @override
  void dispose() {
    app.removeListener(_onApp);
    super.dispose();
  }

  /// Layar lain (voucher, pembayaran) bisa meminta pindah tab lewat app.requestTab().
  void _onApp() {
    final t = app.requestedTab;
    if (t != null) {
      app.requestedTab = null;
      if (mounted) {
        setState(() {
          _idx = t;
          _pack = null;
          _vehicle = null;
        });
      }
    }
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
      case 3:
        return LayananTab(onGo: _go);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _body()),
          ),
        ),
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
            _navItem(1, Icons.receipt_long_rounded, 'Pesanan'),
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
            _navItem(3, Icons.local_car_wash_rounded, 'Layanan'),
            _navItem(4, Icons.person_rounded, 'Akun'),
          ]),
        ),
      );
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final name = app.user ?? '';
          final first = name.split(' ').first;
          final active = app.bookings.where((b) => b.active).toList()..sort((a, b) => a.slot.compareTo(b.slot));
          final toReview = app.bookings.where((b) => b.status == 3 && !b.cancelled && b.review == null).firstOrNull;
          return RefreshIndicator(
            color: kRed,
            onRefresh: () async {
              try {
                await app.refreshAll();
              } catch (_) {}
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Halo, $first!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      const Text('Siap cuci kendaraanmu hari ini?', style: TextStyle(color: kMuted)),
                    ]),
                  ),
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
              ),
              _hero(),
              const SizedBox(height: 16),
              const VoucherHomeCard(),
              const SizedBox(height: 16),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _quick(Icons.event_available, 'Booking', () => onGo(2)),
                    _quick(Icons.receipt_long, 'Pesanan', () => onGo(1)),
                    _quick(Icons.local_car_wash, 'Layanan', () => onGo(3)),
                    _quick(Icons.local_offer_outlined, 'Voucher',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen()))),
                  ]),
                ]),
              ),
              if (toReview != null) ...[
                const SizedBox(height: 16),
                Panel(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: toReview.id))),
                  child: Row(children: [
                    const Icon(Icons.star_rounded, color: kGold, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Bagaimana hasil cucianmu?', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${toReview.pack.name} • ${toReview.plate}. Beri rating dan ulasan.',
                            style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: kMuted),
                  ]),
                ),
              ],
              sec('Cucian aktif', trailing: TextButton(onPressed: () => onGo(1), child: const Text('Lihat Semua'))),
              if (active.isEmpty)
                Panel(
                  child: Row(children: [
                    const Icon(Icons.local_car_wash_outlined, size: 32, color: kMuted),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Belum ada cucian aktif.', style: TextStyle(color: kMuted))),
                    TextButton(onPressed: () => onGo(2), child: const Text('Booking')),
                  ]),
                )
              else
                _ActiveCard(active.first),
            ]),
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
                Text('${b.pack.name} • ${b.plate}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
            Text('Estimasi selesai ${fmtHm.format(b.estFinish)}', style: const TextStyle(fontSize: 12.5, color: kMuted)),
            const Spacer(),
            PayChip(b),
          ]),
        ]),
      );
}

// ---------- LAYANAN ----------
class LayananTab extends StatefulWidget {
  final GoFn onGo;
  const LayananTab({super.key, required this.onGo});
  @override
  State<LayananTab> createState() => _LayananTabState();
}

class _LayananTabState extends State<LayananTab> {
  VehicleType _v = VehicleType.mobil;

  Widget _pill(VehicleType v) {
    final sel = _v == v;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _v = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kNavy : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? kNavy : kLine),
          ),
          child: Text(v.label, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : kNavy)),
        ),
      ),
    );
  }

  Widget _serviceCard(WashPackage p) {
    final popular = p.name == 'Reguler';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: NavyCard(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                flex: 5,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${p.name} Wash',
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(p.desc, style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 14, color: _creamMuted),
                    const SizedBox(width: 4),
                    Text('${p.minutes} menit', style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
                  ]),
                  const SizedBox(height: 12),
                  Text(rp(p.priceFor(_v)), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => widget.onGo(2, pack: p, vehicle: _v),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
              const SizedBox(width: 6),
              Expanded(flex: 5, child: Image.asset(p.imageFor(_v), fit: BoxFit.contain)),
            ]),
          ),
          if (popular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(color: kRed, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                child: const Text('Populer', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          pageHeader('Layanan Kami', 'Pilih kendaraan, lihat harga tiap paket.'),
          if (app.rating.count > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                StarRow(app.rating.avg, size: 18),
                const SizedBox(width: 8),
                Text('${app.rating.avg.toStringAsFixed(1)} dari ${app.rating.count} ulasan',
                    style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          Row(children: [for (final v in VehicleType.values) _pill(v)]),
          const SizedBox(height: 16),
          for (final p in packages) _serviceCard(p),
        ]),
      );
}

// ---------- BOOKING (pilih kendaraan, paket, jadwal) ----------
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
  final _plate = TextEditingController();
  int _dayOffset = 0;
  int? _hour;
  Map<int, int> _counts = {};
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
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

  /// Estimasi selesai = jam datang + durasi paket + 10 menit per antrean di depan.
  DateTime _estimate(DateTime slot) => slot.add(Duration(minutes: _p.minutes + _count(slot.hour) * 10));

  void _next() {
    final slot = _day.add(Duration(hours: _hour!));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmOrderScreen(vehicle: _v, pack: _p, plate: _plate.text.trim(), slot: slot, estimate: _estimate(slot)),
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

  Widget _vehicleTile(VehicleType v) {
    final sel = _v == v;
    final fg = sel ? Colors.white : kNavy;
    return _choice(
      selected: sel,
      onTap: () => setState(() => _v = v),
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
                Text('${p.name} Wash', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
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
    final ready = slot != null && _plate.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(rp(_p.priceFor(_v)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(slot == null ? 'Pilih jam kedatangan' : 'Selesai sekitar ${fmtHm.format(_estimate(slot))}',
                style: const TextStyle(fontSize: 12.5, color: kMuted)),
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
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          pageHeader('Booking Cuci', 'Pilih kendaraan, paket, dan jam kedatangan.'),
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
          sec('Paket cuci'),
          for (final p in packages) _packTile(p),
          sec('Tanggal', top: 12),
          Row(children: [for (var i = 0; i < 3; i++) _dayTile(i)]),
          sec('Jam kedatangan'),
          if (_loadingSlots)
            const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: kRed)))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [for (var h = 8; h <= 17; h++) _hourTile(h)]),
        ]),
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
  const ConfirmOrderScreen({
    super.key,
    required this.vehicle,
    required this.pack,
    required this.plate,
    required this.slot,
    required this.estimate,
  });
  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  Voucher? _voucher;
  bool _busy = false;

  int get _price => widget.pack.priceFor(widget.vehicle);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Panel(
              child: Column(children: [
                kv('Paket', '${widget.pack.name} Wash'),
                kv('Kendaraan', widget.vehicle.label),
                kv('Nomor Polisi', widget.plate.toUpperCase()),
                kv('Tanggal', fmtDate.format(widget.slot)),
                kv('Jam', '${fmtHm.format(widget.slot)} WIB'),
                kv('Estimasi Selesai', '${fmtHm.format(widget.estimate)} WIB'),
              ]),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(children: [
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
              ]),
            ),
            const SizedBox(height: 20),
            RedButton('Konfirmasi Pesanan', busy: _busy, onPressed: _confirm),
            const SizedBox(height: 14),
            const Text(
              'Setelah dikonfirmasi, kamu akan diarahkan ke pembayaran. Pesanan baru aktif setelah dibayar.',
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
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
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
              ]),
            ),
            const SizedBox(height: 22),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _menu(Icons.receipt_long_outlined, 'Pesanan Saya', () => onGo(1)),
                const Divider(height: 1),
                _menu(Icons.local_offer_outlined, 'Voucher Saya',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen()))),
                const Divider(height: 1),
                _menu(Icons.star_outline_rounded, 'Ulasan Saya',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen()))),
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
                    applicationVersion: '1.1.0',
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
          ]);
        },
      );
}
