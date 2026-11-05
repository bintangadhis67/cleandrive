import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

final _fmt = DateFormat('d MMM yyyy, HH:mm');

// ---------- LOGIN / REGISTER ----------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();
  bool _register = false;
  bool _hidePass = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _emailRule(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Wajib diisi';
    if (!t.contains('@') || !t.contains('.')) return 'Format email tidak valid';
    return null;
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final name = _register ? _name.text.trim() : _email.text.split('@').first;
    final ok = app.login(name, _email.text, _pass.text);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        content: const Text('Email atau password salah'),
      ));
    }
  }

  void _fillDemo() {
    setState(() {
      _register = false;
      _email.text = AppState.adminEmail;
      _pass.text = AppState.adminPass;
    });
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kNavy.withOpacity(.55)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF1F5FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(kSky, 2),
      errorBorder: b(Colors.red.shade300),
      focusedErrorBorder: b(Colors.red.shade400, 2),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? kNavy : Colors.black45)),
          ),
        ),
      );

  Widget _card() => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 32, offset: const Offset(0, 16))],
        ),
        child: Form(
          key: _key,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFE9EFF8), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _tab('Masuk', !_register, () => setState(() => _register = false)),
                _tab('Daftar', _register, () => setState(() => _register = true)),
              ]),
            ),
            const SizedBox(height: 22),
            Text(_register ? 'Buat akun baru' : 'Selamat datang kembali',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 4),
            Text(
                _register
                    ? 'Daftar untuk mulai booking cuci kendaraan.'
                    : 'Masuk untuk booking dan pantau antreanmu.',
                style: const TextStyle(fontSize: 13.5, color: Colors.black54)),
            const SizedBox(height: 20),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _register
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _name,
                        validator: _req,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _dec('Nama lengkap', Icons.person_outline),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            TextFormField(
              controller: _email,
              validator: _emailRule,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _dec('Email', Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              validator: (v) => (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
              obscureText: _hidePass,
              onFieldSubmitted: (_) => _submit(),
              decoration: _dec(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black45),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kNavy,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: _submit,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_register ? 'Daftar Sekarang' : 'Masuk'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ]),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(
                    _register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: kNavy)),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _fillDemo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kSky.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.admin_panel_settings_outlined, size: 18, color: kNavy),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text('Demo admin: ketuk untuk isi otomatis',
                        style: TextStyle(fontSize: 12.5, color: kNavy)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kNavy, kNavyDark],
              ),
            ),
          ),
        ),
        Positioned(top: -60, right: -40, child: _bubble(200, .05)),
        Positioned(top: 140, left: -50, child: _bubble(120, .04)),
        Positioned(bottom: -70, left: -30, child: _bubble(220, .05)),
        Positioned(bottom: 120, right: -30, child: _bubble(90, .05)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/logo.png', height: wide ? 150 : 120, fit: BoxFit.contain),
                  const SizedBox(height: 22),
                  _card(),
                  const SizedBox(height: 18),
                  const Text('Cuci bersih, antre tanpa ribet.',
                      style: TextStyle(color: Colors.white60, fontSize: 12.5)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------- HOME KONSUMEN ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Halo, ${app.user}'),
          actions: [IconButton(icon: const Icon(Icons.logout), onPressed: app.logout)],
        ),
        body: _idx == 0 ? BookingScreen(onDone: () => setState(() => _idx = 1)) : const OrdersScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Booking'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          ],
        ),
      );
}

// ---------- BOOKING ----------
class BookingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BookingScreen({super.key, required this.onDone});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  VehicleType _v = VehicleType.mobil;
  WashPackage _p = packages[1];
  final _plate = TextEditingController();
  int _dayOffset = 0;
  int? _hour;

  DateTime get _day {
    final n = DateTime.now().add(Duration(days: _dayOffset));
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final slot = _hour == null ? null : _day.add(Duration(hours: _hour!));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('1. Jenis kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [
        for (final v in VehicleType.values)
          ChoiceChip(label: Text(v.label), selected: _v == v, onSelected: (_) => setState(() => _v = v)),
      ]),
      const SizedBox(height: 12),
      TextField(controller: _plate, textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Plat nomor (mis. L 1234 AB)', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 16),
      const Text('2. Paket cuci', style: TextStyle(fontWeight: FontWeight.bold)),
      for (final p in packages)
        Card(
          color: _p == p ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            title: Text('${p.name} • ${rp(p.priceFor(_v))}'),
            subtitle: Text('${p.desc}\nEstimasi ${p.minutes} menit'),
            isThreeLine: true,
            trailing: _p == p ? const Icon(Icons.check_circle) : null,
            onTap: () => setState(() => _p = p),
          ),
        ),
      const SizedBox(height: 8),
      const Text('3. Tanggal & jam kedatangan', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < 3; i++)
          ChoiceChip(
            label: Text(i == 0 ? 'Hari ini' : i == 1 ? 'Besok' : DateFormat('d MMM').format(DateTime.now().add(Duration(days: i)))),
            selected: _dayOffset == i,
            onSelected: (_) => setState(() { _dayOffset = i; _hour = null; }),
          ),
      ]),
      Wrap(spacing: 8, children: [
        for (var h = 8; h <= 17; h++)
          Builder(builder: (_) {
            final past = _day.add(Duration(hours: h)).isBefore(DateTime.now());
            final full = app.slotCount(_day, h) >= AppState.maxPerSlot;
            return ChoiceChip(
              label: Text('${h.toString().padLeft(2, '0')}:00${full ? ' (penuh)' : ''}'),
              selected: _hour == h,
              onSelected: (past || full) ? null : (_) => setState(() => _hour = h),
            );
          }),
      ]),
      const SizedBox(height: 16),
      if (slot != null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text('Estimasi selesai: ${_fmt.format(app.estimate(slot, _p))}'),
            subtitle: Text('Total: ${rp(_p.priceFor(_v))}'),
          ),
        ),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: const Icon(Icons.event_available),
        label: const Text('Pesan Sekarang'),
        onPressed: (slot == null || _plate.text.trim().isEmpty)
            ? null
            : () {
                final b = app.create(_v, _p, _plate.text.trim(), slot);
                _plate.clear();
                setState(() => _hour = null);
                widget.onDone();
                Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id)));
              },
      ),
    ]);
  }
}

// ---------- DAFTAR PESANAN KONSUMEN ----------
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final list = app.myBookings;
          return list.isEmpty
              ? const Center(child: Text('Belum ada pesanan'))
              : ListView(children: [
                  for (final b in list)
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${b.pack.name} • ${b.plate}'),
                      subtitle: Text('${_fmt.format(b.slot)} • ${statusLabels[b.status]}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
                    ),
                ]);
        },
      );
}

// ---------- DETAIL: QR + TRACKING + PDF ----------
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.bookings.firstWhere((x) => x.id == id);
          return Scaffold(
            appBar: AppBar(title: Text('Pesanan #${b.id}')),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Center(child: QrImageView(data: b.code, size: 180)),
              Center(child: SelectableText(b.code, style: const TextStyle(fontWeight: FontWeight.bold))),
              const Center(child: Text('Tunjukkan QR ini ke petugas saat tiba', style: TextStyle(fontSize: 12))),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: Icon(b.verified ? Icons.verified : Icons.hourglass_empty, size: 18),
                  label: Text(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi petugas'),
                ),
              ),
              const Divider(height: 32),
              Text('${b.vehicle.label} ${b.plate} • ${b.pack.name}'),
              Text('Jadwal: ${_fmt.format(b.slot)}'),
              Text('Estimasi selesai: ${_fmt.format(b.estFinish)}'),
              Text('Total: ${rp(b.price)}'),
              const SizedBox(height: 16),
              const Text('Status pengerjaan', style: TextStyle(fontWeight: FontWeight.bold)),
              for (var i = 0; i < statusLabels.length; i++)
                ListTile(
                  dense: true,
                  leading: Icon(i <= b.status ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: i <= b.status ? kSky : Colors.grey),
                  title: Text(statusLabels[i]),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Cetak Bukti PDF'),
                onPressed: () => _pdf(b),
              ),
            ]),
          );
        },
      );
}

// ================= ADMIN =================
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [AdminQueue(), AdminVerify(), AdminSummary()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CleanDrive'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: app.logout)],
      ),
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.format_list_numbered), label: 'Antrean'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Verifikasi'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Ringkasan'),
        ],
      ),
    );
  }
}

class AdminQueue extends StatelessWidget {
  const AdminQueue({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final q = app.queue;
          if (q.isEmpty) return const Center(child: Text('Belum ada antrean'));
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final b in q)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b.pack.name} • ${b.vehicle.label} ${b.plate}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Pemilik: ${b.owner} • ${_fmt.format(b.slot)}'),
                    Text(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Chip(label: Text(statusLabels[b.status])),
                      const Spacer(),
                      if (b.status < statusLabels.length - 1)
                        FilledButton(
                          onPressed: () => app.advance(b),
                          child: Text('Ubah ke ${statusLabels[b.status + 1]}'),
                        ),
                    ]),
                  ]),
                ),
              ),
          ]);
        },
      );
}

class AdminVerify extends StatefulWidget {
  const AdminVerify({super.key});
  @override
  State<AdminVerify> createState() => _AdminVerifyState();
}

class _AdminVerifyState extends State<AdminVerify> {
  final _code = TextEditingController();
  String _result = '';
  bool _ok = false;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Masukkan kode tiket konsumen (tertera di bawah QR).'),
        const SizedBox(height: 12),
        TextField(controller: _code, textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Kode tiket (CD-0001-L1234AB)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.verified_user),
          label: const Text('Verifikasi'),
          onPressed: () {
            final b = app.verify(_code.text);
            setState(() {
              _ok = b != null;
              _result = b == null ? 'Kode tidak ditemukan' : 'Valid: ${b.pack.name} • ${b.plate} (${b.owner})';
            });
          },
        ),
        const SizedBox(height: 16),
        if (_result.isNotEmpty)
          Card(
            color: _ok ? Colors.green.shade100 : Colors.red.shade100,
            child: ListTile(leading: Icon(_ok ? Icons.check_circle : Icons.error), title: Text(_result)),
          ),
        const SizedBox(height: 8),
        const Text('Catatan: scan kamera (mobile_scanner) bisa ditambahkan untuk versi HP.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]);
}

class AdminSummary extends StatelessWidget {
  const AdminSummary({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Total pesanan'),
              trailing: Text('${app.bookings.length}'))),
          Card(child: ListTile(leading: const Icon(Icons.task_alt), title: const Text('Pesanan selesai'),
              trailing: Text('${app.doneCount}'))),
          Card(child: ListTile(leading: const Icon(Icons.payments), title: const Text('Pendapatan (selesai)'),
              trailing: Text(rp(app.revenue), style: const TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          const Text('Pesanan per paket', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final p in packages)
            ListTile(dense: true, title: Text(p.name),
                trailing: Text('${app.bookings.where((b) => b.pack == p).length}')),
        ]),
      );
}
