import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'
    show BarcodeCapture, BarcodeFormat, DetectionSpeed, MobileScanner, MobileScannerController, MobileScannerState;

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/repository.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// VERIFIKASI TIKET: pemindai QR (kamera), input kode manual, detail tiket, status valid/tidak valid, riwayat.
// Hasil pindai hanya mengisi kode tiket lalu memanggil _verify() -> app.verify (alur verifikasi yang sudah ada).
// ---------------------------------------------------------------------------
class AdminVerifyPage extends StatefulWidget {
  const AdminVerifyPage({super.key});

  @override
  State<AdminVerifyPage> createState() => _AdminVerifyPageState();
}

class _AdminVerifyPageState extends State<AdminVerifyPage> {
  final _code = TextEditingController();
  bool _busy = false;
  bool? _ok; // null = belum ada pemeriksaan
  String _msg = '';
  Booking? _ticket;

  // ----- pemindai kamera -----
  MobileScannerController? _cam; // null = kamera mati
  bool get _scanning => _cam != null;

  @override
  void dispose() {
    _code.dispose();
    _cam?.dispose();
    super.dispose();
  }

  MobileScannerController _newCam() => MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );

  /// Menyalakan kamera. Izin kamera diminta browser / sistem saat pertama kali.
  void _startScan() => setState(() => _cam = _newCam());

  /// Memulai ulang kamera dengan controller baru (dipakai tombol "Coba lagi").
  void _restartScan() {
    final old = _cam;
    setState(() => _cam = _newCam());
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  /// Mematikan kamera. Controller dibuang setelah widget kamera dilepas dari layar.
  void _stopScan() {
    final c = _cam;
    if (c == null) return;
    setState(() => _cam = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  /// QR terbaca: isi kolom kode, matikan kamera, lalu verifikasi dengan alur yang sama seperti input manual.
  void _onDetect(BarcodeCapture cap) {
    if (_busy || !_scanning) return;
    String value = '';
    for (final b in cap.barcodes) {
      final v = b.rawValue?.trim() ?? '';
      if (v.isNotEmpty) {
        value = v;
        break;
      }
    }
    if (value.isEmpty) return;
    _code.text = value;
    _stopScan();
    _verify();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() {
        _ok = false;
        _ticket = null;
        _msg = 'Masukkan kode tiket terlebih dahulu.';
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final b = await app.verify(code);
      _ok = true;
      _ticket = b;
      _msg = 'Tiket valid';
      _code.clear();
      adminData.load();
    } on ApiException catch (e) {
      _ok = false;
      _ticket = null;
      _msg = e.message;
    } catch (_) {
      _ok = false;
      _ticket = null;
      _msg = 'Terjadi kesalahan. Coba lagi.';
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Isi kotak pemindai: kamera hidup, atau tampilan siaga saat kamera mati.
  Widget _cameraBox() {
    final cam = _cam;
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: kNavyDark, borderRadius: BorderRadius.circular(16)),
      child: Stack(children: [
        if (cam != null)
          Positioned.fill(child: MobileScanner(key: ObjectKey(cam), controller: cam, onDetect: _onDetect, fit: BoxFit.cover)),
        Positioned.fill(child: CustomPaint(painter: _FramePainter())),
        if (cam == null)
          const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 56),
              SizedBox(height: 10),
              Text('Pindai QR tiket pelanggan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              SizedBox(height: 2),
              Text('Tekan "Aktifkan Kamera" untuk mulai.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          )
        else
          // Pesan galat (izin ditolak, kamera tidak ada, dll.) dan tombol ganti kamera.
          Positioned.fill(
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: cam,
              builder: (context, state, _) {
                if (state.error != null) {
                  return Container(
                    color: kNavyDark,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
                      const SizedBox(height: 8),
                      const Text('Kamera tidak dapat dibuka',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 4),
                      const Text(
                        'Pastikan izin kamera diberikan dan kamera tidak dipakai aplikasi lain. Di browser, gunakan HTTPS atau localhost.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      // Detail teknis galat, berguna untuk mencari penyebab.
                      Text('${state.error}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: _restartScan,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba lagi'),
                      ),
                    ]),
                  );
                }
                // Status kamera untuk diagnosis: menyiapkan / berjalan, jumlah kamera, resolusi.
                final String status;
                if (!state.isInitialized) {
                  status = 'Menyiapkan kamera...';
                } else if (!state.isRunning) {
                  status = 'Kamera siap, belum berjalan';
                } else {
                  status = 'Kamera aktif • ${state.availableCameras ?? '?'} kamera • ${state.size.width.toInt()}×${state.size.height.toInt()}';
                }
                return Stack(children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filledTonal(
                        tooltip: 'Ganti kamera',
                        style: IconButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
                        onPressed: () => cam.switchCamera(),
                        icon: const Icon(Icons.cameraswitch_rounded),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
      ]),
    );
  }

  Widget _scanner() => AdminCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardTitle('Pemindai QR Code'),
          const SizedBox(height: 12),
          _cameraBox(),
          const SizedBox(height: 12),
          if (_scanning)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: kNavy,
                side: const BorderSide(color: Color(0xFFD7E2F6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _stopScan,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Hentikan Pemindaian'),
            )
          else
            RedButton('Aktifkan Kamera', icon: Icons.videocam_rounded, busy: _busy, onPressed: _startScan),
          const SizedBox(height: 10),
          const Text('Arahkan kamera ke QR pada tiket pelanggan. Setelah terbaca, tiket langsung diverifikasi. Kode tiket juga bisa diketik manual di bawah.',
              style: TextStyle(color: kMuted, fontSize: 11.5, height: 1.4)),
        ]),
      );

  Widget _manual() => AdminCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardTitle('Input Kode Tiket'),
          const SizedBox(height: 4),
          const Text('Kode tertera di bawah QR pada tiket pelanggan. Tiket harus sudah dibayar.', style: TextStyle(color: kMuted, fontSize: 12.5)),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _verify(),
            decoration: const InputDecoration(labelText: 'Kode tiket (CD-0001-L1234AB)', prefixIcon: Icon(Icons.confirmation_number_outlined)),
          ),
          const SizedBox(height: 12),
          RedButton('Verifikasi', icon: Icons.verified_user_rounded, busy: _busy, onPressed: _verify),
        ]),
      );

  Widget _result() {
    final ok = _ok;
    final t = _ticket;
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CardTitle('Detail Tiket'),
        const SizedBox(height: 12),
        if (ok == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Column(children: [
              Icon(Icons.qr_code_2_rounded, size: 52, color: kMuted),
              SizedBox(height: 8),
              Text('Belum ada tiket diperiksa', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Hasil verifikasi akan muncul di sini.', style: TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ok ? kGreenSoft : kRedSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: ok ? kGreen : kError, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ok ? 'Valid' : 'Tidak valid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ok ? kGreen : kError)),
                  Text(_msg, style: const TextStyle(fontSize: 12.5, color: kNavy)),
                ]),
              ),
            ]),
          ),
          if (t != null) ...[
            const SizedBox(height: 10),
            kv('Kode tiket', t.code),
            kv('Pelanggan', t.owner),
            kv('Layanan', t.pack.title),
            if (!t.pack.isShop) kv('Kendaraan', '${t.vehicle.label} • ${t.plate}'),
            kv('Jadwal', fmtDateTime.format(t.slot)),
            kv('Total', rp(t.total), bold: true),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [QBadge(t), PayChip(t)]),
          ],
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final verified = app.bookings.where((b) => b.verified && !b.cancelled && !b.pack.isShop).toList()
            ..sort((a, b) => b.slot.compareTo(a.slot));
          return AdminPageBody(children: [
            TwoPane(
              left: [_scanner(), const SizedBox(height: 16), _manual()],
              right: [_result()],
            ),
            const SizedBox(height: 16),
            AdminCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CardTitle('Riwayat Verifikasi', trailing: Text('${verified.length} tiket', style: const TextStyle(color: kMuted, fontSize: 12.5))),
                const SizedBox(height: 12),
                AdminTable(
                  emptyText: 'Belum ada tiket yang diverifikasi.',
                  minWidth: 720,
                  cols: const [TCol('Kode tiket', flex: 3), TCol('Pelanggan', flex: 3), TCol('Layanan', flex: 3), TCol('Jadwal', flex: 2), TCol('Status', flex: 2)],
                  rows: [
                    for (final b in verified)
                      [
                        Text(b.code, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        PersonCell(b.owner),
                        TwoLine(b.pack.title, '${b.vehicle.label} • ${b.plate}'),
                        TwoLine(fmtDate.format(b.slot), fmtHm.format(b.slot), false),
                        leftCell(const StatusBadge('Valid', kGreen)),
                      ],
                  ],
                ),
              ]),
            ),
          ]);
        },
      );
}

/// Bingkai sudut merah pada area pemindai.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = kRed
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const m = 26.0, l = 32.0;
    final r = Rect.fromLTWH(m, m, s.width - 2 * m, s.height - 2 * m);
    c.drawLine(r.topLeft, r.topLeft + const Offset(l, 0), p);
    c.drawLine(r.topLeft, r.topLeft + const Offset(0, l), p);
    c.drawLine(r.topRight, r.topRight + const Offset(-l, 0), p);
    c.drawLine(r.topRight, r.topRight + const Offset(0, l), p);
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(l, 0), p);
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -l), p);
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(-l, 0), p);
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -l), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}