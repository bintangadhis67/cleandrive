import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/repository.dart';
import '../../../models/membership_models.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import 'admin_data.dart';

// ---------------------------------------------------------------------------
// WARNA KHUSUS ADMIN (turunan dari design tokens di theme.dart)
// ---------------------------------------------------------------------------
const kAdminBg = Color(0xFFF4F6FB);
const kBlue = Color(0xFF2F6FE4);
const kBlueSoft = Color(0xFFEAF2FF);
const kBlueLine = Color(0xFFCFE0FA);
const kCreamSoft = Color(0xFFFFF8E5);
const kCreamLine = Color(0xFFF1DDA8);
const kGoldDeep = Color(0xFFA86F00);
const kRedSoft = Color(0xFFFDECEC);
const kGreenSoft = Color(0xFFE6F5EC);
const kPurple = Color(0xFF7B5CD6);
const kPurpleSoft = Color(0xFFF0EBFC);
const kCardLine = Color(0x1410264C);
const kRowLine = Color(0x0D10264C);

// ---------------------------------------------------------------------------
// STATUS PESANAN UNTUK ADMIN: Menunggu (kuning), Diproses (biru), Selesai (hijau), Dibatalkan (merah)
// ---------------------------------------------------------------------------
enum QStatus {
  waiting('Menunggu', kWarn),
  processing('Diproses', kBlue),
  done('Selesai', kGreen),
  cancelled('Dibatalkan', kError);

  const QStatus(this.label, this.color);
  final String label;
  final Color color;
}

QStatus qStatusOf(Booking b) =>
    b.cancelled ? QStatus.cancelled : (b.status <= 0 ? QStatus.waiting : (b.status >= 3 ? QStatus.done : QStatus.processing));

Map<QStatus, int> statusCounts(Iterable<Booking> list) {
  final m = {for (final s in QStatus.values) s: 0};
  for (final b in list) {
    final s = qStatusOf(b);
    m[s] = (m[s] ?? 0) + 1;
  }
  return m;
}

// ---------------------------------------------------------------------------
// KARTU DAN JUDUL
// ---------------------------------------------------------------------------
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color border;
  final VoidCallback? onTap;
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.border = kCardLine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: const [BoxShadow(color: Color(0x0F10264C), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Judul kartu (merah seperti desain referensi) dengan aksi opsional di kanan.
class CardTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final Widget? leading;
  final Color color;
  const CardTitle(this.text, {super.key, this.trailing, this.leading, this.color = kRed});

  @override
  Widget build(BuildContext context) => Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color))),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]);
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(20)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class QBadge extends StatelessWidget {
  final Booking b;
  const QBadge(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = qStatusOf(b);
    return StatusBadge(s.label, s.color);
  }
}

/// Avatar inisial (aplikasi belum menyimpan foto profil pelanggan).
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialAvatar(this.name, {super.key, this.size = 36});

  static const _palette = [kBlue, kRed, kGreen, kPurple, kWarn, Color(0xFF0E8FA3)];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final ini = parts.take(2).map((e) => e[0]).join().toUpperCase();
    final c = _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: .14), shape: BoxShape.circle),
      child: Text(ini.isEmpty ? '?' : ini, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: size * .36)),
    );
  }
}

/// Kotak ikon berwarna lembut.
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBox(this.icon, this.color, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(icon, color: color, size: size * .5),
      );
}

/// Statistik kecil (dipakai di bagian atas halaman).
class MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final String? sub;
  final Color? bg, border;
  const MiniStat(this.icon, this.color, this.label, this.value, {super.key, this.sub, this.bg, this.border});

  @override
  Widget build(BuildContext context) => AdminCard(
        color: bg ?? Colors.white,
        border: border ?? kCardLine,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconBox(icon, color, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kNavy))),
              if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 11.5)),
            ]),
          ),
        ]),
      );
}

/// Menyusun kartu statistik: 4 kolom di layar lebar, 2 di tablet, 1 di HP kecil.
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  const StatGrid(this.children, {super.key, this.gap = 14});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 480 ? 2 : 1);
        return ColumnsGrid(cols: cols, gap: gap, children: children);
      });
}

// ---------------------------------------------------------------------------
// TOMBOL
// ---------------------------------------------------------------------------
class SmallOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool chevron;
  const SmallOutlineButton(this.label, this.onTap, {super.key, this.icon, this.chevron = true});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 6)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (chevron) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right_rounded, size: 18)],
        ]),
      );
}

/// Tombol lebar penuh bergaya lembut ("Lihat Detail Coins >").
class WideLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color border;
  final Color fill;
  const WideLinkButton(this.label, this.onTap, {super.key, this.color = kNavy, this.border = kCardLine, this.fill = Colors.white});

  @override
  Widget build(BuildContext context) => Material(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: color),
            ]),
          ),
        ),
      );
}

/// Tombol merah berukuran sedang (aksi utama di toolbar).
class RedAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const RedAction(this.label, this.onTap, {super.key, this.icon});

  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(label),
        ]),
      );
}

// ---------------------------------------------------------------------------
// TOOLBAR: pencarian, dropdown, tab
// ---------------------------------------------------------------------------
class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;
  const SearchBox({super.key, required this.hint, required this.onChanged, this.width = 280});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, minWidth: 180),
      child: SizedBox(
        width: width,
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMuted, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: b(kCardLine),
            enabledBorder: b(kCardLine),
            focusedBorder: b(kRed, 1.5),
          ),
        ),
      ),
    );
  }
}

class AdminDropdown<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final bool compact;
  const AdminDropdown({super.key, required this.value, required this.items, required this.onChanged, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        height: compact ? 34 : 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(compact ? 10 : 14), border: Border.all(color: kCardLine)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(14),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: kNavy),
            style: TextStyle(fontSize: compact ? 12 : 13.5, color: kNavy, fontWeight: FontWeight.w600),
            items: [for (final e in items.entries) DropdownMenuItem<T>(value: e.key, child: Text(e.value))],
            onChanged: (v) => onChanged(v as T),
          ),
        ),
      );
}

/// Baris tab berbentuk pil (merah saat dipilih), bisa digeser di layar sempit.
class PillBar extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PillBar({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) FilterPill(label: labels[i], selected: i == index, onTap: () => onChanged(i)),
        ]),
      );
}

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoBanner(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) => AdminCard(
        color: kBlueSoft,
        border: kBlueLine,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.45, color: kNavy))),
        ]),
      );
}

/// Dialog jujur untuk aksi yang belum punya backend.
Future<void> showNotConnected(BuildContext context, String feature) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
          'Fitur ini belum tersambung ke backend, jadi belum menyimpan perubahan apa pun. '
          'Tampilannya sudah disiapkan dan akan aktif setelah API tersedia.',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// TABEL RESPONSIF: di layar sempit tabel bisa digeser ke samping
// ---------------------------------------------------------------------------
class TCol {
  final String label;
  final int flex;
  const TCol(this.label, {this.flex = 2});
}

class AdminTable extends StatefulWidget {
  final List<TCol> cols;
  final List<List<Widget>> rows;
  final double minWidth;
  final int pageSize;
  final bool pager;
  final String emptyText;
  const AdminTable({
    super.key,
    required this.cols,
    required this.rows,
    this.minWidth = 720,
    this.pageSize = 10,
    this.pager = true,
    this.emptyText = 'Belum ada data.',
  });

  @override
  State<AdminTable> createState() => _AdminTableState();
}

class _AdminTableState extends State<AdminTable> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.rows.length;
    final size = widget.pager ? widget.pageSize : (total == 0 ? 1 : total);
    final pages = total == 0 ? 1 : (total + size - 1) ~/ size;
    if (_page >= pages) _page = pages - 1;
    final from = _page * size;
    final to = math.min(total, from + size);
    final shown = widget.rows.sublist(from, to);

    final header = Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: kCardLine)),
      ),
      child: Row(children: [
        for (final c in widget.cols)
          Expanded(
            flex: c.flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kNavy)),
            ),
          ),
      ]),
    );

    Widget row(List<Widget> cells) => Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kRowLine))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            for (var i = 0; i < widget.cols.length; i++)
              Expanded(
                flex: widget.cols[i].flex,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: i < cells.length ? cells[i] : const SizedBox.shrink()),
              ),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (_, box) {
        final table = SizedBox(
          width: math.max(box.maxWidth, widget.minWidth),
          child: Column(children: [header, for (final r in shown) row(r)]),
        );
        if (box.maxWidth >= widget.minWidth) return table;
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
      }),
      if (total == 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(child: Text(widget.emptyText, style: const TextStyle(color: kMuted))),
        ),
      if (widget.pager && pages > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(child: Text('Menampilkan ${from + 1}-$to dari $total', style: const TextStyle(color: kMuted, fontSize: 12.5))),
            IconButton(
              tooltip: 'Sebelumnya',
              visualDensity: VisualDensity.compact,
              onPressed: _page > 0 ? () => setState(() => _page--) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text('${_page + 1} / $pages', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
            IconButton(
              tooltip: 'Berikutnya',
              visualDensity: VisualDensity.compact,
              onPressed: _page < pages - 1 ? () => setState(() => _page++) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
        ),
    ]);
  }
}

/// Teks dua baris dalam sel tabel (judul tebal + keterangan abu-abu).
class TwoLine extends StatelessWidget {
  final String top;
  final String? bottom;
  final bool boldTop;
  const TwoLine(this.top, [this.bottom, this.boldTop = true]);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(top, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: boldTop ? FontWeight.w600 : FontWeight.w500, color: kNavy)),
        if (bottom != null && bottom!.isNotEmpty)
          Text(bottom!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: kMuted)),
      ]);
}

/// Avatar + nama + keterangan (sel "Pelanggan").
class PersonCell extends StatelessWidget {
  final String name;
  final String? sub;
  const PersonCell(this.name, [this.sub]);

  @override
  Widget build(BuildContext context) => Row(children: [
        InitialAvatar(name, size: 34),
        const SizedBox(width: 10),
        Expanded(child: TwoLine(name, sub)),
      ]);
}

// ---------------------------------------------------------------------------
// KERANGKA HALAMAN, PEMUATAN DATA
// ---------------------------------------------------------------------------
/// Isi halaman: gulir, jarak responsif, lebar maksimum, tarik untuk memuat ulang.
class AdminPageBody extends StatelessWidget {
  final List<Widget> children;
  const AdminPageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final pad = box.maxWidth >= 720 ? 24.0 : 14.0;
        return RefreshIndicator(
          color: kRed,
          onRefresh: adminData.load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 6, pad, 32),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ],
          ),
        );
      });
}

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) => const AdminPageBody(children: [
        Skeleton(height: 84, radius: 18),
        SizedBox(height: 14),
        Skeleton(height: 240, radius: 18),
        SizedBox(height: 14),
        Skeleton(height: 160, radius: 18),
      ]);
}

/// Menunggu data lintas pelanggan (adminOverview) dimuat, lalu menampilkan [builder].
class OverviewGate extends StatelessWidget {
  final Widget Function(AdminOverview ov) builder;
  const OverviewGate({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: adminData,
        builder: (_, __) {
          final ov = adminData.overview;
          if (ov != null) return builder(ov);
          if (adminData.error != null) {
            return AdminPageBody(children: [ErrorState(message: adminData.error!, onRetry: adminData.load)]);
          }
          return const AdminLoading();
        },
      );
}

// ---------------------------------------------------------------------------
// DETAIL PESANAN (dipakai Antrean, Pesanan & Transaksi, Ulasan)
// ---------------------------------------------------------------------------
Future<void> showBookingDetail(BuildContext context, Booking b) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(b.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 6, children: [QBadge(b), PayChip(b)]),
              const SizedBox(height: 10),
              kv('Pelanggan', b.owner),
              kv('Layanan', b.pack.title),
              if (!b.pack.isShop) kv('Kendaraan', '${b.vehicle.label} • ${b.plate}'),
              kv('Jadwal', fmtDateTime.format(b.slot)),
              if (!b.pack.isShop) kv('Perkiraan selesai', fmtDateTime.format(b.estFinish)),
              kv('Tiket', b.verified ? 'Terverifikasi' : 'Belum diverifikasi'),
              kv('Metode bayar', b.payMethod?.label ?? '-'),
              kv('No. transaksi', b.trx ?? '-'),
              if (b.items.isNotEmpty) ...[
                const Divider(height: 18),
                for (final l in b.items) kv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
              ],
              const Divider(height: 18),
              kv('Harga', rp(b.price)),
              if (b.discount > 0) kv('Voucher ${b.voucherCode ?? ''}', '- ${rp(b.discount)}'),
              if (b.memberDiscount > 0) kv('Diskon member ${b.memberLabel ?? ''}', '- ${rp(b.memberDiscount)}'),
              if (b.coinDiscount > 0) kv('Potongan Coins', '- ${rp(b.coinDiscount)}'),
              kv('Total', rp(b.total), bold: true),
              if (b.freeWash) kv('Pembayaran', 'Cuci gratis membership', valueColor: kGreen),
              if (b.perks.isNotEmpty) kv('Siapkan untuk member', b.perks.join(' + '), valueColor: kWarn),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );

/// Ikon layanan untuk sel tabel.
IconData serviceIcon(WashPackage p) => p.isShop ? Icons.shopping_bag_outlined : (p.isOil ? Icons.opacity_rounded : Icons.local_car_wash_rounded);

// ---------------------------------------------------------------------------
// DISTRIBUSI MEMBERSHIP (progress bar per tingkat)
// ---------------------------------------------------------------------------
class TierBars extends StatelessWidget {
  final Map<MembershipTier, int> counts;
  const TierBars(this.counts, {super.key});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (s, v) => s + v);
    return Column(children: [
      for (final t in MembershipTier.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 64, child: Text(t.label, style: const TextStyle(fontSize: 12.5, color: kNavy))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : (counts[t] ?? 0) / total,
                  minHeight: 8,
                  color: t.color,
                  backgroundColor: const Color(0xFFE8EDF5),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                '${fmtNum(counts[t] ?? 0)} (${fmtPct(total == 0 ? 0 : (counts[t] ?? 0) / total * 100)}%)',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kNavy),
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// GRAFIK: garis (pendapatan) dan donat (status pesanan). Digambar sendiri, tanpa paket tambahan.
// ---------------------------------------------------------------------------
class RevenueLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  const RevenueLineChart({super.key, required this.values, required this.labels, this.height = 200});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(painter: _LinePainter(values, labels)),
      );
}

double _niceMax(double m) {
  if (m <= 0) return 4;
  final exp = math.pow(10, (math.log(m) / math.ln10).floor()).toDouble();
  final f = m / exp;
  for (final o in const [1.0, 2.0, 4.0, 6.0, 8.0, 10.0]) {
    if (f <= o) return o * exp;
  }
  return 10 * exp;
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  _LinePainter(this.values, this.labels);

  void _label(Canvas c, String s, Offset o, {bool right = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: const TextStyle(color: kMuted, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? o.dx - tp.width : (center ? o.dx - tp.width / 2 : o.dx);
    tp.paint(c, Offset(dx, right ? o.dy - tp.height / 2 : o.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0, right = 14.0, top = 10.0, bottom = 26.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    if (w <= 0 || h <= 0 || values.isEmpty) return;
    final maxV = _niceMax(values.reduce(math.max));
    final grid = Paint()
      ..color = const Color(0x1410264C)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _label(canvas, fmtAxis(maxV * i / 4), Offset(left - 8, y), right: true);
    }
    final n = values.length;
    Offset pt(int i) => Offset(n == 1 ? left + w / 2 : left + w * i / (n - 1), top + h - h * (values[i] / maxV));
    final pts = [for (var i = 0; i < n; i++) pt(i)];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, top + h)
      ..lineTo(pts.first.dx, top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33C62026), Color(0x00C62026)],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = kRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.6, Paint()..color = kRed);
    }
    final step = (w / n < 38) ? 2 : 1;
    for (var i = 0; i < n && i < labels.length; i += step) {
      _label(canvas, labels[i], Offset(pts[i].dx, top + h + 8), center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values || old.labels != labels;
}

class DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double size;
  final Widget center;
  const DonutChart({super.key, required this.values, required this.colors, required this.center, this.size = 150});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(values, colors)),
          center,
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .19;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = const Color(0xFFE8EDF5));
      return;
    }
    final nonZero = values.where((v) => v > 0).length;
    final gap = nonZero > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(rect, start + gap / 2, math.max(0.001, sweep - gap), false, paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values || old.colors != colors;
}

/// Merapatkan isi sel tabel ke kiri agar badge tidak melebar mengikuti lebar kolom.
Widget leftCell(Widget child) => Align(alignment: Alignment.centerLeft, child: child);