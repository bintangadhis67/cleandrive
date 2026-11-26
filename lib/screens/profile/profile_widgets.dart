import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/loyalty_models.dart';
import '../../models/membership_models.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../rewards/loyalty.dart';
import '../rewards/membership.dart';

// ===========================================================================
// WIDGET REUSABLE HALAMAN AKUN / PROFIL (redesign).
// Warna mengikuti brief: navy #08265C, royal blue #164A9B, putih, gold #FFBE27.
// ===========================================================================

const kProNavy = Color(0xFF08265C);
const kProRoyal = Color(0xFF164A9B);
const kProGold = Color(0xFFFFBE27);

const _kCardShadow = [BoxShadow(color: Color(0x1A08265C), blurRadius: 22, offset: Offset(0, 8))];

// ---------------------------------------------------------------------------
// HEADER PROFIL
// ---------------------------------------------------------------------------
class ProfileHeader extends StatelessWidget {
  final VoidCallback onSettings, onEdit, onMembership;

  /// true = layar lebar (laptop/desktop): header berbentuk kartu bulat dengan margin, ukuran lebih besar.
  final bool wide;
  const ProfileHeader({super.key, required this.onSettings, required this.onEdit, required this.onMembership, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final top = wide ? 4.0 : MediaQuery.paddingOf(context).top;
    final name = (app.user ?? '').trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final mem = app.membership;
    final cur = mem.current;
    final active = mem.hasActive && cur != null;
    final radius = wide ? BorderRadius.circular(34) : const BorderRadius.vertical(bottom: Radius.circular(34));

    return Container(
      margin: wide ? const EdgeInsets.fromLTRB(28, 24, 28, 0) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kProNavy, Color(0xFF0B3380), kProRoyal],
        ),
        boxShadow: const [BoxShadow(color: Color(0x4008265C), blurRadius: 26, offset: Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(children: [
          // kilau lembut di kanan atas
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.75, -.8),
                  radius: 1.0,
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          // foto mobil + percikan air: memakai gambar yang sama dengan Beranda (utuh, tidak bolong)
          Positioned(
            right: wide ? -10 : -34,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset('assets/images/home_hero_car.png', width: wide ? 620 : 340, fit: BoxFit.fitWidth),
            ),
          ),
          Padding(
            padding: wide ? const EdgeInsets.fromLTRB(28, 22, 24, 28) : EdgeInsets.fromLTRB(20, top + 14, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ---- baris atas: logo + ikon pengaturan ----
              Row(children: [
                Image.asset('assets/images/profile_logo_mark.png', height: 34),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Clean', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Drive', style: TextStyle(color: kProGold)),
                  ]),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Pengaturan',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                ),
              ]),
              const SizedBox(height: 14),
              // ---- avatar + data pengguna ----
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                _Avatar(initial: initial, size: wide ? 110 : 88),
                SizedBox(width: wide ? 22 : 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(name.isEmpty ? 'Pengguna' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: wide ? 30 : 22, fontWeight: FontWeight.w800)),
                      ),
                      if (active) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF3B9BFF), size: 20),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    if (app.email.isNotEmpty) _info(Icons.mail_outline_rounded, app.email, wide: wide),
                    if (app.phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _info(Icons.phone_outlined, app.phone, wide: wide),
                    ],
                    const SizedBox(height: 10),
                    _MemberPill(
                      label: active ? '${cur.tier.label} Member' : 'Belum Berlangganan',
                      onTap: onMembership,
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              // ---- tombol Edit Profil: di bawah avatar (kiri), bukan di bawah mobil ----
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kProNavy,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profil'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _info(IconData icon, String text, {bool wide = false}) => Row(children: [
        Icon(icon, size: wide ? 18 : 16, color: Colors.white70),
        const SizedBox(width: 7),
        Flexible(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: wide ? 15 : 13)),
        ),
      ]);
}

/// Avatar lingkaran dengan inisial nama (tanpa ikon kamera / ganti foto).
class _Avatar extends StatelessWidget {
  final String initial;
  final double size;
  const _Avatar({required this.initial, this.size = 88});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [kProGold, Color(0xFFE5393F), kProGold, kProGold]),
        ),
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: kProNavy),
          alignment: Alignment.center,
          child: Text(initial, style: TextStyle(color: Colors.white, fontSize: size * .43, fontWeight: FontWeight.w700)),
        ),
      );
}

class _MemberPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MemberPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.white.withValues(alpha: .14),
          shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: .20))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.workspace_premium_rounded, color: kProGold, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// KARTU COINS
// ---------------------------------------------------------------------------
class ProfileCoinsCard extends StatefulWidget {
  const ProfileCoinsCard({super.key});
  @override
  State<ProfileCoinsCard> createState() => _ProfileCoinsCardState();
}

class _ProfileCoinsCardState extends State<ProfileCoinsCard> {
  bool _busy = false;

  void _openCoins() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));

  void _info() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tentang Coins'),
          content: Text(kCoinsUsageNote, style: const TextStyle(height: 1.45)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );

  /// Konfirmasi dulu, lalu check-in. Check-in berulang di hari yang sama dicegah.
  Future<void> _checkIn() async {
    final l = app.loyalty;
    if (l.checkedInToday) {
      toast(context, 'Kamu sudah check-in hari ini. Kembali lagi besok!');
      return;
    }
    final reward = l.rewardFor(l.todayIndex);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-in hari ini?'),
        content: Text(
          'Kamu akan mendapat +$reward Coins.\nCheck-in hanya bisa dilakukan 1x per hari, dan streak akan terus bertambah bila dilakukan setiap hari.',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Check-in +$reward'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await doCheckIn(context);
    if (mounted) setState(() => _busy = false);
  }

  // Mendengarkan `app` sendiri agar langsung berubah saat Coins bertambah (check-in, klaim, ulasan, pembayaran),
  // tanpa menunggu halaman induk dibangun ulang.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _buildCard(context));

  Widget _buildCard(BuildContext context) {
    final l = app.loyalty;
    final done = l.checkedInToday;
    return _GradientCard(
      colors: const [Color(0xFF0B2F73), Color(0xFF08265C)],
      watermark: Icons.workspace_premium_rounded,
      onTap: _openCoins,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Image.asset('assets/images/profile_coins.png', width: 46, height: 46, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Coins', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                InkResponse(
                  onTap: _info,
                  radius: 16,
                  child: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                ),
              ]),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('${l.balance}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.bolt_rounded, color: kProGold, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Streak ${l.activeStreak} hari',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (l.doneDays / 7).clamp(0.0, 1.0),
            minHeight: 6,
            color: kProGold,
            backgroundColor: Colors.white.withValues(alpha: .20),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: done
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: kGreen.withValues(alpha: .25), borderRadius: BorderRadius.circular(22)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF6FE0A6)),
                    SizedBox(width: 6),
                    Text('Sudah check-in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  onPressed: _busy ? null : _checkIn,
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.card_giftcard_rounded, size: 18),
                          const SizedBox(width: 6),
                          Flexible(child: Text('Check-in +${l.rewardFor(l.todayIndex)}', overflow: TextOverflow.ellipsis)),
                        ]),
                ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// KARTU MEMBERSHIP
// ---------------------------------------------------------------------------
class ProfileMembershipCard extends StatelessWidget {
  const ProfileMembershipCard({super.key});

  void _info(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tentang Membership'),
          content: const Text(
            'Membership adalah paket berbayar (masa aktif 1 bulan) dengan diskon layanan, jatah cuci gratis, dan benefit kunjungan. '
            'Membership terpisah dari Coins dan tidak bisa dibeli dengan Coins.',
            style: TextStyle(height: 1.45),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );

  // Mendengarkan `app` sendiri agar langsung berubah saat membership dibeli, aktif, atau dibatalkan.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _buildCard(context));

  Widget _buildCard(BuildContext context) {
    final info = app.membership;
    final cur = info.current;
    final active = info.hasActive && cur != null;
    final String title = active ? '${cur.tier.label} Member' : 'Belum Berlangganan';
    final String sub = active
        ? 'Berlaku hingga ${fmtDate.format(cur.endDate!)}'
        : (info.status == MembershipStatus.pending ? 'Menunggu pembayaran' : 'Mulai ${rp(kMembershipPlans.first.price)}');

    return _GradientCard(
      colors: const [Color(0xFF1A2F85), Color(0xFF3A2C8C)],
      watermark: Icons.workspace_premium_rounded,
      onTap: () => showMembershipDetailSheet(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset('assets/images/profile_membership.png', width: 40, height: 52, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                const Text('Membership', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                InkResponse(
                  onTap: () => _info(context),
                  radius: 16,
                  child: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 4),
        Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        const Spacer(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(color: Colors.white.withValues(alpha: .75), width: 1.2),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            onPressed: () => showMembershipDetailSheet(context),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text('Lihat Detail', overflow: TextOverflow.ellipsis)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Bottom sheet informasi paket membership (tombol "Lihat Detail").
void showMembershipDetailSheet(BuildContext context) {
  final info = app.membership;
  final cur = info.current;
  final active = info.hasActive && cur != null;

  Widget row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: kProRoyal),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: kMuted, fontSize: 13.5))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ]),
      );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (active) ...[
              Row(children: [
                TierBadge(cur.tier),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${cur.tier.label} Member',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kProNavy)),
                ),
                MembershipStatusChip(info.status),
              ]),
              const SizedBox(height: 6),
              row(Icons.event_available_rounded, 'Berlaku hingga', fmtDate.format(cur.endDate!)),
              row(Icons.percent_rounded, 'Diskon jasa layanan', '${cur.plan.discountPct}%'),
              if (cur.plan.hasFreeWash) ...[
                row(Icons.local_car_wash_rounded, 'Cuci gratis', cur.plan.freeWashLabel),
                row(Icons.confirmation_number_outlined, 'Sisa jatah', '${cur.freeLeft} dari ${cur.freeTotal}'),
              ],
              row(Icons.flash_on_rounded, 'Prioritas', cur.plan.priority),
              row(Icons.local_offer_outlined, 'Klaim voucher', '${cur.tier.dailyVoucherLimit}x per hari'),
              for (final p in cur.plan.visitPerks) row(Icons.star_outline_rounded, 'Kunjungan', p),
              const SizedBox(height: 8),
              const Text('Benefit paket', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 6),
              for (final b in cur.plan.benefits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: kGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: const TextStyle(fontSize: 13.5, height: 1.35))),
                  ]),
                ),
            ] else ...[
              Row(children: [
                const Expanded(
                  child: Text('Belum Berlangganan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kProNavy)),
                ),
                MembershipStatusChip(info.status),
              ]),
              const SizedBox(height: 6),
              const Text('Pilih paket membership untuk diskon layanan, cuci gratis, dan benefit eksklusif.',
                  style: TextStyle(color: kMuted, height: 1.4)),
              const SizedBox(height: 12),
              for (final p in kMembershipPlans)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.tier.soft.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    TierBadge(p.tier),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Diskon ${p.discountPct}% • ${p.freeWashLabel}',
                          style: const TextStyle(fontSize: 12.5, height: 1.3)),
                    ),
                    const SizedBox(width: 8),
                    Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kRed),
              onPressed: () {
                Navigator.pop(ctx);
                openMembership(context);
              },
              child: Text(active ? 'Kelola Membership' : 'Lihat Paket Membership'),
            ),
          ]),
        ),
      ),
    ),
  );
}

/// Dasar kartu gradasi navy dengan watermark mahkota/medali di sudut kanan atas.
class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final IconData watermark;
  final Widget child;
  final VoidCallback? onTap;
  const _GradientCard({required this.colors, required this.watermark, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          boxShadow: _kCardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Stack(children: [
                Positioned(
                  right: -6,
                  top: 6,
                  child: Icon(watermark, size: 64, color: Colors.white.withValues(alpha: .07)),
                ),
                Padding(padding: const EdgeInsets.all(14), child: child),
              ]),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// MENU
// ---------------------------------------------------------------------------
class ProfileSectionTitle extends StatelessWidget {
  final String text;
  const ProfileSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 0, 12),
        child: Row(children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(color: kProRoyal, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kProNavy)),
        ]),
      );
}

/// Ikon menu: lingkaran lembut biru dengan ikon Material, opsional lencana angka.
class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final int badge;
  const _MenuIcon(this.icon, {this.size = 42, this.badge = 0});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: kProRoyal.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: kProRoyal, size: size * .58),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                child: Text(badge > 99 ? '99+' : '$badge',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
}

/// Kartu menu untuk grid 2 kolom (Menu Utama).
class ProfileGridTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final int badge;
  const ProfileGridTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kLineSoft),
          boxShadow: _kCardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(children: [
                _MenuIcon(icon, size: 40, badge: badge),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: kProNavy)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kProRoyal, height: 1.25)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: kProRoyal, size: 20),
              ]),
            ),
          ),
        ),
      );
}

/// Susun widget menjadi grid dua kolom dengan tinggi baris yang sama (tanpa overflow).
class ProfileTwoColumn extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  /// Jumlah kolom (2 di HP, 4 di layar lebar).
  final int columns;
  const ProfileTwoColumn({super.key, required this.children, this.gap = 12, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (i > 0) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var k = 0; k < columns; k++) ...[
            if (k > 0) SizedBox(width: gap),
            Expanded(child: i + k < children.length ? children[i + k] : const SizedBox.shrink()),
          ],
        ]),
      ));
    }
    return Column(children: rows);
  }
}

/// Baris menu berbentuk list (Aktivitas Saya & Pengaturan Akun).
class ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const ProfileListTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLineSoft),
          boxShadow: _kCardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(children: [
                _MenuIcon(icon, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kProNavy)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: kProRoyal)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: kProNavy, size: 24),
              ]),
            ),
          ),
        ),
      );
}