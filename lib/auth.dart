import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart';
import 'widgets.dart';

const _soft = Color(0xB3F4E8D6); // krem pudar untuk teks pendukung di atas foto

// ---------- LOGIN / REGISTER ----------
// Halaman perkenalan (onboarding) sudah dihapus. Login/Daftar memakai background foto.
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
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white)),
      );

  Widget _social(IconData icon) => InkWell(
        customBorder: const CircleBorder(),
        onTap: () => toast(context, 'Masuk dengan akun sosial belum tersedia di versi ini.'),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white12, border: Border.all(color: Colors.white38)),
          child: Icon(icon, color: Colors.white),
        ),
      );

  /// Latar belakang foto + lapisan gelap tipis agar tulisan tetap terbaca.
  Widget _background() => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: kNavyDark),
        Image.asset(
          'assets/images/auth_bg.jpg',
          fit: BoxFit.cover, // memenuhi layar di HP, Chrome, maupun laptop
          alignment: Alignment.centerRight, // mobil tetap terlihat saat layar sempit (HP)
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kNavyDark.withOpacity(0.62), kNavyDark.withOpacity(0.40), kNavyDark.withOpacity(0.78)],
            ),
          ),
        ),
      ]);

  /// Tema khusus formulir: tanpa kotak putih, isian transparan bergaris putih tipis.
  ThemeData _formTheme() {
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    const err = Color(0xFFFF8A80);
    return Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white, selectionColor: Colors.white24),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        hintStyle: const TextStyle(color: Colors.white60),
        errorStyle: const TextStyle(color: err),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: b(Colors.white38),
        enabledBorder: b(Colors.white38),
        focusedBorder: b(Colors.white, 2),
        errorBorder: b(err),
        focusedErrorBorder: b(err, 2),
      ),
    );
  }

  Widget _form(bool compact) => Theme(
        data: _formTheme(),
        child: Form(
        key: _key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_register ? 'Buat Akun' : 'Selamat Datang!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(_register ? 'Daftar dan nikmati layanan CleanDrive' : 'Masuk untuk melanjutkan',
              style: const TextStyle(color: _soft)),
          if (_register) ...[
            _label('Nama Lengkap'),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: _name,
              validator: _req,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Masukkan nama lengkap'),
            ),
          ],
          _label('Email'),
          TextFormField(
            style: const TextStyle(color: Colors.white),
            controller: _email,
            validator: _emailRule,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Masukkan email'),
          ),
          _label('Password'),
          TextFormField(
            style: const TextStyle(color: Colors.white),
            controller: _pass,
            validator: (v) => (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
            obscureText: _hidePass,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: _register ? 'Buat password' : 'Masukkan password',
              suffixIcon: IconButton(
                icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white70),
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
            const Center(child: Text('atau masuk dengan', style: TextStyle(color: _soft, fontSize: 12.5))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _social(Icons.g_mobiledata_rounded),
              const SizedBox(width: 16),
              _social(Icons.apple),
            ]),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: _register ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                    style: const TextStyle(color: _soft, fontWeight: FontWeight.w500)),
                TextSpan(text: _register ? 'Masuk' : 'Daftar', style: const TextStyle(fontWeight: FontWeight.w800)),
              ])),
            ),
          ),
        ]),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kNavyDark,
        body: Stack(fit: StackFit.expand, children: [
          _background(),
          SafeArea(
            child: LayoutBuilder(builder: (context, cons) {
              final wide = cons.maxWidth >= 900; // laptop / Chrome lebar
              final short = cons.maxHeight < 640; // HP layar pendek / mode landscape
              final logoH = short ? 70.0 : (wide ? 130.0 : 100.0);
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 20, vertical: 20),
                child: ConstrainedBox(
                  // minHeight membuat isi tetap di tengah layar, tetap bisa digulir saat keyboard muncul.
                  constraints: BoxConstraints(minHeight: cons.maxHeight - 40),
                  child: Align(
                    // Form selalu di tengah layar (HP, Chrome, laptop).
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                        // Logo transparan langsung di atas foto (tanpa kotak putih).
                        Center(child: Image.asset('assets/images/logo_transparent.png', height: logoH, fit: BoxFit.contain)),
                        SizedBox(height: short ? 12 : 20),
                        // Kotak putih dihapus: formulir langsung di atas foto (transparan).
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                          child: _form(short),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ]),
      );
}