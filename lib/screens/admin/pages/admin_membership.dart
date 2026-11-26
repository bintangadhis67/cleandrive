import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/repository.dart';
import '../../../models/membership_models.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// MEMBERSHIP (panel terpisah dari Coins): pelanggan per tingkatan, benefit, syarat level, riwayat.
// ---------------------------------------------------------------------------
class AdminMembershipPage extends StatefulWidget {
  const AdminMembershipPage({super.key});

  @override
  State<AdminMembershipPage> createState() => _AdminMembershipPageState();
}

class _AdminMembershipPageState extends State<AdminMembershipPage> {
  int _tab = 0;
  int _tier = 0; // 0 semua, -1 belum berlangganan, 1..4 tingkat
  String _q = '';

  static final _tierItems = <int, String>{
    0: 'Semua pelanggan',
    -1: 'Belum berlangganan',
    for (final t in MembershipTier.values) t.rank: t.label,
  };

  Future<void> _editPlan(MembershipPlan p) async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _PlanDialog(p));
    if (!mounted) return;
    if (saved == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tingkatan ${p.name} disimpan.')));
    }
  }

  void _detail(AdminCustomer c) {
    final m = c.membership;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [InitialAvatar(c.name, size: 44), const SizedBox(width: 12), Expanded(child: TwoLine(c.name, c.email))]),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              kv('Status', m == null ? 'Belum berlangganan' : (c.hasActiveMembership ? 'Aktif' : m.status.label)),
              if (m != null) ...[
                kv('Tingkatan', m.tier.label),
                if (m.startDate != null) kv('Mulai', fmtDate.format(m.startDate!)),
                if (m.endDate != null) kv('Berakhir', fmtDate.format(m.endDate!)),
                if (c.hasActiveMembership) kv('Sisa masa aktif', '${m.daysLeft} hari'),
                const Divider(height: 20),
                const Text('Benefit paket', style: TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
                const SizedBox(height: 6),
                for (final b in m.plan.benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_rounded, size: 16, color: kGreen),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                    ]),
                  ),
              ],
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _customers(AdminOverview ov) {
    final q = _q.trim().toLowerCase();
    final list = ov.customers.where((c) {
      if (_tier == -1 && c.membership != null) return false;
      if (_tier > 0 && c.membership?.tier.rank != _tier) return false;
      return q.isEmpty || c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q);
    }).toList();
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SearchBox(hint: 'Cari nama atau email', onChanged: (v) => setState(() => _q = v)),
          AdminDropdown<int>(value: _tier, items: _tierItems, onChanged: (v) => setState(() => _tier = v)),
        ]),
        const SizedBox(height: 14),
        AdminTable(
          minWidth: 900,
          emptyText: 'Tidak ada pelanggan yang cocok.',
          cols: const [TCol('Pelanggan', flex: 4), TCol('Tingkatan', flex: 2), TCol('Status', flex: 2), TCol('Mulai', flex: 2), TCol('Berakhir', flex: 2), TCol('Aksi', flex: 2)],
          rows: [
            for (final c in list)
              [
                PersonCell(c.name, c.email),
                leftCell(c.membership == null ? const Text('-') : StatusBadge(c.membership!.tier.label, c.membership!.tier.color)),
                leftCell(c.membership == null
                    ? const StatusBadge('Belum berlangganan', kMuted)
                    : StatusBadge(c.hasActiveMembership ? 'Aktif' : c.membership!.status.label, c.hasActiveMembership ? kGreen : c.membership!.status.color)),
                Text(c.membership?.startDate == null ? '-' : fmtDate.format(c.membership!.startDate!), style: const TextStyle(fontSize: 13)),
                TwoLine(c.membership?.endDate == null ? '-' : fmtDate.format(c.membership!.endDate!), c.hasActiveMembership ? 'Sisa ${c.membership!.daysLeft} hari' : null, false),
                leftCell(SmallOutlineButton('Detail', () => _detail(c), chevron: false)),
              ],
          ],
        ),
      ]),
    );
  }

  Widget _plans(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AutoGrid(minWidth: 250, gap: 14, children: [
          for (final p in kMembershipPlans)
            AdminCard(
              border: kBlueLine,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconBox(p.tier.icon, p.tier.color, size: 42),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kNavy))),
                  if (p.popular) const StatusBadge('Populer', kRed),
                ]),
                const SizedBox(height: 10),
                Text(rp(p.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kNavy)),
                Text('Masa berlaku ${p.durationLabel}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
                const Divider(height: 22),
                kv('Cuci gratis', p.freeWashLabel),
                for (final perk in p.visitPerks) kv('Saat cuci', perk),
                kv('Klaim voucher', '${p.tier.dailyVoucherLimit}x / hari'),
                kv('Diskon layanan', '${p.discountPct}%'),
                kv('Prioritas', p.priority),
                kv('Promo', p.promo),
                const SizedBox(height: 6),
                for (final b in p.benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_rounded, size: 16, color: kGreen),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: const TextStyle(fontSize: 12.5))),
                    ]),
                  ),
                const SizedBox(height: 10),
                SmallOutlineButton('Ubah tingkatan', () => _editPlan(p), chevron: false),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        const AdminCard(
          color: kBlueSoft,
          border: kBlueLine,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardTitle('Syarat kenaikan level', color: kNavy),
            SizedBox(height: 8),
            Text(
              'Level tidak naik otomatis. Membership adalah produk berbayar: pelanggan naik atau pindah tingkat dengan membeli paket '
              'yang diinginkan, dan Coins tidak memengaruhi level. Masa berlaku mengikuti durasi paket dan bisa diperpanjang.',
              style: TextStyle(height: 1.5, fontSize: 13),
            ),
          ]),
        ),
      ]);

  Widget _history(AdminOverview ov) => AdminCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: AdminTable(
          minWidth: 880,
          emptyText: 'Belum ada pembelian atau perpanjangan membership.',
          cols: const [TCol('Waktu', flex: 2), TCol('Pelanggan', flex: 3), TCol('Paket', flex: 2), TCol('Jenis', flex: 2), TCol('Metode', flex: 2), TCol('Nominal', flex: 2)],
          rows: [
            for (final r in ov.memberTx)
              [
                TwoLine(fmtDate.format(r.tx.createdAt), fmtHm.format(r.tx.createdAt), false),
                PersonCell(r.customer),
                leftCell(StatusBadge(r.tx.tier.label, r.tx.tier.color)),
                Text(r.tx.refund ? 'Pengembalian dana' : (r.tx.renewal ? 'Perpanjangan' : 'Pembelian baru'), style: const TextStyle(fontSize: 13)),
                Text(r.tx.method.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                Text(r.tx.refund ? '-${rp(r.tx.amount)}' : rp(r.tx.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => OverviewGate(builder: (ov) {
        final counts = {for (final t in MembershipTier.values) t: 0};
        for (final c in ov.customers) {
          final t = c.activeTier;
          if (t != null) counts[t] = (counts[t] ?? 0) + 1;
        }
        final active = counts.values.fold<int>(0, (s, v) => s + v);
        final inactive = ov.customers.where((c) => c.membership != null && !c.hasActiveMembership).length;
        final revenue = ov.memberTx.fold<int>(0, (s, r) => s + (r.tx.refund ? -r.tx.amount : r.tx.amount));
        Widget content = switch (_tab) {
          0 => _customers(ov),
          1 => _plans(context),
          _ => _history(ov),
        };
        return AdminPageBody(children: [
          StatGrid([
            MiniStat(Icons.workspace_premium_rounded, kBlue, 'Total Member Aktif', fmtNum(active), bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.groups_rounded, kNavy, 'Pelanggan Terdaftar', fmtNum(ov.customers.length), bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.timer_off_outlined, kWarn, 'Tidak Aktif', fmtNum(inactive), sub: 'kedaluwarsa atau dibatalkan', bg: kBlueSoft, border: kBlueLine),
            MiniStat(Icons.payments_outlined, kGreen, 'Pendapatan Membership', rp(revenue), bg: kBlueSoft, border: kBlueLine),
          ]),
          const SizedBox(height: 16),
          AdminCard(
            color: kBlueSoft,
            border: kBlueLine,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const CardTitle('Distribusi Membership', color: kNavy, leading: Icon(Icons.workspace_premium_rounded, color: kNavy)),
              const SizedBox(height: 8),
              TierBars(counts),
            ]),
          ),
          const SizedBox(height: 16),
          PillBar(labels: const ['Pelanggan', 'Tingkatan & Benefit', 'Riwayat'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 8),
          content,
        ]);
      });
}

// ---------------------------------------------------------------------------
// Dialog ubah satu tingkatan membership. Validasi sama dengan server (AdminSettingsController::savePlan).
// ---------------------------------------------------------------------------
class _PlanDialog extends StatefulWidget {
  final MembershipPlan plan;
  const _PlanDialog(this.plan);

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  static const _washNames = ['Express', 'Reguler', 'Detailing'];

  late final TextEditingController _price = TextEditingController(text: '${widget.plan.price}');
  late final TextEditingController _discount = TextEditingController(text: '${widget.plan.discountPct}');
  late final TextEditingController _priority = TextEditingController(text: widget.plan.priority);
  late final TextEditingController _promo = TextEditingController(text: widget.plan.promo);
  late final TextEditingController _quota = TextEditingController(text: '${widget.plan.freeWashQuota}');
  late final TextEditingController _benefits = TextEditingController(text: widget.plan.benefits.join('\n'));
  late String _free = widget.plan.freePackage;
  late Set<VehicleType> _veh = {...widget.plan.freeVehicles};
  late bool _snack = widget.plan.snack;
  late bool _vip = widget.plan.vip;
  late bool _massage = widget.plan.massage;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _priority.dispose();
    _promo.dispose();
    _quota.dispose();
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.trim());
    final discount = int.tryParse(_discount.text.trim());
    final quota = int.tryParse(_quota.text.trim());
    final priority = _priority.text.trim();
    final promo = _promo.text.trim();
    final benefits = _benefits.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String? err;
    if (price == null || price < 1000 || price > 100000000) {
      err = 'Harga harus berupa angka minimal Rp 1.000.';
    } else if (discount == null || discount < 0 || discount > 100) {
      err = 'Diskon harus berupa angka 0 sampai 100.';
    } else if (priority.isEmpty || priority.length > 60) {
      err = 'Prioritas booking wajib diisi (maksimal 60 karakter).';
    } else if (promo.length > 120) {
      err = 'Promo maksimal 120 karakter.';
    } else if (_free.isNotEmpty && (quota == null || quota < 1 || quota > 100)) {
      err = 'Jatah cuci gratis harus berupa angka 1 sampai 100.';
    } else if (_free.isNotEmpty && _veh.isEmpty) {
      err = 'Pilih minimal satu jenis kendaraan untuk cuci gratis.';
    } else if (benefits.isEmpty || benefits.length > 12) {
      err = 'Benefit minimal 1 baris dan maksimal 12 baris.';
    } else if (benefits.any((b) => b.length > 120)) {
      err = 'Setiap baris benefit maksimal 120 karakter.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final plan = MembershipPlan(
      tier: widget.plan.tier,
      price: price!,
      durationDays: widget.plan.durationDays,
      discountPct: discount!,
      priority: priority,
      benefits: benefits,
      promo: promo,
      popular: widget.plan.popular,
      freePackage: _free,
      freeWashQuota: _free.isEmpty ? 0 : quota!,
      freeVehicles: _free.isEmpty ? <VehicleType>{} : _veh,
      snack: _snack,
      vip: _vip,
      massage: _massage,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.repo.savePlan(plan);
      await app.loadCatalog(force: true);
      await app.refreshAll();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan. Periksa koneksi ke server lalu coba lagi.';
        });
      }
    }
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );

  Widget _head(String s) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Ubah tingkatan ${widget.plan.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _num(_price, 'Harga (Rp)')),
                const SizedBox(width: 12),
                Expanded(child: _num(_discount, 'Diskon layanan (%)')),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _priority, enabled: !_saving, decoration: const InputDecoration(labelText: 'Prioritas booking')),
              const SizedBox(height: 8),
              TextField(controller: _promo, enabled: !_saving, decoration: const InputDecoration(labelText: 'Promo eksklusif')),
              _head('Cuci gratis'),
              Wrap(spacing: 8, runSpacing: 6, children: [
                ChoiceChip(label: const Text('Tidak ada'), selected: _free.isEmpty, onSelected: _saving ? null : (_) => setState(() => _free = '')),
                for (final n in _washNames)
                  ChoiceChip(label: Text(n), selected: _free == n, onSelected: _saving ? null : (_) => setState(() => _free = n)),
              ]),
              if (_free.isNotEmpty) ...[
                const SizedBox(height: 10),
                _num(_quota, 'Total jatah selama masa aktif (kali)'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final v in VehicleType.values)
                    FilterChip(
                      label: Text(v.label),
                      selected: _veh.contains(v),
                      onSelected: _saving
                          ? null
                          : (on) => setState(() {
                                if (on) {
                                  _veh.add(v);
                                } else {
                                  _veh.remove(v);
                                }
                              }),
                    ),
                ]),
              ],
              _head('Saat cuci'),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Makanan & minuman gratis'), value: _snack, onChanged: _saving ? null : (v) => setState(() => _snack = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Ruang tunggu VIP'), value: _vip, onChanged: _saving ? null : (v) => setState(() => _vip = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Kursi pijat'), value: _massage, onChanged: _saving ? null : (v) => setState(() => _massage = v)),
              _head('Daftar benefit (satu per baris)'),
              TextField(controller: _benefits, enabled: !_saving, minLines: 4, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text(
                'Daftar benefit dan promo hanya tulisan. Yang dipakai saat transaksi adalah kolom angka (harga, diskon, jatah cuci gratis), jadi samakan keduanya. Diskon layanan langsung berlaku di pesanan berikutnya, termasuk untuk member yang sudah aktif. Harga dan jatah cuci gratis berlaku untuk pembelian dan perpanjangan berikutnya.',
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: kError, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ],
      );
}
