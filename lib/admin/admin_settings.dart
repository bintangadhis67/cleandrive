import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repository.dart';
import '../help.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// PENGATURAN: profil admin, informasi akun, ubah password, pengaturan aplikasi dan notifikasi.
// Profil dan password memakai app.updateProfile / app.changePassword (alur yang sudah ada).
// Pengaturan notifikasi tersimpan di memori saja (sama seperti pengaturan sisi pelanggan).
// ---------------------------------------------------------------------------
class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  static bool _nOrder = true, _nVerify = true, _nReview = true;

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
    final n = _name.text.trim();
    if (n.isEmpty) {
      toast(context, 'Nama tidak boleh kosong', error: true);
      return;
    }
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      await app.updateProfile(n, _phone.text.trim());
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) toast(context, 'Profil diperbarui');
  }

  void _changePassword() {
    final oldC = TextEditingController(), newC = TextEditingController(), conC = TextEditingController();
    String? err;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ubah password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
                const SizedBox(height: 12),
                TextField(controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
                const SizedBox(height: 12),
                TextField(controller: conC, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi password baru')),
                if (err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(err!, style: const TextStyle(color: kError))),
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
                    if (mounted) toast(context, 'Password berhasil diubah');
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

  Widget _switch(IconData icon, String title, String sub, bool v, ValueChanged<bool> on) => SwitchListTile(
        secondary: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
        value: v,
        activeThumbColor: kRed,
        onChanged: on,
      );

  Widget _info(IconData icon, String title, String sub, {VoidCallback? onTap}) => ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: kMuted),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) => AdminPageBody(children: [
        TwoPane(
          left: [
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const CardTitle('Profil Admin'),
                const SizedBox(height: 14),
                Row(children: [
                  InitialAvatar(app.user ?? 'Admin', size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.user ?? 'Admin', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy)),
                      const StatusBadge('Super Admin', kBlue),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama lengkap')),
                const SizedBox(height: 12),
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP')),
                const SizedBox(height: 14),
                RedButton('Simpan profil', icon: Icons.save_outlined, busy: _busy, onPressed: _save),
              ]),
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const CardTitle('Informasi Akun'),
                const SizedBox(height: 8),
                kv('Email', app.email),
                kv('Peran', 'Super Admin'),
                kv('Status akun', 'Aktif'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_outline_rounded, size: 19),
                  label: const Text('Ubah password'),
                ),
              ]),
            ),
          ],
          right: [
            AdminCard(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: CardTitle('Pengaturan Aplikasi')),
                const SizedBox(height: 6),
                _info(Icons.language_rounded, 'Bahasa', 'Bahasa Indonesia (belum ada pilihan lain)'),
                const Divider(height: 1, color: kRowLine),
                _info(Icons.sync_rounded, 'Pembaruan data otomatis', 'Setiap 8 detik selama panel admin terbuka'),
                const Divider(height: 1, color: kRowLine),
                _info(Icons.shield_outlined, 'Kebijakan Privasi', 'Baca kebijakan privasi CleanDrive',
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const HelpScreen()))),
              ]),
            ),
            const SizedBox(height: 16),
            AdminCard(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: CardTitle('Notifikasi')),
                const SizedBox(height: 6),
                _switch(Icons.shopping_bag_outlined, 'Pesanan masuk', 'Beritahu saat ada pesanan baru', _nOrder, (v) => setState(() => _nOrder = v)),
                const Divider(height: 1, color: kRowLine),
                _switch(Icons.confirmation_number_outlined, 'Tiket diverifikasi', 'Beritahu saat tiket berhasil diverifikasi', _nVerify, (v) => setState(() => _nVerify = v)),
                const Divider(height: 1, color: kRowLine),
                _switch(Icons.rate_review_outlined, 'Ulasan baru', 'Beritahu saat pelanggan memberi ulasan', _nReview, (v) => setState(() => _nReview = v)),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Text('Pilihan ini hanya tersimpan di memori aplikasi dan belum dikirim ke server.', style: TextStyle(color: kMuted, fontSize: 11.5)),
                ),
              ]),
            ),
          ],
        ),
      ]);
}
