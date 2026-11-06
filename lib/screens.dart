import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      focusedBorder: b(kRed, 2),
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
                backgroundColor: kRed,
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
                  color: kRed.withOpacity(.08),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Image.asset('assets/logo.png', height: wide ? 150 : 120, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 22),
                  Theme(data: buildCardTheme(), child: _card()),
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
            color: _ok ? const Color(0xFF1F5E3A) : const Color(0xFF7A1D1D),
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
