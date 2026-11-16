import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/repository.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// VERIFIKASI TIKET: area pemindai, input kode manual, detail tiket, status valid/tidak valid, riwayat.
// Verifikasi memakai app.verify (alur yang sudah ada).
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

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
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

  Widget _scanner() => AdminCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CardTitle('Pemindai QR Code'),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(color: kNavyDark, borderRadius: BorderRadius.circular(16)),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _FramePainter())),
              const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 56),
                  SizedBox(height: 10),
                  Text('Pemindaian kamera belum tersedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Gunakan input kode tiket di bawah.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('Pemindaian lewat kamera membutuhkan paket mobile_scanner dan belum dipasang di project ini.',
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
