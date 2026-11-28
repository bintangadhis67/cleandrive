# Panduan animasi CleanDrive

Semua animasi memakai bawaan Flutter (tidak menambah paket di `pubspec.yaml`).
Ada dua cara memasangnya:

- **Cara cepat:** ekstrak `cleandrive-pack-16.zip` ke `C:\cleandrive` (timpa file), lalu `flutter analyze`. Paket 16 sudah mencakup seluruh isi paket 14 dan 15, jadi cukup satu paket.
- **Cara manual:** ikuti bagian di bawah. Mulai dari file baru `motion.dart` (langkah 1), baru langkah 2 sampai 10.

Pada tiap langkah: **CARI** = potongan kode lama di file itu, **GANTI** = isi barunya.

## 1. FILE BARU `lib/widgets/motion.dart`
Salin seluruh isi file `motion.dart` yang diberikan. Isinya enam komponen:

| Komponen | Fungsi | Dipakai di |
|---|---|---|
| `Pressable` | Menyusut sedikit saat ditekan, lalu melenting kembali | tombol, kartu, menu bawah, akses cepat |
| `FadeSlideIn` | Muncul memudar sambil naik, bisa diberi jeda (`delay`) | splash, voucher, pembayaran |
| `SuccessBurst` | Centang tergambar, gelombang, konfeti | klaim voucher, pembayaran berhasil |
| `ShineLogo` | Logo membesar + kilau menyapu | splash |
| `FloatingBubbles` | Gelembung sabun naik pelan | latar splash |
| `SlideFadePageTransitionsBuilder` | Pindah halaman: geser + pudar | tema aplikasi |
| `SwipeSwitcher` | Isi berganti dengan geser sesuai arah (kanan bila ke pil berikutnya, kiri bila mundur) | kategori Toko, filter Notifikasi, mode Booking |
| `Pop` | Membesar sebentar lalu mengendap saat nilai berubah | pil filter terpilih, badge dan total keranjang |

`FadeSlideIn` kini punya dua tambahan: `dx` (geser dari samping) dan `playOnce` (kunci agar item daftar tidak mengulang animasi tiap digulir).

## 2. `lib/main.dart` (logo splash beranimasi)
**a.** Di bagian import, tambahkan di bawah `import 'screens/home/customer.dart';`:
```dart
import 'widgets/motion.dart';
```
**b.** Ganti SELURUH class `SplashScreen` (dari `class SplashScreen extends StatelessWidget` sampai akhir file) dengan class `SplashScreen` yang baru di file `main.dart` pada paket.
Perubahannya: `Scaffold.body` kini `Stack` berisi `FloatingBubbles` (latar), `ShineLogo` membungkus gambar logo, dan tagline serta progres dibungkus `FadeSlideIn`.

## 3. `lib/core/theme.dart` (animasi pindah halaman)
**a.** Di bawah `import 'package:google_fonts/google_fonts.dart';` tambahkan:
```dart
import '../widgets/motion.dart' show SlideFadePageTransitionsBuilder;
```
**b.** Di `pageTransitionsTheme`, ganti `FadeUpwardsPageTransitionsBuilder()` menjadi `SlideFadePageTransitionsBuilder()` pada **android, windows, linux, fuchsia**. Baris iOS dan macOS tetap `CupertinoPageTransitionsBuilder()` (gestur geser kembali bawaan iPhone).

## 4. `lib/widgets/widgets.dart` (kartu `Panel` dan tombol `RedButton`)
**a.** Tambahkan setelah `import '../models/models.dart';`:
```dart
import 'motion.dart';
```
**b. `Panel`:** ubah `build` dari bentuk `=> Container(...)` menjadi:
```dart
  @override
  Widget build(BuildContext context) {
    final card = Container(
      /* isi Container yang lama, tidak diubah */
    );
    return onTap == null ? card : Pressable(scale: 0.98, child: card);
  }
```
**c. `RedButton`:** bungkus `SizedBox(...)` yang lama:
```dart
  Widget build(BuildContext context) => Pressable(
        enabled: !busy && onPressed != null,
        scale: 0.97,
        child: SizedBox( /* isi lama */ ),
      );
```

## 5. `lib/screens/rewards/reward_ui.dart` (`RwCard`, `RwButton`, `RwSmallButton`)
**a.** Tambahkan setelah `import '../../models/membership_models.dart';`:
```dart
import '../../widgets/motion.dart';
```
**b. `RwCard`:** pola sama dengan `Panel` (simpan Container ke `final card`, lalu `return onTap == null ? card : Pressable(scale: 0.98, child: card);`).
**c. `RwButton`:** `return SizedBox(` menjadi `return Pressable(enabled: !busy && onPressed != null, scale: 0.97, child: SizedBox(`, dan penutupnya `);` menjadi `));`.
**d. `RwSmallButton`:** `=> FilledButton(` menjadi `=> Pressable(enabled: !busy && onPressed != null, scale: 0.94, child: FilledButton(`, dan penutupnya `);` menjadi `));`.

## 6. `lib/screens/home/beranda_widgets.dart` (Akses Cepat)
**a.** Tambahkan `import '../../widgets/motion.dart';` di atas `import '../../widgets/widgets.dart';`.
**b.** Pada `_tile`: `Widget _tile(QuickItem it) => Container(` menjadi `Widget _tile(QuickItem it) => Pressable(scale: 0.94, child: Container(`, dan penutup method `);` menjadi `));`.

## 7. `lib/screens/home/customer.dart` (menu bawah dan pindah tab)
**a.** Tambahkan `import '../../widgets/motion.dart';` di atas `import '../../widgets/widgets.dart';`.
**b. `_navItem`:** `child: InkWell(` (di dalam `Expanded`) dibungkus `Pressable(scale: 0.9, child: InkWell(...))`. Penutupnya `),` menjadi `)),`.
**c. Tombol Booking tengah:** `GestureDetector(` dibungkus `Pressable(scale: 0.9, child: GestureDetector(...))`. Penutupnya `),` setelah `Container(...)` menjadi `)),`.
**d. Pindah tab:** di `AnimatedSwitcher`, ubah `duration` menjadi 260 ms dan tambahkan:
```dart
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
```

## 8. `lib/screens/rewards/voucher.dart` (klaim voucher berhasil)
**a.** Tambahkan `import '../../widgets/motion.dart';` di atas `import '../../widgets/widgets.dart';`.
**b.** Di `VoucherClaimScreen`, lingkaran 68x68 diganti: bila `_claimed` tampilkan `const SuccessBurst(size: 68, color: kRwGreen)`, bila belum tampilkan lingkaran navy dengan ikon label lama.
**c.** Teks "berhasil diklaim!" dibungkus `FadeSlideIn(delay: Duration(milliseconds: 350), ...)`, dan `VoucherTicket(v)` dibungkus `FadeSlideIn(delay: const Duration(milliseconds: 150), child: VoucherTicket(v))`.
**d.** `const SizedBox(height: 8)` di atas lencana menjadi `SizedBox(height: _claimed ? 36 : 8)` agar konfeti tidak terpotong.

## 9. `lib/screens/payment/payment.dart` (pembayaran berhasil)
**a.** Tambahkan `import '../../widgets/motion.dart';` di atas `import '../../widgets/widgets.dart';`.
**b.** Di `PaymentSuccessScreen`, hapus blok `TweenAnimationBuilder<double>(... RwCheckCircle(size: 96) ...)` dan ganti dengan `const SuccessBurst(size: 96),`.
**c.** Judul, subjudul, kartu rincian, kartu Coins, dan tombol "Lihat Pesanan" dibungkus `FadeSlideIn` dengan jeda bertingkat: 400, 520, 650, 800, 950 ms. Hasilnya muncul berurutan dari atas ke bawah.

## 10A. TOKO `lib/screens/shop/shop.dart`
Tambahkan `import '../../widgets/motion.dart';` di atas `import '../../widgets/widgets.dart';`.

| Yang dianimasikan | Cara |
|---|---|
| Chip Makanan / Minuman / Oli | Di `_chip`, `AnimatedContainer` dibungkus `Pressable(scale: 0.94, child: Pop(trigger: sel, enabled: sel, amount: 1.08, child: ...))`. `onTap` menaikkan penghitung `_gen` |
| Isi bergeser saat ganti kategori | Di `build`, `Expanded(child: ListenableBuilder(...))` menjadi `Expanded(child: SwipeSwitcher(index: _cat.index, child: ListenableBuilder(...)))` |
| Kartu masuk bertahap | `itemBuilder` grid dibungkus `FadeSlideIn(playOnce: (_token, _gen, list[i].id), delay: Duration(milliseconds: 45 * (i < 8 ? i : 8)), dy: 16, child: _card(list[i]))` |
| Klik produk | Di `_card`: `Container` dibungkus `Pressable(scale: 0.96, ...)`, dan gambar dibungkus `Hero(tag: 'product-${p.id}', ...)` |
| Gambar terbang ke halaman detail | Di `ProductDetailScreen`, `ProductImage(p, height: 300, ...)` dibungkus `Hero` dengan **tag yang sama** |
| Tombol "+" dan stepper | "+" dibungkus `Pressable(scale: 0.85)`. Stepper muncul dengan efek pop (`TweenAnimationBuilder`), angka jumlah berganti dengan `AnimatedSwitcher`, tinggi area beli halus lewat `AnimatedSize` |
| Badge dan total keranjang | Badge dibungkus `Pop(trigger: badge, playOnInit: true, ...)`, total harga dibungkus `Pop(trigger: app.cartTotal, ...)`. Bar keranjang naik lewat `FadeSlideIn(dy: 36, ...)` |

## 10B. RIWAYAT `lib/screens/orders/orders.dart`
Tambahkan `import '../../widgets/motion.dart';`.
- Tambah di state: `int _dir = 1; int _gen = 0; final Object _token = Object();`.
- `_pill`: `onTap` mengisi `_dir` (1 bila pil lebih kanan, -1 bila lebih kiri), menaikkan `_gen`, lalu mengganti `_filter`. `AnimatedContainer` dibungkus `Pressable` + `Pop` seperti di Toko.
- Daftar memakai `CustomScrollView` (sliver), jadi animasinya per item: builder `SliverList` dibungkus `FadeSlideIn(playOnce: (_token, _gen, list[i].id), delay: ..., dx: 28.0 * _dir, dy: 0, ...)`. Item masuk dari arah geser pil. Tampilan kosong ikut dibungkus dengan kunci `'kosong'`.

## 10C. NOTIFIKASI `lib/screens/notifications/notifications.dart`
Tambahkan `import '../../widgets/motion.dart';`.
- Tambah di state: `int _gen = 0; final Object _token = Object();`.
- `_pill`: sama dengan Riwayat (`Pressable` + `Pop`, `onTap` menaikkan `_gen`).
- `Expanded(child: ListenableBuilder(...))` menjadi `Expanded(child: SwipeSwitcher(index: _filter, child: ListenableBuilder(...)))`.
- Tiap kartu: `children.add(FadeSlideIn(key: ValueKey('fs-${n.id}'), playOnce: (_token, _gen, n.id), delay: ..., dy: 14, child: _tile(n)))`. Key di pembungkus penting agar menghapus kartu (geser) tidak mengacaukan animasi kartu lain.

## 10D. BOOKING `lib/screens/home/booking_screen.dart`
Tambahkan `import '../../widgets/motion.dart';`.

| Yang dianimasikan | Cara |
|---|---|
| Pilihan Cuci / Ganti Oli | `_modeToggle` memakai `Stack`: penanda merah `AnimatedAlign` (meluncur kiri-kanan, 320 ms) di belakang dua tombol. `_modeBtn` kini transparan; warna ikon dan teks berubah halus lewat `TweenAnimationBuilder<Color?>` |
| Isi halaman saat ganti mode | `content,` menjadi `AnimatedSize(child: SwipeSwitcher(index: _isOil ? 1 : 0, child: content))` |
| Gambar header (mobil ke botol oli) | `if (oil) Positioned(...) else Positioned(...)` menjadi satu `Positioned.fill(child: AnimatedSwitcher(...))` yang menukar dua `Stack` berkunci `'oil'` dan `'car'` |
| Judul dan slogan header | Dibungkus `AnimatedSwitcher` dengan kunci berdasarkan judul / mode |
| Kartu kendaraan | `AnimatedContainer` dibungkus `Pressable(scale: 0.97)` |

## 10E. HEADER BERANDA DAN AKUN (gambar mobil menyatu)
**Masalah awal:** gambar mobil di Beranda dan Akun hanya selebar 340 px (±140 px tinggi) di header setinggi ±215 px, sehingga tepi atas gambar terlihat seperti kotak. Di Booking, gambar memenuhi tinggi header sehingga tepinya tersembunyi dan menyatu dengan gradient.

**File baru `lib/widgets/hero_car.dart`** (komponen `HeroCarBackdrop`):
- Memakai gambar yang sama dengan Booking (`booking_header_car.png`).
- Di layar lebar, lebar gambar mengikuti tinggi header (maks. tinggi x 2,5), jadi mobil memenuhi header seperti di Booking. Di HP lebarnya 80% layar.
- Tepi kiri (10%) dan atas (12%) gambar dipudarkan ke gradient dengan `ShaderMask`.

**Pemasangan:**
- `lib/screens/home/beranda_widgets.dart`: tambah `import '../../widgets/hero_car.dart';`. Ganti blok `Positioned(right: ..., child: IgnorePointer(child: Image.asset('assets/images/home_hero_car.png', ...)))` dengan `const Positioned.fill(child: HeroCarBackdrop()),`.
- `lib/screens/profile/profile_widgets.dart`: sama persis (tambah import, ganti blok `Positioned` gambar).

**Menyesuaikan** (di `hero_car.dart`): `.80` / `.62` = porsi lebar gambar di HP / layar lebar (naikkan untuk mobil lebih besar), `2.5` = batas terhadap tinggi header, `stops: [0.0, 0.10]` = lebar pudar tepi kiri.

## 10F. RIWAYAT TRANSAKSI DAN RIWAYAT BOOKING `lib/screens/profile/profile_screens.dart`
Tambahkan `import '../../widgets/motion.dart';`.
- **Riwayat Transaksi:** pil `_Pills` dibungkus `Pressable` + `Pop`. Di state tambah `_dir`, `_gen`, `_token`; `onSelect` mengisi `_dir` (1 ke kanan, -1 ke kiri) dan menaikkan `_gen`. Kartu dibungkus `FadeSlideIn(playOnce: (_token, _gen, list[i].id), delay: ..., dx: 28.0 * _dir, dy: 0, ...)`.
- **Riwayat Booking:** `_tabs()` diperlakukan sama (Akan Datang, Selesai, Dibatalkan). Tampilan kosong ikut masuk dari arah geser.
- Kartu yang dibungkus memakai `key: ValueKey(...)` sehingga tidak terkait posisi saat daftar berubah.

## 10. Periksa dan uji
```
flutter analyze
flutter run -d chrome --release
```
Yang diuji:
1. Buka ulang aplikasi: logo muncul membesar, kilau menyapu, gelembung naik.
2. Tekan tombol dan kartu: menyusut sedikit lalu melenting.
3. Pindah menu bawah dan buka halaman: bergeser halus.
4. Klaim voucher: centang tergambar, gelombang, konfeti.
5. Bayar pesanan: centang, konfeti, lalu isi muncul berurutan.
6. Toko: ganti Makanan, Minuman, Oli (isi bergeser, kartu masuk bertahap). Ketuk produk: gambar terbang ke halaman detail. Tekan "+": stepper muncul, angka berganti, badge keranjang berdenyut.
7. Riwayat dan Notifikasi: ketuk pil filter bergantian (maju dan mundur). Isi masuk dari arah pil.
8. Booking: ketuk Cuci lalu Ganti Oli. Penanda merah meluncur, isi bergeser, gambar header bertukar.
9. Beranda dan Akun: mobil besar memenuhi tinggi header, tepinya menyatu dengan gradient. Coba juga dengan jendela Chrome dipersempit sampai selebar HP.
10. Akun, Riwayat Transaksi (Semua, Layanan, Toko) dan Riwayat Booking (Akan Datang, Selesai, Dibatalkan): ketuk tab bergantian, kartu masuk dari arah geser.

## Menyesuaikan
- **Efek tekan lebih kuat/lemah:** ubah `scale` (0.9 kuat, 0.98 halus).
- **Konfeti lebih sedikit:** di `motion.dart`, ubah `const n = 22;`. Untuk mematikan: `SuccessBurst(confetti: false)`.
- **Kilau logo lebih cepat:** ubah `Duration(milliseconds: 2400)` pada `_shine`.
- **Mematikan satu efek:** hapus pembungkusnya (mis. `Pressable(...)`), isi di dalamnya tidak berubah.
