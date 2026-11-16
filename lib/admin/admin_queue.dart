import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// ANTREAN LAYANAN: daftar antrean, filter tanggal dan status, ubah status pesanan.
// Perubahan status memakai app.advance (alur yang sudah ada).
// ---------------------------------------------------------------------------
class AdminQueuePage extends StatefulWidget {
  const AdminQueuePage({super.key});

  @override
  State<AdminQueuePage> createState() => _AdminQueuePageState();
}

class _AdminQueuePageState extends State<AdminQueuePage> {
  QStatus? _status; // null = semua
  DateTime? _date; // null = semua tanggal
  String _q = '';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? dayOf(now),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih tanggal antrean',
    );
    if (d != null) setState(() => _date = dayOf(d));
  }

  Future<void> _advance(Booking b) async {
    final next = b.pack.statusNames[b.status + 1];
    final ok = await guard(context, () async {
      await app.advance(b);
      return true;
    });
    if (ok == true && mounted) {
      toast(context, '${b.code} diubah ke $next');
      adminData.load();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final all = app.queue;
          final inDate = all.where((b) => _date == null || sameDay(b.slot, _date!)).toList();
          final cnt = statusCounts(inDate);
          final q = _q.trim().toLowerCase();
          final list = inDate.where((b) {
            if (_status != null && qStatusOf(b) != _status) return false;
            if (q.isEmpty) return true;
            return b.owner.toLowerCase().contains(q) || b.plate.toLowerCase().contains(q) || b.code.toLowerCase().contains(q);
          }).toList();

          return AdminPageBody(children: [
            StatGrid([
              MiniStat(Icons.hourglass_top_rounded, kWarn, 'Menunggu', fmtNum(cnt[QStatus.waiting] ?? 0)),
              MiniStat(Icons.local_car_wash_rounded, kBlue, 'Diproses', fmtNum(cnt[QStatus.processing] ?? 0)),
              MiniStat(Icons.task_alt_rounded, kGreen, 'Selesai', fmtNum(cnt[QStatus.done] ?? 0)),
              MiniStat(Icons.cancel_outlined, kError, 'Dibatalkan', fmtNum(cnt[QStatus.cancelled] ?? 0)),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SearchBox(hint: 'Cari nama, plat, atau kode tiket', onChanged: (v) => setState(() => _q = v)),
              SmallOutlineButton(
                _date == null ? 'Semua tanggal' : fmtDate.format(_date!),
                _pickDate,
                icon: Icons.calendar_today_rounded,
                chevron: false,
              ),
              if (_date == null || !sameDay(_date!, DateTime.now()))
                SmallOutlineButton('Hari ini', () => setState(() => _date = dayOf(DateTime.now())), chevron: false),
              if (_date != null) SmallOutlineButton('Semua tanggal', () => setState(() => _date = null), icon: Icons.close_rounded, chevron: false),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                FilterPill(label: 'Semua', selected: _status == null, onTap: () => setState(() => _status = null)),
                for (final s in QStatus.values) FilterPill(label: s.label, selected: _status == s, onTap: () => setState(() => _status = s)),
              ]),
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const EmptyState(icon: Icons.format_list_bulleted_rounded, title: 'Tidak ada antrean', message: 'Belum ada pesanan yang cocok dengan filter ini.')
            else
              AutoGrid(minWidth: 430, gap: 14, children: [for (final b in list) _QueueCard(b, onAdvance: () => _advance(b))]),
          ]);
        },
      );
}

class _QueueCard extends StatelessWidget {
  final Booking b;
  final VoidCallback onAdvance;
  const _QueueCard(this.b, {required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final canAdvance = !b.cancelled && !b.pack.isShop && b.status < 3;
    final next = canAdvance ? b.pack.statusNames[b.status + 1] : '';
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ServiceThumb(b.pack, b.vehicle, width: 76),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.pack.isShop ? 'Pembelian Toko • ${b.itemCount} item' : '${b.pack.title} • ${b.vehicle.label}',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kNavy)),
              const SizedBox(height: 2),
              Row(children: [
                InitialAvatar(b.owner, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(b.owner, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5))),
              ]),
              if (!b.pack.isShop) Text('Plat ${b.plate}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
              Text(fmtDateTime.format(b.slot), style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          QBadge(b),
          PayChip(b),
          StatusBadge(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi', b.verified ? kGreen : kMuted),
          if (b.queuePosition > 0) StatusBadge('Antrean #${b.queuePosition}', kBlue),
        ]),
        const SizedBox(height: 10),
        Text(
          b.items.isEmpty ? 'Total ${rp(b.total)}' : 'Total ${rp(b.total)} • ${b.items.map((l) => '${l.product.name} ×${l.qty}').join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: kNavy),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => showBookingDetail(context, b),
              child: const Text('Detail'),
            ),
          ),
          if (canAdvance) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: b.paid ? onAdvance : null,
                child: Text(b.paid ? 'Ubah ke $next' : 'Belum dibayar', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}
