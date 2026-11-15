import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'help.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------- PENGATURAN ----------
// Pengaturan notifikasi tersimpan di memori (belum ada penyimpanan permanen / backend).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static bool _orders = true, _promo = true, _coins = true;

  void editProfile(BuildContext context) {
    final name = TextEditingController(text: app.user);
    final phone = TextEditingController(text: app.phone);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profil'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama lengkap')),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP')),
            ]),
          ),
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

  void changePassword(BuildContext context) {
    final oldC = TextEditingController(), newC = TextEditingController(), conC = TextEditingController();
    String? err;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ubah password'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
                const SizedBox(height: 12),
                TextField(controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
                const SizedBox(height: 12),
                TextField(controller: conC, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi password baru')),
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

  Widget _tile(IconData icon, String title, {String? sub, VoidCallback? onTap, Widget? trailing}) => ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: sub == null ? null : Text(sub, style: const TextStyle(color: kMuted, fontSize: 12.5)),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right, color: kMuted)),
        onTap: onTap,
      );

  Widget _switch(IconData icon, String title, bool v, ValueChanged<bool> on) => SwitchListTile(
        secondary: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: v,
        activeThumbColor: kRed,
        onChanged: on,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Akun')),
        body: PageList(
          bottom: 32,
          children: [
            TwoPane(
              left: [
                sec('Akun', top: 0),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _tile(Icons.person_outline, 'Edit Profil', onTap: () => editProfile(context)),
                    const Divider(height: 1),
                    _tile(Icons.lock_outline, 'Ubah Password', onTap: () => changePassword(context)),
                    const Divider(height: 1),
                    _tile(Icons.language_rounded, 'Bahasa', sub: 'Bahasa Indonesia (belum ada pilihan lain)'),
                  ]),
                ),
              ],
              right: [
                sec('Notifikasi', top: 0),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _switch(Icons.local_car_wash_outlined, 'Pesanan & pembayaran', _orders, (v) => setState(() => _orders = v)),
                    const Divider(height: 1),
                    _switch(Icons.monetization_on_outlined, 'Coins & check-in', _coins, (v) => setState(() => _coins = v)),
                    const Divider(height: 1),
                    _switch(Icons.campaign_outlined, 'Promo & voucher', _promo, (v) => setState(() => _promo = v)),
                  ]),
                ),
                sec('Lainnya'),
                Panel(
                  padding: EdgeInsets.zero,
                  child: _tile(Icons.shield_outlined, 'Kebijakan Privasi',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
                ),
              ],
            ),
          ],
        ),
      );
}
