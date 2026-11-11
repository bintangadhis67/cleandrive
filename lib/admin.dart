import 'dart:async';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

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
    const pages = [AdminQueue(), AdminVerify(), AdminSummaryTab(), AdminReviews()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CleanDrive'),
        actions: [IconButton(tooltip: 'Keluar', icon: const Icon(Icons.logout), onPressed: app.logout)],
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: pages[_idx])),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: kRed.withOpacity(.14),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.format_list_numbered), label: 'Antrean'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Verifikasi'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Ringkasan'),
          NavigationDestination(icon: Icon(Icons.star_outline_rounded), label: 'Ulasan'),
        ],
      ),
    );
  }
}

class AdminQueue extends StatefulWidget {
  const AdminQueue({super.key});
  @override
  State<AdminQueue> createState() => _AdminQueueState();
}

class _AdminQueueState extends State<AdminQueue> {
  Timer? _timer;

  Future<void> _reload() async {
    try {
      await app.refreshAll();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _reload());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final q = app.queue.where((b) => !b.cancelled).toList();
          if (q.isEmpty) return const Center(child: Text('Belum ada antrean', style: TextStyle(color: kMuted)));
          return RefreshIndicator(
            color: kRed,
            onRefresh: _reload,
            child: ListView(padding: const EdgeInsets.all(12), children: [
              for (final b in q)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ServiceThumb(b.pack, b.vehicle, width: 74),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b.pack.isShop ? 'Pembelian Toko • ${b.itemCount} item' : '${b.pack.name} • ${b.vehicle.label} ${b.plate}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('Pemilik: ${b.owner}', style: const TextStyle(color: kMuted, fontSize: 13)),
                            Text(fmtDateTime.format(b.slot), style: const TextStyle(color: kMuted, fontSize: 13)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        StatusChip(b),
                        PayChip(b),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (b.verified ? kGreen : kMuted).withOpacity(.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi',
                              style: TextStyle(color: b.verified ? kGreen : kMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ]),
                      if (b.status < statusLabels.length - 1) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
                            onPressed: () => guard(context, () => app.advance(b)),
                            child: Text('Ubah ke ${statusLabels[b.status + 1]}'),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
            ]),
          );
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
  bool _ok = false, _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final b = await app.verify(_code.text);
      _ok = true;
      _result = 'Valid: ${b.pack.name} • ${b.plate} (${b.owner})';
    } on ApiException catch (e) {
      _ok = false;
      _result = e.message;
    } catch (_) {
      _ok = false;
      _result = 'Terjadi kesalahan. Coba lagi.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Masukkan kode tiket konsumen (tertera di bawah QR).', style: TextStyle(color: kMuted)),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Kode tiket (CD-0001-L1234AB)'),
        ),
        const SizedBox(height: 12),
        RedButton('Verifikasi', icon: Icons.verified_user, busy: _busy, onPressed: _verify),
        const SizedBox(height: 16),
        if (_result.isNotEmpty)
          Panel(
            color: _ok ? const Color(0x1F2E9E5B) : const Color(0x1FD64545),
            child: Row(children: [
              Icon(_ok ? Icons.check_circle : Icons.error, color: _ok ? kGreen : const Color(0xFFB3261E)),
              const SizedBox(width: 10),
              Expanded(child: Text(_result, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
        const SizedBox(height: 8),
        const Text('Catatan: tiket harus sudah dibayar. Scan kamera (mobile_scanner) bisa ditambahkan untuk versi HP.',
            style: TextStyle(fontSize: 12, color: kMuted)),
      ]);
}

class AdminSummaryTab extends StatefulWidget {
  const AdminSummaryTab({super.key});
  @override
  State<AdminSummaryTab> createState() => _AdminSummaryTabState();
}

class _AdminSummaryTabState extends State<AdminSummaryTab> {
  late Future<AdminSummary> _f = app.summary();

  Widget _stat(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          child: Row(children: [
            Icon(icon, color: kNavy),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kRed,
        onRefresh: () async {
          final f = app.summary();
          setState(() => _f = f);
          await f.catchError((_) => AdminSummary(total: 0, done: 0, revenue: 0, byPackage: {}, rating: const RatingSummary(0, 0)));
        },
        child: FutureBuilder<AdminSummary>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: kRed));
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(snap.error is ApiException ? (snap.error as ApiException).message : 'Gagal memuat ringkasan. Tarik untuk coba lagi.',
                      textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
                ),
              ]);
            }
            final s = snap.data!;
            return ListView(padding: const EdgeInsets.all(16), children: [
              _stat(Icons.receipt_long, 'Total pesanan', '${s.total}'),
              _stat(Icons.task_alt, 'Pesanan selesai', '${s.done}'),
              _stat(Icons.payments, 'Pendapatan (selesai & lunas)', rp(s.revenue)),
              Panel(
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: kGold),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Rating rata-rata', style: TextStyle(fontWeight: FontWeight.w700))),
                  Text(s.rating.count == 0 ? '-' : '${s.rating.avg.toStringAsFixed(1)} (${s.rating.count})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
              sec('Pesanan per paket'),
              for (final e in s.byPackage.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      );
}

class AdminReviews extends StatefulWidget {
  const AdminReviews({super.key});
  @override
  State<AdminReviews> createState() => _AdminReviewsState();
}

class _AdminReviewsState extends State<AdminReviews> {
  late Future<List<Booking>> _f = app.allReviews();

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kRed,
        onRefresh: () async {
          final f = app.allReviews();
          setState(() => _f = f);
          await f.catchError((_) => <Booking>[]);
        },
        child: FutureBuilder<List<Booking>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: kRed));
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return ListView(children: const [
                Padding(padding: EdgeInsets.all(32), child: Text('Belum ada ulasan dari konsumen.', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
              ]);
            }
            final avg = list.map((b) => b.review!.rating).reduce((a, b) => a + b) / list.length;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Panel(
                child: Row(children: [
                  Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    StarRow(avg, size: 20),
                    Text('${list.length} ulasan', style: const TextStyle(color: kMuted)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              for (final b in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(b.owner, style: const TextStyle(fontWeight: FontWeight.w800))),
                        StarRow(b.review!.rating.toDouble(), size: 16),
                      ]),
                      Text('${b.pack.name} • ${b.code} • ${fmtDate.format(b.slot)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                      if (b.review!.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(b.review!.comment),
                      ],
                    ]),
                  ),
                ),
            ]);
          },
        ),
      );
}