import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------- ONBOARDING (desain layar 2) ----------
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    ('Cuci Kendaraan\nJadi Lebih Mudah', 'Pesan, lacak antrean, dan nikmati layanan terbaik.', 'assets/images/onboard_1.png'),
    ('Booking Tanpa Antre', 'Pilih paket, tanggal, dan jam kedatangan sesuai waktumu.', 'assets/images/onboard_2.png'),
    ('Hemat dengan Voucher', "Klaim voucher, kumpulkan Coins, dan bayar lewat QRIS, e-wallet, atau Livin' by Mandiri.", 'assets/images/onboard_3.png'),
    ('Beri Rating & Ulasan', 'Ceritakan pengalamanmu agar layanan kami makin baik.', 'assets/images/onboard_4.png'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onDone();
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: widget.onDone, child: const Text('Lewati')),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(children: [
                        const SizedBox(height: 8),
                        Text(_pages[i].$1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 12),
                        Text(_pages[i].$2, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.4)),
                        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Image.asset(_pages[i].$3, fit: BoxFit.contain))),
                      ]),
                    ),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: i == _page ? kRed : kLine, borderRadius: BorderRadius.circular(8)),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                  child: RedButton(_page == _pages.length - 1 ? 'Mulai' : 'Next', icon: Icons.arrow_forward_rounded, onPressed: _next),
                ),
              ]),
            ),
          ),
        ),
      );
}

// ---------- LOGIN / REGISTER (desain layar 3 dan 4) ----------
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
  bool _busy = false;

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

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    await guard(context, () => _register
        ? app.register(_name.text.trim(), _email.text.trim(), '', _pass.text)
        : app.login(_email.text.trim(), _pass.text));
    if (mounted) setState(() => _busy = false);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      );

  Widget _social(IconData icon) => InkWell(
        customBorder: const CircleBorder(),
        onTap: () => toast(context, 'Masuk dengan akun sosial belum tersedia di versi ini.'),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: kLine)),
          child: Icon(icon, color: kNavy),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _key,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Center(child: Image.asset('assets/logo.png', height: 96, fit: BoxFit.contain)),
                    const SizedBox(height: 18),
                    Text(_register ? 'Buat Akun' : 'Selamat Datang!',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(_register ? 'Daftar dan nikmati layanan CleanDrive' : 'Masuk untuk melanjutkan',
                        style: const TextStyle(color: kMuted)),
                    if (_register) ...[
                      _label('Nama Lengkap'),
                      TextFormField(
                        controller: _name,
                        validator: _req,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Masukkan nama lengkap'),
                      ),
                    ],
                    _label('Email'),
                    TextFormField(
                      controller: _email,
                      validator: _emailRule,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Masukkan email'),
                    ),
                    _label('Password'),
                    TextFormField(
                      controller: _pass,
                      validator: (v) => (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
                      obscureText: _hidePass,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: _register ? 'Buat password' : 'Masukkan password',
                        suffixIcon: IconButton(
                          icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: kMuted),
                          onPressed: () => setState(() => _hidePass = !_hidePass),
                        ),
                      ),
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => toast(context, 'Reset password belum tersedia. Hubungi admin CleanDrive.'),
                          child: const Text('Lupa password?', style: TextStyle(fontSize: 13)),
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                    RedButton(_register ? 'Daftar' : 'Masuk', busy: _busy, onPressed: _submit),
                    if (!_register) ...[
                      const SizedBox(height: 18),
                      const Center(child: Text('atau masuk dengan', style: TextStyle(color: kMuted, fontSize: 12.5))),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _social(Icons.g_mobiledata_rounded),
                        const SizedBox(width: 16),
                        _social(Icons.apple),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _register = !_register),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: _register ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                              style: const TextStyle(color: kMuted, fontWeight: FontWeight.w500)),
                          TextSpan(text: _register ? 'Masuk' : 'Daftar', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ])),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
