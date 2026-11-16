import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// ULASAN: rating, komentar, tanggal, layanan. Data dari app.allReviews().
// ---------------------------------------------------------------------------
class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  int _rating = 0; // 0 = semua
  String _q = '';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: adminData,
        builder: (context, _) {
          if (!adminData.loaded) return const AdminLoading();
          final all = adminData.reviews.where((b) => b.review != null).toList();
          final q = _q.trim().toLowerCase();
          final list = all.where((b) {
            if (_rating > 0 && b.review!.rating != _rating) return false;
            return q.isEmpty || b.owner.toLowerCase().contains(q) || b.review!.comment.toLowerCase().contains(q) || b.pack.title.toLowerCase().contains(q);
          }).toList();
          final avg = all.isEmpty ? 0.0 : all.map((b) => b.review!.rating).reduce((a, b) => a + b) / all.length;
          final withComment = all.where((b) => b.review!.comment.trim().isNotEmpty).length;

          final summary = AdminCard(
            child: Row(children: [
              Text(all.isEmpty ? '-' : fmtPct(avg), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StarRow(avg, size: 20),
                  const SizedBox(height: 4),
                  Text('${fmtNum(all.length)} ulasan', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  Text('${fmtNum(withComment)} dengan komentar', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                ]),
              ),
            ]),
          );
          final dist = AdminCard(
            child: Column(children: [
              for (var s = 5; s >= 1; s--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(width: 34, child: Text('$s ★', style: const TextStyle(fontSize: 12.5))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: all.isEmpty ? 0 : all.where((b) => b.review!.rating == s).length / all.length,
                          minHeight: 8,
                          color: kGold,
                          backgroundColor: const Color(0xFFE8EDF5),
                        ),
                      ),
                    ),
                    SizedBox(width: 36, child: Text('${all.where((b) => b.review!.rating == s).length}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                  ]),
                ),
            ]),
          );

          return AdminPageBody(children: [
            LayoutBuilder(
              builder: (_, c) => c.maxWidth >= 720
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 4, child: summary),
                      const SizedBox(width: 14),
                      Expanded(flex: 6, child: dist),
                    ])
                  : Column(children: [summary, const SizedBox(height: 14), dist]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SearchBox(hint: 'Cari nama, komentar, layanan', onChanged: (v) => setState(() => _q = v)),
              AdminDropdown<int>(
                value: _rating,
                items: const {0: 'Semua rating', 5: '5 bintang', 4: '4 bintang', 3: '3 bintang', 2: '2 bintang', 1: '1 bintang'},
                onChanged: (v) => setState(() => _rating = v),
              ),
            ]),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const EmptyState(icon: Icons.rate_review_outlined, title: 'Belum ada ulasan', message: 'Ulasan pelanggan yang cocok dengan filter akan muncul di sini.')
            else
              AutoGrid(minWidth: 440, gap: 14, children: [
                for (final b in list)
                  AdminCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        InitialAvatar(b.owner, size: 40),
                        const SizedBox(width: 10),
                        Expanded(child: TwoLine(b.owner, '${b.pack.title} • ${b.code}')),
                        const SizedBox(width: 8),
                        StarRow(b.review!.rating.toDouble(), size: 16),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        b.review!.comment.trim().isEmpty ? 'Tanpa komentar.' : b.review!.comment,
                        style: TextStyle(height: 1.45, fontSize: 13.5, color: b.review!.comment.trim().isEmpty ? kMuted : kNavy),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        StatusBadge(ratingLabel(b.review!.rating), b.review!.rating >= 4 ? kGreen : (b.review!.rating == 3 ? kWarn : kError)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(fmtDate.format(b.review!.createdAt), style: const TextStyle(color: kMuted, fontSize: 12))),
                        TextButton(onPressed: () => showBookingDetail(context, b), child: const Text('Lihat pesanan')),
                        TextButton(onPressed: () => showNotConnected(context, 'Balas ulasan'), child: const Text('Balas')),
                      ]),
                    ]),
                  ),
              ]),
          ]);
        },
      );
}
