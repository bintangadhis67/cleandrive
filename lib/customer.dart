import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

typedef GoFn = void Function(int, {WashPackage? pack, VehicleType? vehicle});

final _fmt = DateFormat('d MMM yyyy, HH:mm');
final _hm = DateFormat('HH:mm');
const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _statusColors = [Color(0xFFD08A00), kRed, Color(0xFF3B5FB8), Color(0xFF2E9E5B)];
const _stageNames = ['Mobil dalam antrean', 'Sedang dicuci', 'Finishing', 'Siap diambil'];
const _headlines = [
  'Kendaraanmu menunggu giliran',
  'Kendaraanmu sedang dicuci!',
  'Hampir selesai, tahap finishing!',
  'Cucian selesai, siap diambil!',
];
const _inkMuted = Color(0x990B1F44); // teks redup di atas kartu cream
const _creamMuted = Color(0xB3F4E8D6); // teks redup di atas latar navy
final _cardTheme = buildCardTheme();

// ---------- Helper tampilan ----------
IconData _vehicleIcon(VehicleType v) => switch (v) {
      VehicleType.motor => Icons.two_wheeler,
      VehicleType.mobil => Icons.directions_car_filled,
      VehicleType.suv => Icons.airport_shuttle,
    };

IconData _packIcon(WashPackage p) =>
    p.name == 'Express' ? Icons.bolt : (p.name == 'Reguler' ? Icons.local_car_wash : Icons.auto_awesome);

Widget _sec(String t, {double top = 22}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kCream)),
    );

Widget _header(String title, String sub) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kCream)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: _creamMuted)),
      ]),
    );

void _toast(BuildContext c, String msg) => ScaffoldMessenger.of(c)
    .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

/// Kartu cream dengan teks navy (gaya desain).
class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) => Theme(
        data: _cardTheme,
        child: Material(
          color: kCream,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final int status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    final c = _statusColors[status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabels[status], style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

// ---------- HOME KONSUMEN (bottom bar cream + tombol Booking di tengah) ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0; // 0 Beranda, 1 Pesanan, 2 Booking, 3 Layanan, 4 Akun
  WashPackage? _pack;
  VehicleType? _vehicle;

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
          onDone: () => _go(1),
        );
      case 3:
        return LayananTab(onGo: _go);
      default:
        return AkunTab(onGo: _go);
    }
  }

  Widget _navItem(int i, IconData icon, String label) {
    final on = _idx == i;
    final c = on ? kRed : _inkMuted;
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
          color: kCream,
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
                          color: _idx == 2 ? kRed : _inkMuted)),
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

  Widget _hero() => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B3A73), kNavySoft]),
          ),
          child: Stack(children: [
            Positioned(
              right: -20,
              bottom: -10,
              child: Icon(Icons.directions_car_filled_rounded, size: 170, color: Colors.white.withOpacity(.08)),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 5, color: kRed)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Drive\nCleaner,\nGo Further.',
                      style: GoogleFonts.orbitron(
                          color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kCream,
                      foregroundColor: kNavy,
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
          final active = app.myBookings.where((b) => b.status < 3).toList()..sort((a, b) => a.slot.compareTo(b.slot));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Halo, $first!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kCream)),
                    const Text('Jaga mobilmu tetap prima.', style: TextStyle(color: _creamMuted)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => onGo(4),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: kCream,
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                ),
              ]),
            ),
            _hero(),
            const SizedBox(height: 16),
            _Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(children: [
                  _quick(Icons.event_available, 'Booking', () => onGo(2)),
                  _quick(Icons.receipt_long, 'Pesanan', () => onGo(1)),
                  _quick(Icons.local_car_wash, 'Layanan', () => onGo(3)),
                  _quick(Icons.person_outline, 'Akun', () => onGo(4)),
                ]),
              ]),
            ),
            _sec('Cucian aktif'),
            if (active.isEmpty)
              _Panel(
                child: Row(children: [
                  const Icon(Icons.local_car_wash_outlined, size: 32, color: _inkMuted),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Belum ada cucian aktif.', style: TextStyle(color: _inkMuted))),
                  TextButton(onPressed: () => onGo(2), child: const Text('Booking')),
                ]),
              )
            else
              _ActiveCard(active.first),
          ]);
        },
      );
}

class _ActiveCard extends StatelessWidget {
  final Booking b;
  const _ActiveCard(this.b);
  @override
  Widget build(BuildContext context) => _Panel(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: kNavy, child: Icon(_vehicleIcon(b.vehicle), color: kCream)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b.pack.name} • ${b.plate}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(_fmt.format(b.slot), style: const TextStyle(fontSize: 12.5, color: _inkMuted)),
              ]),
            ),
            _StatusChip(b.status),
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
            const Icon(Icons.timer_outlined, size: 16, color: _inkMuted),
            const SizedBox(width: 6),
            Text('Estimasi selesai ${_hm.format(b.estFinish)}',
                style: const TextStyle(fontSize: 12.5, color: _inkMuted)),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kRed : Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(v.label,
              style: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : kCream)),
        ),
      ),
    );
  }

  Widget _serviceCard(WashPackage p) {
    final popular = p.name == 'Reguler';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B3A73), kNavySoft]),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned(right: -10, bottom: -14, child: Icon(_packIcon(p), size: 130, color: Colors.white.withOpacity(.06))),
          if (popular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                    color: kRed, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                child: const Text('Populer',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(14)),
                child: Icon(_packIcon(p), color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(p.desc, style: const TextStyle(color: _creamMuted, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 14, color: _creamMuted),
                const SizedBox(width: 4),
                Text('${p.minutes} menit', style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Text(rp(p.priceFor(_v)),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => widget.onGo(2, pack: p, vehicle: _v),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        _header('Layanan Kami', 'Pilih kendaraan, lihat harga tiap paket.'),
        Row(children: [for (final v in VehicleType.values) _pill(v)]),
        const SizedBox(height: 16),
        for (final p in packages) _serviceCard(p),
      ]);
}

// ---------- BOOKING ----------
class BookingScreen extends StatefulWidget {
  final VoidCallback onDone;
  final WashPackage? initialPack;
  final VehicleType? initialVehicle;
  const BookingScreen({super.key, required this.onDone, this.initialPack, this.initialVehicle});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late VehicleType _v = widget.initialVehicle ?? VehicleType.mobil;
  late WashPackage _p = widget.initialPack ?? packages[1];
  final _plate = TextEditingController();
  int _dayOffset = 0;
  int? _hour;

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  DateTime get _day {
    final n = DateTime.now().add(Duration(days: _dayOffset));
    return DateTime(n.year, n.month, n.day);
  }

  void _submit() {
    final nav = Navigator.of(context);
    final b = app.create(_v, _p, _plate.text.trim(), _day.add(Duration(hours: _hour!)));
    widget.onDone();
    nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: b.id)));
  }

  Widget _choice({required bool selected, required VoidCallback? onTap, required Widget child, double vertical = 14}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: vertical),
          decoration: BoxDecoration(
            color: selected ? kRed : Colors.white.withOpacity(.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kRed : Colors.white.withOpacity(.14)),
          ),
          child: child,
        ),
      );

  Widget _vehicleTile(VehicleType v) {
    final sel = _v == v;
    final fg = sel ? Colors.white : kCream;
    return _choice(
      selected: sel,
      onTap: () => setState(() => _v = v),
      vertical: 16,
      child: Column(children: [
        Icon(_vehicleIcon(v), size: 30, color: fg),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? kRed : Colors.transparent, width: 2.5),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(14)),
              child: Icon(_packIcon(p), color: kCream),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                Text(p.desc, style: const TextStyle(fontSize: 12.5, color: _inkMuted)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 14, color: _inkMuted),
                  const SizedBox(width: 4),
                  Text('${p.minutes} menit', style: const TextStyle(fontSize: 12, color: _inkMuted)),
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
    final fg = sel ? Colors.white : kCream;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
        child: _choice(
          selected: sel,
          onTap: () => setState(() {
            _dayOffset = i;
            _hour = null;
          }),
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
    final full = app.slotCount(_day, h) >= AppState.maxPerSlot;
    final off = past || full;
    final sel = _hour == h;
    final fg = sel ? Colors.white : (off ? Colors.white30 : kCream);
    return SizedBox(
      width: 82,
      child: _choice(
        selected: sel,
        onTap: off ? null : () => setState(() => _hour = h),
        vertical: 10,
        child: Column(children: [
          Text('${h.toString().padLeft(2, '0')}:00', style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
          Text(full ? 'Penuh' : (past ? 'Lewat' : 'Tersedia'),
              style: TextStyle(fontSize: 10.5, color: full ? const Color(0xFFFF7B7B) : fg)),
        ]),
      ),
    );
  }

  Widget _bottomBar(DateTime? slot) {
    final ready = slot != null && _plate.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: kNavySoft,
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(rp(_p.priceFor(_v)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCream)),
            Text(slot == null ? 'Pilih jam kedatangan' : 'Selesai sekitar ${_hm.format(app.estimate(slot, _p))}',
                style: const TextStyle(fontSize: 12.5, color: _creamMuted)),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: ready ? _submit : null,
          icon: const Icon(Icons.event_available),
          label: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.w800)),
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
          _header('Booking Cuci', 'Pilih kendaraan, paket, dan jam kedatangan.'),
          const Text('Jenis kendaraan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kCream)),
          const SizedBox(height: 10),
          Row(children: [
            for (final v in VehicleType.values)
              Expanded(child: Padding(padding: EdgeInsets.only(right: v == VehicleType.suv ? 0 : 10), child: _vehicleTile(v))),
          ]),
          const SizedBox(height: 12),
          Theme(
            data: _cardTheme,
            child: TextField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Plat nomor',
                hintText: 'mis. L 1234 AB',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                filled: true,
                fillColor: kCream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kRed, width: 2)),
              ),
            ),
          ),
          _sec('Paket cuci'),
          for (final p in packages) _packTile(p),
          _sec('Tanggal', top: 12),
          Row(children: [for (var i = 0; i < 3; i++) _dayTile(i)]),
          _sec('Jam kedatangan'),
          Wrap(spacing: 8, runSpacing: 8, children: [for (var h = 8; h <= 17; h++) _hourTile(h)]),
        ]),
      ),
      _bottomBar(slot),
    ]);
  }
}

// ---------- RIWAYAT PESANAN ----------
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final list = app.myBookings;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            _header('Riwayat Pesanan', 'Semua pesanan cucimu ada di sini.'),
            if (list.isEmpty)
              const _Panel(
                padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: _inkMuted),
                    SizedBox(height: 10),
                    Text('Belum ada pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Pesanan yang kamu buat akan muncul di sini.', style: TextStyle(color: _inkMuted)),
                  ]),
                ),
              ),
            for (final b in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Panel(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: kNavy, child: Icon(_vehicleIcon(b.vehicle), color: kCream)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${b.pack.name} • ${b.plate}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(_fmt.format(b.slot), style: const TextStyle(fontSize: 12.5, color: _inkMuted)),
                        const SizedBox(height: 6),
                        _StatusChip(b.status),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: _inkMuted),
                  ]),
                ),
              ),
          ]);
        },
      );
}

// ---------- TRACKING ANTREAN CUCI + TIKET QR ----------
class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  Future<void> _pdf(Booking b) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('CleanDrive - Bukti Transaksi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text('Kode: ${b.code}'),
          pw.Text('Kendaraan: ${b.vehicle.label} (${b.plate})'),
          pw.Text('Paket: ${b.pack.name}'),
          pw.Text('Jadwal: ${_fmt.format(b.slot)}'),
          pw.Text('Estimasi selesai: ${_fmt.format(b.estFinish)}'),
          pw.Text('Status: ${statusLabels[b.status]}'),
          pw.SizedBox(height: 8),
          pw.Text('Total: ${rp(b.price)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.BarcodeWidget(data: b.code, barcode: pw.Barcode.qrCode(), width: 100, height: 100),
        ])));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'bukti-${b.id}.pdf');
  }

  DateTime _stageTime(Booking b, int i) {
    const f = [0.0, .3, .8, 1.0];
    final total = b.estFinish.difference(b.slot).inMinutes;
    return b.slot.add(Duration(minutes: (total * f[i]).round()));
  }

  Widget _stepper(int stage) {
    const names = ['Booking', 'Proses', 'Selesai'];
    Widget dot(int i) {
      final done = i < stage, cur = i == stage;
      return Column(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cur ? kRed : (done ? kNavy : const Color(0x1F0B1F44)),
          ),
          child: (done || cur) ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(names[i],
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: (done || cur) ? kNavy : _inkMuted)),
      ]);
    }

    Widget line(int i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
            child: Container(height: 2, color: i < stage ? kNavy : const Color(0x1F0B1F44)),
          ),
        );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [dot(0), line(0), dot(1), line(1), dot(2)]);
  }

  Widget _timeline(Booking b) => Column(children: [
        for (var i = 0; i < 4; i++)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= b.status ? kRed : const Color(0x330B1F44),
                ),
              ),
              if (i < 3) Container(width: 2, height: 30, color: i < b.status ? kRed : const Color(0x1F0B1F44)),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_stageNames[i],
                  style: TextStyle(
                      fontWeight: i == b.status ? FontWeight.w800 : FontWeight.w600,
                      color: i <= b.status ? kNavy : _inkMuted)),
            ),
            Text('${i > b.status ? '~' : ''}${_hm.format(_stageTime(b, i))}',
                style: TextStyle(fontWeight: FontWeight.w700, color: i <= b.status ? kNavy : _inkMuted)),
          ]),
      ]);

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: Text(k, style: const TextStyle(color: _inkMuted))),
          Expanded(
            flex: 3,
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.bookings.firstWhere((x) => x.id == id);
          final stage = b.status == 0 ? 0 : (b.status == 3 ? 2 : 1);
          return Scaffold(
            appBar: AppBar(title: const Text('Tracking Antrean Cuci')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  _Panel(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    child: Column(children: [
                      _stepper(stage),
                      const SizedBox(height: 20),
                      Text(_headlines[b.status],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        const TextSpan(text: 'Estimasi selesai: ', style: TextStyle(color: _inkMuted)),
                        TextSpan(
                            text: _hm.format(b.estFinish),
                            style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
                      ])),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: (b.status + 1) / 4,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              color: kRed,
                              backgroundColor: const Color(0x140B1F44),
                            ),
                          ),
                          Icon(_vehicleIcon(b.vehicle), size: 70, color: kNavy),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(statusLabels[b.status], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(height: 22),
                      _timeline(b),
                    ]),
                  ),
                  _sec('Tiket Masuk'),
                  _Panel(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x1F0B1F44)),
                        ),
                        child: QrImageView(data: b.code, size: 170, backgroundColor: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(b.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const Text('Tunjukkan QR ini ke petugas saat tiba',
                          style: TextStyle(fontSize: 12.5, color: _inkMuted)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (b.verified ? _statusColors[3] : _statusColors[0]).withOpacity(.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(b.verified ? Icons.verified : Icons.hourglass_empty,
                              size: 16, color: b.verified ? _statusColors[3] : _statusColors[0]),
                          const SizedBox(width: 6),
                          Text(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi petugas',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: b.verified ? _statusColors[3] : _statusColors[0])),
                        ]),
                      ),
                      const Divider(height: 28),
                      _kv('No. Pesanan', '#${b.id}'),
                      _kv('Kendaraan', '${b.vehicle.label} • ${b.plate}'),
                      _kv('Paket', b.pack.name),
                      _kv('Jadwal', _fmt.format(b.slot)),
                      _kv('Total', rp(b.price), bold: true),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _pdf(b),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Cetak Bukti PDF', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          );
        },
      );
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
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              app.updateProfile(name.text.trim(), phone.text.trim());
              Navigator.pop(ctx);
              _toast(context, 'Profil diperbarui');
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
              onPressed: () {
                if (newC.text.length < 6) {
                  setS(() => err = 'Password baru minimal 6 karakter');
                } else if (newC.text != conC.text) {
                  setS(() => err = 'Konfirmasi password tidak sama');
                } else if (!app.changePassword(oldC.text, newC.text)) {
                  setS(() => err = 'Password lama salah');
                } else {
                  Navigator.pop(ctx);
                  _toast(context, 'Password berhasil diubah');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text('Kamu perlu masuk lagi untuk melihat pesananmu.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                app.logout();
              },
              child: const Text('Keluar'),
            ),
          ],
        ),
      );

  Widget _menu(IconData icon, String title, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, color: _inkMuted),
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
                Stack(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: kCream,
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(color: kNavy, fontSize: 36, fontWeight: FontWeight.w800)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: kNavy, width: 3),
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCream)),
                if (app.email.isNotEmpty) Text(app.email, style: const TextStyle(color: _creamMuted)),
                if (app.phone.isNotEmpty) Text(app.phone, style: const TextStyle(color: _creamMuted)),
              ]),
            ),
            const SizedBox(height: 22),
            _Panel(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _menu(Icons.receipt_long_outlined, 'Pesanan Saya', () => onGo(1)),
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
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Aplikasi booking dan tracking antrean cuci kendaraan.',
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            _Panel(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onTap: () => _confirmLogout(context),
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
