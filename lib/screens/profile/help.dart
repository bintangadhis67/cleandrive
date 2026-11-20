import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../widgets/widgets.dart';
import '../rewards/reward_ui.dart';

// ---------- BANTUAN & FAQ ----------
// Isi di bawah adalah teks contoh. Ganti dengan data resmi (kontak, kebijakan) sebelum rilis.
const kSupportEmail = 'bantuan@cleandrive.example';
const kSupportPhone = '+62 800-0000-0000';

const _faq = [
  ('Bagaimana cara memesan cuci kendaraan?', 'Buka tab Booking, pilih jenis kendaraan, paket, tanggal dan jam, lalu konfirmasi dan bayar.'),
  ('Apakah Coins bisa dipakai untuk potongan harga?', 'Bisa. Di halaman pembayaran aktifkan Tukar Coins (1 Coin = Rp 50, kelipatan 10, maksimal 30% dari total). Coins tidak bisa dipakai untuk membeli membership.'),
  ('Apa bedanya Coins dan Membership?', 'Coins didapat gratis dari aktivitas (check-in, transaksi, ulasan). Membership adalah paket berbayar dengan diskon layanan dan benefit lain. Keduanya terpisah.'),
  ('Bagaimana cara membeli Membership?', 'Buka Membership dari Beranda atau Akun, pilih paket, lalu bayar. Tidak perlu Coins. Masa aktif 1 bulan dan bisa dibatalkan kapan saja (benefit tetap aktif sampai berakhir, tanpa refund).'),
  ('Berapa voucher yang bisa diklaim per hari?', 'Satu voucher per hari. Member Gold bisa 2x sehari dan Platinum 3x sehari. Voucher Spesial (Rp 20.000) dan Selamat Datang (Rp 10.000) hanya sekali per akun. Hemat 10% dan voucher membership diperbarui tiap minggu.'),
  ('Bagaimana cara memakai cuci gratis membership?', 'Saat konfirmasi pesanan, aktifkan Pakai Cuci Gratis. Berlaku 1x per minggu sesuai paket dan jenis kendaraan membership kamu, tidak bisa digabung voucher atau Coins.'),
  ('Kapan pesanan saya diproses?', 'Pesanan diproses setelah pembayaran berhasil. Pantau status lewat tiket dan tracking di detail pesanan.'),
  ('Bisakah membatalkan pesanan?', 'Bisa selama status masih Menunggu dan belum diverifikasi petugas.'),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    toast(context, '$label disalin');
  }

  /// AppBar seragam: latar biru muda, judul navy di tengah, tombol kembali navy.
  static AppBar _bar(String title) => AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: kRwBg,
        foregroundColor: kRwText,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kRwNavy),
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
      );

  Widget _sectionTitle(String t, {double top = 20}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 10, left: 4),
        child: Text(t, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: kRwText)),
      );

  /// Kartu kontak: ikon navy membulat, judul, nilai, dan tombol salin (fungsi salin tidak berubah).
  Widget _contact(BuildContext context, IconData icon, String title, String value) => RwCard(
        onTap: () => _copy(context, title, value),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyLight, kRwNavyDark]),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: kRwSub, fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: kRwBg, shape: BoxShape.circle),
            child: const Icon(Icons.copy_rounded, size: 17, color: kRwNavy),
          ),
        ]),
      );

  /// Baris Informasi Hukum: ikon dalam kotak biru muda, judul, panah.
  Widget _legalRow(IconData icon, String title, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: kRwBlueSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: kRwNavy, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: kRwText))),
            const Icon(Icons.chevron_right_rounded, color: kRwSub),
          ]),
        ),
      );

  void _doc(BuildContext context, String title, String body) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: kRwBg,
            appBar: _bar(title),
            body: PageList(children: [
              RwCard(padding: const EdgeInsets.all(18), child: Text(body, style: const TextStyle(height: 1.6, color: kRwText, fontSize: 14))),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: _bar('Bantuan & FAQ'),
        body: PageList(
          bottom: 32,
          children: [
            TwoPane(
              leftFlex: 6,
              rightFlex: 4,
              left: [
                _sectionTitle('Pertanyaan Umum', top: 6),
                RwCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (var i = 0; i < _faq.length; i++) ...[
                      if (i > 0) const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: kRwLine),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          iconColor: kRed,
                          collapsedIconColor: kRwSub,
                          textColor: kRwNavy,
                          collapsedTextColor: kRwText,
                          title: Text(_faq[i].$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.3)),
                          children: [Text(_faq[i].$2, style: const TextStyle(color: kRwSub, fontSize: 13.5, height: 1.5))],
                        ),
                      ),
                    ],
                  ]),
                ),
              ],
              right: [
                _sectionTitle('Hubungi Kami'),
                _contact(context, Icons.mail_outline_rounded, 'Kontak Admin', kSupportEmail),
                const SizedBox(height: 10),
                _contact(context, Icons.headset_mic_outlined, 'Customer Service', kSupportPhone),
                _sectionTitle('Informasi Hukum'),
                RwCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(children: [
                      _legalRow(
                        Icons.shield_outlined,
                        'Kebijakan Privasi',
                        () => _doc(context, 'Kebijakan Privasi',
                            'Teks contoh. CleanDrive menyimpan data akun, kendaraan, dan transaksi untuk menjalankan layanan. Data tidak dibagikan tanpa persetujuan. Ganti dengan kebijakan privasi resmi sebelum rilis.'),
                      ),
                      const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: kRwLine),
                      _legalRow(
                        Icons.description_outlined,
                        'Syarat & Ketentuan',
                        () => _doc(context, 'Syarat & Ketentuan',
                            'Teks contoh. Pesanan diproses setelah pembayaran berhasil. Coins adalah reward yang dapat ditukar sebagai potongan saat pembayaran (maksimal 30% dari total) dan tidak berlaku untuk membeli membership. Membership adalah produk berbayar dengan masa berlaku tertentu. Ganti dengan syarat dan ketentuan resmi sebelum rilis.'),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}