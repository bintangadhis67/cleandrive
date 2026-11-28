import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../garage/garage.dart';
import '../orders/orders.dart';
import '../rewards/reward_ui.dart';
import 'profile_widgets.dart';

// ===========================================================================
// LAYAR-LAYAR YANG DIBUKA DARI HALAMAN AKUN:
//  - EditProfileScreen          (Edit Profil)
//  - TransactionHistoryScreen   (Riwayat Transaksi)
//  - BookingHistoryScreen       (Riwayat Booking)
//  - VehicleCareHistoryScreen   (Riwayat Perawatan Kendaraan)
//  - AccountSecurityScreen      (Keamanan Akun)
// Semua memakai data asli dari `app` (bookings, garage, me), bukan data palsu.
// ===========================================================================

/// Kembali ke Home lalu pindah ke tab Booking.
void _goBooking(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  app.requestTab(2);
}

/// Pil filter horizontal (konsisten dengan halaman Riwayat).
class _Pills extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  const _Pills({required this.labels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSelect(i),
                // Menyusut saat ditekan + berdenyut kecil saat terpilih.
                child: Pressable(
                  scale: 0.94,
                  child: Pop(
                    trigger: selected == i,
                    enabled: selected == i,
                    amount: 1.08,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected == i ? kRed : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: selected == i ? kRed : kLine),
                      ),
                      child: Text(labels[i],
                          style: TextStyle(fontWeight: FontWeight.w700, color: selected == i ? Colors.white : kProNavy)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      );
}

Future<void> _refresh() async {
  try {
    await app.refreshAll();
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// EDIT PROFIL
// ---------------------------------------------------------------------------
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: app.user ?? '');
  late final TextEditingController _phone = TextEditingController(text: app.phone);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      await app.updateProfile(_name.text.trim(), _phone.text.trim());
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      toast(context, 'Profil diperbarui');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _name.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: PageList(
        top: 16,
        bottom: 32,
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [kProNavy, kProRoyal], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Text(n.isEmpty ? '?' : n[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Avatar memakai inisial nama kamu', style: TextStyle(color: kMuted, fontSize: 12.5)),
          ),
          const SizedBox(height: 20),
          Panel(
            child: Form(
              key: _form,
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline_rounded)),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No. HP', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    if (t.replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'Nomor HP tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: app.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Email tidak dapat diubah',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          RedButton('Simpan Perubahan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIWAYAT TRANSAKSI
// ---------------------------------------------------------------------------
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _filter = 0; // 0 semua, 1 layanan, 2 toko
  int _dir = 1; // arah geser terakhir: 1 = ke pil di kanan, -1 = ke kiri
  int _gen = 0; // naik tiap ganti filter, supaya daftar masuk ulang dengan animasi
  final Object _token = Object(); // pembeda tiap kali layar dibuka

  Widget _stat(IconData icon, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: kProGold, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          ]),
        ),
      );

  Widget _summary(List<Booking> tx) {
    final done = tx.where((b) => b.paid && !b.cancelled);
    final spent = done.fold<int>(0, (s, b) => s + b.total);
    final coins = done.fold<int>(0, (s, b) => s + b.coinsEarned);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [kProNavy, kProRoyal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color(0x3308265C), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 2),
        Text(rp(spent), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          _stat(Icons.receipt_long_rounded, 'Transaksi', '${done.length}'),
          const SizedBox(width: 10),
          _stat(Icons.toll_rounded, 'Coins didapat', '$coins'),
        ]),
      ]),
    );
  }

  Widget _card(Booking b) {
    final method = b.freeWash ? 'Cuci gratis membership' : (b.payMethod?.label ?? (b.paid ? 'Lunas' : 'Belum dibayar'));
    final refunded = b.payStatus == 'refunded';
    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
      child: Row(children: [
        // Gambar sama seperti halaman Riwayat: foto produk (toko) / gambar layanan sesuai kendaraan.
        OrderThumb(b, size: 58),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
            const SizedBox(height: 2),
            Text(fmtDateTime.format(b.slot), style: const TextStyle(color: kMuted, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text('${b.code} • $method', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(b.total <= 0 ? 'Gratis' : rp(b.total),
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: refunded ? kMuted : kProNavy,
                  decoration: refunded ? TextDecoration.lineThrough : null)),
          const SizedBox(height: 4),
          refunded
              ? const Text('Dikembalikan', style: TextStyle(color: kWarn, fontWeight: FontWeight.w700, fontSize: 11.5))
              : StatusChip(b),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat Transaksi')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final tx = app.bookings.where((b) => b.paid || b.payStatus == 'refunded' || b.freeWash).toList()
              ..sort((a, b) => b.slot.compareTo(a.slot));
            final list = switch (_filter) {
              1 => tx.where((b) => !b.pack.isShop).toList(),
              2 => tx.where((b) => b.pack.isShop).toList(),
              _ => tx,
            };
            return RefreshIndicator(
              color: kRed,
              onRefresh: _refresh,
              child: PageList(top: 12, bottom: 32, children: [
                _summary(tx),
                const SizedBox(height: 16),
                _Pills(
                  labels: const ['Semua', 'Layanan', 'Toko'],
                  selected: _filter,
                  onSelect: (i) {
                    if (i == _filter) return;
                    setState(() {
                      _dir = i > _filter ? 1 : -1;
                      _gen++;
                      _filter = i;
                    });
                  },
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  FadeSlideIn(
                    playOnce: (_token, _gen, 'kosong'),
                    dx: 28.0 * _dir,
                    dy: 0,
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada transaksi',
                      message: 'Transaksi yang sudah dibayar akan muncul di sini.',
                      actionLabel: 'Booking Sekarang',
                      onAction: () => _goBooking(context),
                    ),
                  )
                else
                  // Kartu masuk bertahap dari arah geser pil (maks. 8 kartu pertama), sekali per ganti filter.
                  for (var i = 0; i < list.length; i++)
                    FadeSlideIn(
                      key: ValueKey('tx-${list[i].id}'),
                      playOnce: (_token, _gen, list[i].id),
                      delay: Duration(milliseconds: 50 * (i < 8 ? i : 8)),
                      duration: const Duration(milliseconds: 380),
                      dx: 28.0 * _dir,
                      dy: 0,
                      child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(list[i])),
                    ),
              ]),
            );
          },
        ),
      );
}

// ---------------------------------------------------------------------------
// RIWAYAT BOOKING (tema Navy: tab kapsul + kartu putih)
// ---------------------------------------------------------------------------
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});
  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  int _filter = 0; // 0 akan datang / berjalan, 1 selesai, 2 dibatalkan
  int _dir = 1; // arah geser terakhir: 1 = ke tab di kanan, -1 = ke kiri
  int _gen = 0; // naik tiap ganti tab, supaya daftar masuk ulang dengan animasi
  final Object _token = Object(); // pembeda tiap kali layar dibuka

  /// Tab kapsul: aktif = navy + teks putih, tidak aktif = putih + garis tipis.
  Widget _tabs() {
    const labels = ['Akan Datang', 'Selesai', 'Dibatalkan'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                if (_filter == i) return;
                setState(() {
                  _dir = i > _filter ? 1 : -1;
                  _gen++;
                  _filter = i;
                });
              },
              // Menyusut saat ditekan + berdenyut kecil saat terpilih.
              child: Pressable(
                scale: 0.94,
                child: Pop(
                  trigger: _filter == i,
                  enabled: _filter == i,
                  amount: 1.08,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _filter == i ? kRed : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _filter == i ? kRed : kRwLine, width: 1.2),
                    ),
                    child: Text(labels[i],
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _filter == i ? Colors.white : kRwText)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  /// Badge status booking: Menunggu (kuning), Diproses (biru), Selesai (hijau), Dibatalkan (merah).
  Widget _statusBadge(Booking b) {
    if (b.cancelled) return const RwPill('Dibatalkan', bg: Color(0xFFFDE3E5), fg: kRwDanger);
    switch (b.status) {
      case 0:
        return const RwPill('Menunggu', bg: kRwGoldLight, fg: kRwGoldDark);
      case 3:
        return const RwPill('Selesai', bg: Color(0xFFDDF3E8), fg: Color(0xFF148A57));
      default:
        return const RwPill('Diproses', bg: kRwBlueSoft, fg: kRwNavy);
    }
  }

  Widget _card(Booking b) => RwCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(b.code, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText))),
            const SizedBox(width: 8),
            _statusBadge(b),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // Gambar paket layanan (sama seperti kartu di halaman pilih paket Express / Reguler / Detailing)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: b.pack.isOil
                  ? Container(
                      width: 96,
                      height: 58,
                      color: kRwBlueSoft,
                      child: ServiceThumb(b.pack, b.vehicle, width: 96),
                    )
                  : ServiceThumb(b.pack, b.vehicle, width: 96),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.pack.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: kRwText)),
                const SizedBox(height: 2),
                Text('${b.vehicle.label} • ${b.plate}', style: const TextStyle(color: kRwSub, fontSize: 12.5)),
              ]),
            ),
          ]),
          rwDivider(v: 12),
          Row(children: [
            const Icon(Icons.event_rounded, size: 17, color: kRwNavy),
            const SizedBox(width: 6),
            Expanded(child: Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 13, color: kRwText))),
            Text(b.total <= 0 ? 'Gratis' : rp(b.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kRwNavy)),
          ]),
          if (b.active && b.queuePosition > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.groups_rounded, size: 17, color: kRwNavy),
              const SizedBox(width: 6),
              Text('Antrean ke-${b.queuePosition}', style: const TextStyle(fontSize: 12.5, color: kRwSub)),
            ]),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: AppBar(
          title: const Text('Riwayat Booking'),
          centerTitle: true,
          backgroundColor: kRwBg,
          foregroundColor: kRwText,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: kRwText),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final all = app.bookings.where((b) => !b.pack.isShop).toList()..sort((a, b) => b.slot.compareTo(a.slot));
            final list = switch (_filter) {
              0 => all.where((b) => b.active).toList(),
              1 => all.where((b) => !b.cancelled && b.status == 3).toList(),
              _ => all.where((b) => b.cancelled).toList(),
            };
            const empty = [
              ('Belum ada booking aktif', 'Booking cuci atau ganti oli yang sedang berjalan akan tampil di sini.'),
              ('Belum ada booking selesai', 'Booking yang sudah selesai dikerjakan akan tampil di sini.'),
              ('Tidak ada booking dibatalkan', 'Booking yang kamu batalkan akan tampil di sini.'),
            ];
            return RefreshIndicator(
              color: kRwNavy,
              onRefresh: _refresh,
              child: PageList(top: 8, bottom: 32, children: [
                _tabs(),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  FadeSlideIn(
                    playOnce: (_token, _gen, 'kosong'),
                    dx: 28.0 * _dir,
                    dy: 0,
                    child: EmptyState(
                      icon: Icons.event_note_rounded,
                      title: empty[_filter].$1,
                      message: empty[_filter].$2,
                      actionLabel: _filter == 0 ? 'Booking Sekarang' : null,
                      onAction: () => _goBooking(context),
                    ),
                  )
                else
                  // Kartu masuk bertahap dari arah geser tab (maks. 8 kartu pertama), sekali per ganti tab.
                  for (var i = 0; i < list.length; i++)
                    FadeSlideIn(
                      key: ValueKey('bk-${list[i].id}'),
                      playOnce: (_token, _gen, list[i].id),
                      delay: Duration(milliseconds: 50 * (i < 8 ? i : 8)),
                      duration: const Duration(milliseconds: 380),
                      dx: 28.0 * _dir,
                      dy: 0,
                      child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(list[i])),
                    ),
              ]),
            );
          },
        ),
      );
}

// ---------------------------------------------------------------------------
// RIWAYAT PERAWATAN KENDARAAN
// Pesanan cuci / ganti oli yang SELESAI, dikelompokkan per plat nomor.
// ---------------------------------------------------------------------------
class VehicleCareHistoryScreen extends StatelessWidget {
  const VehicleCareHistoryScreen({super.key});

  static String _ago(int d) => d <= 0 ? 'hari ini' : (d == 1 ? 'kemarin' : '$d hari lalu');

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kLineSoft),
            boxShadow: const [BoxShadow(color: Color(0x1408265C), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Column(children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kProRoyal)),
            ),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: kMuted)),
          ]),
        ),
      );

  Widget _vehicleCard(BuildContext context, String plate, List<Booking> items) {
    final first = items.first; // terbaru (daftar sudah diurutkan menurun)
    final g = app.garage.where((v) => v.plate.toUpperCase().replaceAll(' ', '') == plate).firstOrNull;
    final title = g?.title ?? '${first.vehicle.label} • ${first.plate}';
    final days = DateTime.now().difference(first.slot).inDays;
    final due = days >= 14;
    final tone = due ? kWarn : kGreen;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: kProNavy, borderRadius: BorderRadius.circular(15)),
            child: Icon(vehicleIcon(first.vehicle), color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              Text('${first.plate} • ${items.length}x perawatan', style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: tone.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(due ? Icons.schedule_rounded : Icons.verified_rounded, color: tone, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                due
                    ? 'Perawatan terakhir ${_ago(days)}. Saatnya cuci lagi!'
                    : 'Terawat baik. Perawatan terakhir ${_ago(days)}.',
                style: TextStyle(color: tone == kGreen ? const Color(0xFF1B7A4D) : const Color(0xFFB07210), fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.3),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) _entry(context, items[i], last: i == items.length - 1),
      ]),
    );
  }

  Widget _entry(BuildContext context, Booking b, {required bool last}) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 22,
              child: Column(children: [
                const SizedBox(height: 6),
                Container(width: 11, height: 11, decoration: const BoxDecoration(color: kProRoyal, shape: BoxShape.circle)),
                if (!last) Expanded(child: Container(width: 2, color: kProRoyal.withValues(alpha: .2))),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, top: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(b.pack.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    Text(b.total <= 0 ? 'Gratis' : rp(b.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(child: Text(fmtDateTime.format(b.slot), style: const TextStyle(color: kMuted, fontSize: 12))),
                    if (b.review != null) ...[
                      const Icon(Icons.star_rounded, size: 15, color: kGold),
                      const SizedBox(width: 2),
                      Text('${b.review!.rating}.0', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Riwayat Perawatan')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final done = app.bookings.where((b) => !b.pack.isShop && !b.cancelled && b.status == 3).toList()
              ..sort((a, b) => b.slot.compareTo(a.slot));
            final groups = <String, List<Booking>>{};
            for (final b in done) {
              groups.putIfAbsent(b.plate.toUpperCase().replaceAll(' ', ''), () => []).add(b);
            }
            final lastDays = done.isEmpty ? null : DateTime.now().difference(done.first.slot).inDays;
            return RefreshIndicator(
              color: kRed,
              onRefresh: _refresh,
              child: PageList(top: 12, bottom: 32, children: [
                Row(children: [
                  _stat('${done.length}', 'Total\nperawatan'),
                  const SizedBox(width: 10),
                  _stat('${groups.length}', 'Kendaraan\nterawat'),
                  const SizedBox(width: 10),
                  _stat(lastDays == null ? '-' : (lastDays <= 0 ? 'Hari ini' : '$lastDays hr'), 'Perawatan\nterakhir'),
                ]),
                const SizedBox(height: 16),
                if (groups.isEmpty)
                  EmptyState(
                    icon: Icons.build_circle_outlined,
                    title: 'Belum ada riwayat perawatan',
                    message: 'Setelah cuci atau ganti oli selesai, riwayat tiap kendaraan akan tampil di sini.',
                    actionLabel: 'Booking Sekarang',
                    onAction: () => _goBooking(context),
                  )
                else
                  for (final e in groups.entries)
                    Padding(padding: const EdgeInsets.only(bottom: 14), child: _vehicleCard(context, e.key, e.value)),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GarageScreen())),
                  icon: const Icon(Icons.directions_car_outlined),
                  label: Text(app.garage.isEmpty ? 'Tambah Kendaraan Saya' : 'Kelola Kendaraan Saya (${app.garage.length})'),
                ),
              ]),
            );
          },
        ),
      );
}

// ---------------------------------------------------------------------------
// KEAMANAN AKUN
// ---------------------------------------------------------------------------
class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  void _changePassword(BuildContext context) {
    final oldC = TextEditingController(), newC = TextEditingController(), conC = TextEditingController();
    String? err;
    bool hide = true, busy = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ubah Password'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: oldC,
                  obscureText: hide,
                  decoration: const InputDecoration(labelText: 'Password lama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newC,
                  obscureText: hide,
                  decoration: const InputDecoration(labelText: 'Password baru (min. 6 karakter)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conC,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: 'Ulangi password baru',
                    suffixIcon: IconButton(
                      icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setS(() => hide = !hide),
                    ),
                  ),
                ),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(err!, style: const TextStyle(color: kError)),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: busy
                  ? null
                  : () async {
                      if (oldC.text.isEmpty) {
                        setS(() => err = 'Password lama wajib diisi');
                      } else if (newC.text.length < 6) {
                        setS(() => err = 'Password baru minimal 6 karakter');
                      } else if (newC.text != conC.text) {
                        setS(() => err = 'Konfirmasi password tidak sama');
                      } else {
                        setS(() {
                          err = null;
                          busy = true;
                        });
                        try {
                          await app.changePassword(oldC.text, newC.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) toast(context, 'Password berhasil diubah');
                        } on ApiException catch (e) {
                          setS(() {
                            err = e.message;
                            busy = false;
                          });
                        } catch (_) {
                          setS(() {
                            err = 'Terjadi kesalahan. Coba lagi.';
                            busy = false;
                          });
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

  Widget _row(IconData icon, String title, String sub, {Widget? trailing, VoidCallback? onTap}) => ListTile(
        leading: Icon(icon, color: kProRoyal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 12.5)),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: kProNavy)),
        onTap: onTap,
      );

  Widget _tip(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: kGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4))),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Keamanan Akun')),
        body: PageList(top: 12, bottom: 32, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [kProNavy, kProRoyal], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle),
                child: const Icon(Icons.shield_rounded, color: kProGold, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Akunmu terlindungi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Jaga password dan jangan bagikan ke siapa pun.', style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3)),
                ]),
              ),
            ]),
          ),
          const ProfileSectionTitle('Kredensial'),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _row(Icons.mail_outline_rounded, 'Email', app.email.isEmpty ? '-' : app.email),
              const Divider(height: 1),
              _row(Icons.phone_outlined, 'No. HP', app.phone.isEmpty ? '-' : app.phone),
              const Divider(height: 1),
              _row(Icons.lock_outline_rounded, 'Ubah Password', 'Ganti password akunmu secara berkala',
                  onTap: () => _changePassword(context)),
            ]),
          ),
          const ProfileSectionTitle('Tips Keamanan'),
          Panel(
            child: Column(children: [
              _tip('Gunakan password minimal 6 karakter, kombinasikan huruf dan angka.'),
              _tip('Jangan membagikan password atau kode pesanan kepada orang lain.'),
              _tip('Keluar dari akun bila memakai perangkat bersama.'),
            ]),
          ),
        ]),
      );
}