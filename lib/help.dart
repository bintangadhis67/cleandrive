import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'widgets.dart';

// ---------- BANTUAN & FAQ ----------
// Isi di bawah adalah teks contoh. Ganti dengan data resmi (kontak, kebijakan) sebelum rilis.
const kSupportEmail = 'bantuan@cleandrive.example';
const kSupportPhone = '+62 800-0000-0000';

const _faq = [
  ('Bagaimana cara memesan cuci kendaraan?', 'Buka tab Booking, pilih jenis kendaraan, paket, tanggal dan jam, lalu konfirmasi dan bayar.'),
  ('Apakah Coins bisa dipakai untuk potongan harga?', 'Bisa. Di halaman pembayaran aktifkan Tukar Coins (1 Coin = Rp 25, kelipatan 10, maksimal 50% dari total). Coins tidak bisa dipakai untuk membeli membership.'),
  ('Apa bedanya Coins dan Membership?', 'Coins didapat gratis dari aktivitas (check-in, transaksi, ulasan). Membership adalah paket berbayar dengan diskon layanan dan benefit lain. Keduanya terpisah.'),
  ('Bagaimana cara membeli Membership?', 'Buka Membership dari Beranda atau Akun, pilih paket, lalu bayar. Tidak perlu Coins.'),
  ('Kapan pesanan saya diproses?', 'Pesanan diproses setelah pembayaran berhasil. Pantau status lewat tiket dan tracking di detail pesanan.'),
  ('Bisakah membatalkan pesanan?', 'Bisa selama status masih Menunggu dan belum diverifikasi petugas.'),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    toast(context, '$label disalin');
  }

  Widget _contact(BuildContext context, IconData icon, String title, String value) => Panel(
        onTap: () => _copy(context, title, value),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: kCream, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(color: kMuted, fontSize: 13)),
            ]),
          ),
          const Icon(Icons.copy_rounded, size: 18, color: kMuted),
        ]),
      );

  void _doc(BuildContext context, String title, String body) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: PageList(children: [Panel(child: Text(body, style: const TextStyle(height: 1.5)))]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bantuan & FAQ')),
        body: PageList(
          bottom: 32,
          children: [
            TwoPane(
              leftFlex: 6,
              rightFlex: 4,
              left: [
                sec('Pertanyaan Umum', top: 0),
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(children: [
                    for (var i = 0; i < _faq.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(_faq[i].$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                          children: [Text(_faq[i].$2, style: const TextStyle(color: kMuted, height: 1.45))],
                        ),
                      ),
                    ],
                  ]),
                ),
              ],
              right: [
                sec('Hubungi Kami'),
                _contact(context, Icons.mail_outline_rounded, 'Kontak Admin', kSupportEmail),
                const SizedBox(height: 10),
                _contact(context, Icons.headset_mic_outlined, 'Customer Service', kSupportPhone),
                sec('Informasi Hukum'),
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: kNavy),
                      title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: kMuted),
                      onTap: () => _doc(context, 'Kebijakan Privasi',
                          'Teks contoh. CleanDrive menyimpan data akun, kendaraan, dan transaksi untuk menjalankan layanan. Data tidak dibagikan tanpa persetujuan. Ganti dengan kebijakan privasi resmi sebelum rilis.'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: kNavy),
                      title: const Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: kMuted),
                      onTap: () => _doc(context, 'Syarat & Ketentuan',
                          'Teks contoh. Pesanan diproses setelah pembayaran berhasil. Coins adalah reward yang dapat ditukar sebagai potongan saat pembayaran (maksimal 50% dari total) dan tidak berlaku untuk membeli membership. Membership adalah produk berbayar dengan masa berlaku tertentu. Ganti dengan syarat dan ketentuan resmi sebelum rilis.'),
                    ),
                  ]),
                ),
              ],
            ),
          ],
        ),
      );
}