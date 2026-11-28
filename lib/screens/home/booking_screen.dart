import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';
import '../../models/models.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../profile/help.dart';
import '../shop/shop.dart';
import 'customer.dart' show ConfirmOrderScreen;

// ===========================================================================
// BOOKING (tab ke-3 di HomeScreen): cuci atau ganti oli.
// Alur: 1 Pilih kendaraan -> 2 Pilih paket (atau oli) -> 3 Jadwal
//       -> 4 Ringkasan -> Lanjutkan (ke ConfirmOrderScreen yang sudah ada).
// Logika lama dipertahankan: harga per kendaraan, kuota slot per jam, estimasi
// antrean, garasi, plat nomor, mode Ganti Oli + stok oli.
// "Pilih Outlet" tidak ada di alur ini (data outlet tetap ada di fitur Lokasi Outlet).
// ===========================================================================

// Palet sama dengan Beranda: navy #08265C, royal #164A9B, gold #FFBE27, latar #F5F7FC.
const _kNavy = Color(0xFF08265C);
const _kBlue = Color(0xFF164A9B);
const _kGold = Color(0xFFFFBE27);
const _kRed = Color(0xFFC62026); // merah: elemen yang dipilih / bisa diklik
const _kBg = Color(0xFFF5F7FC);

// Batas layout layar lebar (laptop/desktop) untuk tampilan 2 kolom.
const double _kWideContentMin = 820;
const double _kWidePad = 28;

const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

const _softShadow = [BoxShadow(color: Color(0x1A08265C), blurRadius: 20, offset: Offset(0, 8))];

class BookingScreen extends StatefulWidget {
  final WashPackage? initialPack;
  final VehicleType? initialVehicle;
  final Product? initialOil; // oli yang sudah dipilih di toko

  /// Dipanggil saat tombol kembali ditekan (HomeScreen mengarahkan ke Beranda).
  final VoidCallback? onBack;
  const BookingScreen({super.key, this.initialPack, this.initialVehicle, this.initialOil, this.onBack});
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

  /// Ganti kendaraan: paket, harga, dan ringkasan ikut menyesuaikan; oli yang tidak cocok dilepas.
  void _setVehicle(VehicleType v) => setState(() {
        _v = v;
        final o = _oil;
        if (o != null && !o.fits(v)) _oil = null;
      });

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

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

  String _hh(int h) => '${h.toString().padLeft(2, '0')}.00';

  static String _tagline(WashPackage p) {
    switch (p.name) {
      case 'Express':
        return 'Cuci cepat dan praktis';
      case 'Reguler':
        return 'Cuci kendaraan secara menyeluruh';
      case 'Detailing':
        return 'Perawatan kendaraan secara menyeluruh';
      default:
        return p.desc;
    }
  }

  // -------------------------------------------------------------------------
  // KOMPONEN
  // -------------------------------------------------------------------------
  Widget _stepTitle(int n, String title, String sub, {double top = 22}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _kNavy, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kNavy)),
              Text(sub, style: const TextStyle(fontSize: 12.5, color: _kBlue)),
            ]),
          ),
        ]),
      );

  Widget _modeToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: _softShadow),
        child: Stack(children: [
          // Penanda merah yang meluncur ke tombol terpilih (Cuci atau Ganti Oli).
          Positioned.fill(
            child: AnimatedAlign(
              alignment: _isOil ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x44C62026), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                ),
              ),
            ),
          ),
          Row(children: [
            Expanded(child: _modeBtn('Cuci', Icons.local_car_wash_rounded, !_isOil, () => _setOilMode(false))),
            Expanded(child: _modeBtn('Ganti Oli', Icons.opacity_rounded, _isOil, () => _setOilMode(true))),
          ]),
        ]),
      );

  /// Tombol mode: warna ikon dan teks berubah halus (putih di atas penanda merah, navy bila tidak dipilih).
  Widget _modeBtn(String label, IconData icon, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Pressable(
          scale: 0.96,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: sel ? Colors.white : _kNavy),
              duration: const Duration(milliseconds: 260),
              builder: (context, color, _) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 7),
                Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              ]),
            ),
          ),
        ),
      );

  /// Kartu kendaraan bergambar dengan tanda pilihan (centang) di pojok kanan atas.
  Widget _vehicleCard(VehicleType v) {
    final sel = _v == v;
    final img = v == VehicleType.motor ? 'assets/images/booking_vehicle_motor.png' : 'assets/images/booking_vehicle_mobil.png';
    return GestureDetector(
      onTap: () => _setVehicle(v),
      child: Pressable(
        scale: 0.97,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 156,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sel ? const [Color(0xFFDCE8FF), Color(0xFFEEF4FF)] : const [Colors.white, Color(0xFFF6F9FF)],
          ),
          border: Border.all(color: sel ? _kRed : const Color(0xFFE3EAF7), width: sel ? 2.5 : 1),
          boxShadow: _softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              bottom: 46,
              child: Image.asset(img, fit: BoxFit.contain),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: sel
                    ? Container(
                        key: const ValueKey('on'),
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
                      )
                    : Container(
                        key: const ValueKey('off'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFC9D5EC), width: 2)),
                      ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                height: 34,
                decoration: BoxDecoration(color: _kBlue.withValues(alpha: sel ? .12 : .06), borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(vehicleIcon(v), color: _kNavy, size: 21),
                  const SizedBox(width: 8),
                  Text(v.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kNavy)),
                ]),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  /// Kolom plat nomor. (Pilihan cepat "Pilih dari garasi" sudah dihapus dari tampilan.)
  Widget _garageAndPlate() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: _softShadow),
          child: TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Plat nomor',
              hintText: 'mis. L 1234 AB',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ]);

  Widget _radio(bool sel) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: sel ? _kBlue : const Color(0xFFC9D5EC), width: 2),
        ),
        child: sel
            ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle)))
            : null,
      );

  Widget _packCard(WashPackage p) {
    final sel = _p == p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _p = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFF3F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? _kBlue : const Color(0xFFE3EAF7), width: sel ? 2.5 : 1),
            boxShadow: _softShadow,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: ServiceThumb(p, _v, width: 96)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(p.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kNavy)),
                  ),
                  if (p.name == 'Reguler')
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Populer', style: TextStyle(color: _kNavy, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(_tagline(p), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _kBlue, height: 1.25)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.schedule_rounded, size: 15, color: _kNavy),
                  const SizedBox(width: 4),
                  Text('± ${p.minutes} menit', style: const TextStyle(fontSize: 12, color: _kNavy, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _radio(sel),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _kBlue.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text('Harga ${_v.label}', style: const TextStyle(fontSize: 10, color: _kBlue)),
                  Text(rp(p.priceFor(_v)), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _kBlue)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _oilCard(Product o) {
    final sel = _oil?.id == o.id;
    final left = app.stockOf(o);
    final out = left <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: out ? null : () => setState(() => _oil = o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFF3F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? _kBlue : const Color(0xFFE3EAF7), width: sel ? 2.5 : 1),
            boxShadow: _softShadow,
          ),
          child: Row(children: [
            SizedBox(width: 66, height: 66, child: Opacity(opacity: out ? .4 : 1, child: ProductImage(o))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: _kNavy)),
                Text(o.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _kBlue)),
                if (out)
                  const Text('Stok habis', style: TextStyle(fontSize: 12, color: Color(0xFFB3261E), fontWeight: FontWeight.w800))
                else if (left < kLowStock)
                  Text('Sisa $left', style: const TextStyle(fontSize: 12, color: Color(0xFFD08A00), fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _radio(sel),
              const SizedBox(height: 8),
              Text(rp(o.price), style: const TextStyle(fontWeight: FontWeight.w800, color: _kBlue, fontSize: 13.5)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _dayChip(int i) {
    final d = DateTime.now().add(Duration(days: i));
    final sel = _dayOffset == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dayOffset = i;
            _hour = null;
          });
          _loadCounts();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 66,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? _kRed : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: sel ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 14, offset: Offset(0, 6))] : _softShadow,
          ),
          child: Column(children: [
            Text(i == 0 ? 'Hari ini' : _dayNames[d.weekday - 1],
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : _kNavy)),
            const SizedBox(height: 2),
            Text('${d.day} ${_monthNames[d.month - 1]}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : _kNavy)),
          ]),
        ),
      ),
    );
  }

  Widget _hourChip(int h, double width) {
    final past = _day.add(Duration(hours: h)).isBefore(DateTime.now());
    final full = _count(h) >= AppState.maxPerSlot;
    final off = past || full;
    final sel = _hour == h;
    final fg = sel ? Colors.white : (off ? const Color(0x5208265C) : _kNavy);
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: off ? null : () => setState(() => _hour = h),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? _kRed : (off ? const Color(0xFFEAEFF9) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            boxShadow: off ? null : (sel ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 14, offset: Offset(0, 6))] : _softShadow),
          ),
          child: Column(children: [
            Text(_hh(h), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: fg)),
            Text(full ? 'Penuh' : (past ? 'Lewat' : 'Tersedia'),
                style: TextStyle(fontSize: 10, color: full ? const Color(0xFFD64545) : fg)),
          ]),
        ),
      ),
    );
  }

  Widget _summaryCard(DateTime? slot) {
    final dateText = slot == null
        ? 'Pilih tanggal & jam kedatangan'
        : '${_dayNames[slot.weekday - 1]}, ${slot.day} ${_monthNames[slot.month - 1]} ${slot.year}  |  ${_hh(slot.hour)} WIB';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: _softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: _kBlue.withValues(alpha: .10), borderRadius: BorderRadius.circular(15)),
            child: Icon(_isOil ? Icons.opacity_rounded : Icons.local_car_wash_rounded, color: _kBlue, size: 27),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kNavy)),
          ),
        ]),
        const Divider(height: 22),
        kv('Kendaraan', _v.label),
        kv(_isOil ? 'Layanan' : 'Paket cuci', _p.title),
        if (_isOil) kv('Oli', _oil?.name ?? 'Belum dipilih'),
        kv('Nomor polisi', _plate.text.trim().isEmpty ? '-' : _plate.text.trim().toUpperCase()),
        kv('Jadwal', dateText),
        kv('Estimasi pengerjaan', slot == null ? '± ${_p.minutes} menit' : '± ${_p.minutes} menit (selesai ${fmtHm.format(_estimate(slot))})'),
        const Divider(height: 18),
        Row(children: [
          const Expanded(child: Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, color: _kNavy))),
          Text(rp(_price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kBlue)),
        ]),
      ]),
    );
  }

  /// Status tombol Lanjutkan: aktif hanya bila semua pilihan wajib terisi.
  (bool, String?) _ctaState(DateTime? slot) {
    final oilReady = !_isOil || _oil != null;
    final plateReady = _plate.text.trim().isNotEmpty;
    final ready = slot != null && plateReady && oilReady;
    final hint = !plateReady
        ? 'Isi plat nomor kendaraan'
        : (!oilReady ? 'Pilih oli dulu' : (slot == null ? 'Pilih tanggal dan jam kedatangan' : null));
    return (ready, hint);
  }

  Widget _hintRow(String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: kMuted),
          const SizedBox(width: 6),
          Text(hint, style: const TextStyle(fontSize: 12.5, color: kMuted)),
        ]),
      );

  /// Tombol merah "Lanjutkan".
  Widget _ctaButton(bool ready) => Opacity(
        opacity: ready ? 1 : .45,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(colors: [Color(0xFFE5393F), kRed], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            boxShadow: ready ? const [BoxShadow(color: Color(0x66C62026), blurRadius: 16, offset: Offset(0, 7))] : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(27),
              onTap: ready ? _next : null,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Lanjutkan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ]),
            ),
          ),
        ),
      );

  /// HP: bilah bawah menempel berisi total + tombol Lanjutkan.
  Widget _bottomBar(DateTime? slot) {
    final (ready, hint) = _ctaState(slot);
    final pad = pagePad(MediaQuery.sizeOf(context).width);
    return Container(
      padding: EdgeInsets.fromLTRB(pad, 10, pad, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x1F08265C), blurRadius: 18, offset: Offset(0, -6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (hint != null) _hintRow(hint),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Total', style: TextStyle(fontSize: 12, color: kMuted)),
            Text(rp(_price), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _kBlue)),
          ]),
          const SizedBox(width: 16),
          Expanded(child: _ctaButton(ready)),
        ]),
      ]),
    );
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final slot = _hour == null ? null : _day.add(Duration(hours: _hour!));
    final oils = productsIn(ProductCategory.oli).where((o) => o.fits(_v)).toList();

    return Container(
      color: _kBg,
      child: LayoutBuilder(builder: (context, c) {
        // Layar lebar (laptop/desktop): dua kolom. Kiri = langkah 1-2, kanan = langkah 3-4 + tombol Lanjutkan.
        final wide = c.maxWidth >= _kWideContentMin;
        final pad = wide ? _kWidePad : pagePad(c.maxWidth);

        final modeAndRating = <Widget>[
          _modeToggle(),
          ListenableBuilder(
            listenable: app,
            builder: (context, _) => app.rating.count > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      StarRow(app.rating.avg, size: 17),
                      const SizedBox(width: 8),
                      Text('${app.rating.avg.toStringAsFixed(1)} dari ${app.rating.count} ulasan',
                          style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ]),
                  )
                : const SizedBox.shrink(),
          ),
        ];

        // ---- 1 + 2: kendaraan, paket / oli ----
        final stepsOneTwo = <Widget>[
          _stepTitle(1, 'Pilih Jenis Kendaraan', _isOil ? 'Pilih kendaraan yang akan diganti olinya' : 'Pilih kendaraan yang akan dicuci', top: 18),
          Row(children: [
            for (final v in VehicleType.values)
              Expanded(child: Padding(padding: EdgeInsets.only(right: v == VehicleType.values.last ? 0 : 12), child: _vehicleCard(v))),
          ]),
          _garageAndPlate(),
          if (_isOil) ...[
            _stepTitle(2, 'Pilih Oli', 'Jasa ${rp(_p.priceFor(_v))} untuk ${_v.label}. Harga oli ditambahkan.'),
            ListenableBuilder(
              listenable: app,
              builder: (context, _) => Column(children: [for (final o in oils) _oilCard(o)]),
            ),
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 15, color: kMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text('Oli wajib dibeli dari CleanDrive. Oli dari luar tidak diperbolehkan.',
                    style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
              ),
            ]),
          ] else ...[
            _stepTitle(2, 'Pilih Paket Cuci', 'Pilih layanan yang sesuai dengan kebutuhan Anda'),
            for (final p in packages) _packCard(p),
          ],
        ];

        // ---- 3 + 4: jadwal, ringkasan ----
        final stepsThreeFour = <Widget>[
          _stepTitle(3, 'Pilih Jadwal', 'Pilih tanggal dan waktu booking', top: wide ? 18 : 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(children: [for (var i = 0; i < 7; i++) _dayChip(i)]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kBlue.withValues(alpha: .06), borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.schedule_rounded, size: 16, color: _kBlue),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Jam operasional 08.00 - 17.00 WIB. Jam penuh atau lewat tidak bisa dipilih.',
                      style: TextStyle(color: _kBlue, fontSize: 12, height: 1.3)),
                ),
              ]),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, c) {
                const gap = 8.0;
                final w = (c.maxWidth - gap * 3) / 4;
                if (_loadingSlots) {
                  return Wrap(spacing: gap, runSpacing: gap, children: [for (var h = 8; h <= 17; h++) Skeleton(width: w, height: 48, radius: 16)]);
                }
                return Wrap(spacing: gap, runSpacing: gap, children: [for (var h = 8; h <= 17; h++) _hourChip(h, w)]);
              }),
            ]),
          ),
          _stepTitle(4, 'Ringkasan Pesanan', 'Periksa kembali sebelum melanjutkan', top: 22),
          _summaryCard(slot),
        ];

        final Widget content;
        if (wide) {
          final (ready, hint) = _ctaState(slot);
          content = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 11, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: stepsOneTwo)),
            const SizedBox(width: 28),
            Expanded(
              flex: 9,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ...stepsThreeFour,
                const SizedBox(height: 16),
                if (hint != null) _hintRow(hint),
                _ctaButton(ready),
              ]),
            ),
          ]);
        } else {
          content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...stepsOneTwo, ...stepsThreeFour]);
        }

        return Column(children: [
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _BookingHeader(
                wide: wide,
                title: _isOil ? 'Ganti Oli' : 'Booking Cuci',
                oil: _isOil,
                onBack: _back,
                onSupport: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // di layar lebar, pilihan Cuci/Ganti Oli dibatasi lebarnya agar tidak melebar
                  if (wide)
                    Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(children: modeAndRating)))
                  else
                    ...modeAndRating,
                  // Ganti mode: isi bergeser (Cuci ke kanan, Ganti Oli ke kiri) dan tinggi berubah halus.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: SwipeSwitcher(index: _isOil ? 1 : 0, child: content),
                  ),
                ]),
              ),
            ]),
          ),
          if (!wide) _bottomBar(slot),
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER BOOKING: tombol kembali, judul, bantuan, logo, tagline, mobil + efek air.
// ---------------------------------------------------------------------------
class _BookingHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack, onSupport;
  final bool wide;

  /// true = mode Ganti Oli: gambar mobil diganti gambar oli.
  final bool oil;
  const _BookingHeader({required this.title, required this.onBack, required this.onSupport, this.wide = false, this.oil = false});

  Widget _circle(IconData icon, VoidCallback onTap, String tip) => Tooltip(
        message: tip,
        child: Material(
          color: Colors.white.withValues(alpha: .12),
          shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: .25))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white, size: 26)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final top = wide ? 4.0 : MediaQuery.paddingOf(context).top;
    final radius = wide ? BorderRadius.circular(34) : const BorderRadius.vertical(bottom: Radius.circular(34));
    return Container(
      margin: wide ? const EdgeInsets.fromLTRB(_kWidePad, 24, _kWidePad, 0) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_kNavy, Color(0xFF0B3380), _kBlue]),
        boxShadow: const [BoxShadow(color: Color(0x4008265C), blurRadius: 26, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment(.8, -.5), radius: 1.1, colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)]),
              ),
            ),
          ),
          // Gambar mobil (Cuci) dan botol oli (Ganti Oli) bertukar dengan geser + pudar.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween<Offset>(begin: const Offset(.12, 0), end: Offset.zero).animate(anim), child: child),
              ),
              child: oil
                  // Mode Ganti Oli: gambar oli (background transparan) menggantikan gambar mobil.
                  ? Stack(key: const ValueKey('oil'), children: [
                      Positioned(
                        right: wide ? 16 : 4,
                        bottom: wide ? 8 : 6,
                        child: IgnorePointer(child: Image.asset('assets/images/booking_header_oil.png', height: wide ? 270 : 185, fit: BoxFit.contain)),
                      ),
                    ])
                  // Mode Cuci: gambar mobil.
                  : Stack(key: const ValueKey('car'), children: [
                      Positioned(
                        right: wide ? -10 : -34,
                        bottom: 0,
                        child: IgnorePointer(child: Image.asset('assets/images/booking_header_car.png', width: wide ? 560 : 330, fit: BoxFit.fitWidth)),
                      ),
                    ]),
            ),
          ),
          Padding(
            padding: wide ? const EdgeInsets.fromLTRB(24, 22, 24, 26) : EdgeInsets.fromLTRB(16, top + 10, 16, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // tombol kembali dihapus; ruang kosong menjaga judul tetap di tengah
                const SizedBox(width: 46, height: 46),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(title,
                        key: ValueKey(title),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: wide ? 26 : 22, fontWeight: FontWeight.w800)),
                  ),
                ),
                _circle(Icons.headset_mic_outlined, onSupport, 'Bantuan'),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Image.asset('assets/images/profile_logo_mark.png', height: 34),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Clean', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Drive', style: TextStyle(color: _kGold)),
                  ]),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.3),
                ),
              ]),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
                child: Text.rich(
                  // slogan mengikuti mode: Cuci vs Ganti Oli
                  oil
                      ? const TextSpan(children: [
                          TextSpan(text: 'Oli Berkualitas,\nMesin Lebih '),
                          TextSpan(text: 'Awet & Bertenaga', style: TextStyle(color: _kGold)),
                        ])
                      : const TextSpan(children: [
                          TextSpan(text: 'Mobil Bersih,\nPerjalanan '),
                          TextSpan(text: 'Lebih Nyaman', style: TextStyle(color: _kGold)),
                        ]),
                  key: ValueKey(oil),
                  style: TextStyle(color: Colors.white, fontSize: wide ? 20 : 15, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
              SizedBox(height: wide ? 60 : 40),
            ]),
          ),
        ]),
      ),
    );
  }
}