import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/app_state.dart';
import '../../core/theme.dart';
import 'pages/admin_catalog.dart';
import 'pages/admin_coins.dart';
import 'pages/admin_customers.dart';
import 'pages/admin_dashboard.dart';
import 'pages/admin_membership.dart';
import 'pages/admin_orders.dart';
import 'pages/admin_queue.dart';
import 'pages/admin_reviews.dart';
import 'pages/admin_settings.dart';
import 'pages/admin_verify.dart';
import 'shared/admin_data.dart';
import 'shared/admin_ui.dart';

// ---------------------------------------------------------------------------
// ADMIN PANEL CLEANDRIVE: kerangka (sidebar navy, header, isi halaman).
// Halaman-halamannya ada di folder lib/admin/. main.dart tetap memakai AdminScreen seperti sebelumnya.
// ---------------------------------------------------------------------------
const _menus = <(String, IconData)>[
  ('Dashboard', Icons.grid_view_rounded),
  ('Antrean Layanan', Icons.view_list_rounded),
  ('Verifikasi Tiket', Icons.qr_code_scanner_rounded),
  ('Pelanggan', Icons.people_alt_outlined),
  ('Pesanan & Transaksi', Icons.receipt_long_outlined),
  ('Layanan & Produk', Icons.inventory_2_outlined),
  ('CleanDrive Coins', Icons.monetization_on_outlined),
  ('Membership', Icons.workspace_premium_outlined),
  ('Ulasan', Icons.rate_review_outlined),
  ('Pengaturan', Icons.settings_outlined),
];

/// Lebar layar mulai dari ini memakai sidebar tetap; di bawahnya sidebar menjadi laci (drawer).
const _kSidebarBreakpoint = 1024.0;
const _kSidebarWidth = 264.0;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    adminDate.value = dayOf(DateTime.now());
    adminData.attach();
  }

  @override
  void dispose() {
    adminData.detach();
    super.dispose();
  }

  void _go(int i) {
    if (_scaffold.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
    setState(() => _idx = i);
  }

  Widget _page() => switch (_idx) {
        0 => AdminDashboard(onNavigate: _go),
        1 => const AdminQueuePage(),
        2 => const AdminVerifyPage(),
        3 => const AdminCustomersPage(),
        4 => const AdminOrdersPage(),
        5 => const AdminCatalogPage(),
        6 => const AdminCoinsPage(),
        7 => const AdminMembershipPage(),
        8 => const AdminReviewsPage(),
        _ => const AdminSettingsPage(),
      };

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = base.copyWith(textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(bodyColor: kText, displayColor: kText));
    return Theme(
      data: theme,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= _kSidebarBreakpoint;
        final contentW = c.maxWidth - (wide ? _kSidebarWidth : 0);
        return Scaffold(
          key: _scaffold,
          backgroundColor: kAdminBg,
          drawer: wide ? null : Drawer(width: 280, backgroundColor: kNavyDark, shape: const RoundedRectangleBorder(), child: _Sidebar(index: _idx, onSelect: _go)),
          body: Row(children: [
            if (wide) SizedBox(width: _kSidebarWidth, child: _Sidebar(index: _idx, onSelect: _go)),
            Expanded(
              child: SafeArea(
                left: !wide,
                child: Column(children: [
                  _Header(
                    title: _menus[_idx].$1,
                    showMenu: !wide,
                    compact: contentW < 640,
                    onMenu: () => _scaffold.currentState?.openDrawer(),
                    onGo: _go,
                  ),
                  Expanded(child: KeyedSubtree(key: ValueKey(_idx), child: _page())),
                ]),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// SIDEBAR
// ---------------------------------------------------------------------------
class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
        color: kNavyDark,
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 18),
            Image.asset('assets/images/logo_transparent.png', width: 118, fit: BoxFit.contain),
            const SizedBox(height: 4),
            const Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: .4)),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                for (var i = 0; i < _menus.length; i++)
                  _NavItem(label: _menus[i].$1, icon: _menus[i].$2, selected: i == index, onTap: () => onSelect(i)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.white24),
                  backgroundColor: Colors.white.withValues(alpha: .05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: app.logout,
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      );
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: selected ? kRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.white.withValues(alpha: .06),
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: selected
                  ? BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x55C62026), blurRadius: 14, offset: Offset(0, 6))])
                  : null,
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500))),
              ]),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// HEADER: judul, breadcrumb, tanggal, notifikasi, profil
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final String title;
  final bool showMenu, compact;
  final VoidCallback onMenu;
  final ValueChanged<int> onGo;
  const _Header({required this.title, required this.showMenu, required this.compact, required this.onMenu, required this.onGo});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: adminDate.value,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih tanggal',
    );
    if (d != null) adminDate.value = dayOf(d);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(compact ? 8 : 24, 14, compact ? 8 : 24, 10),
        child: Row(children: [
          if (showMenu) IconButton(tooltip: 'Menu', onPressed: onMenu, icon: const Icon(Icons.menu_rounded, color: kNavy)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 20 : 26, fontWeight: FontWeight.w800, color: kNavy)),
              Row(children: [
                InkWell(onTap: () => onGo(0), child: const Text('Beranda', style: TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w500))),
                const Text('  /  ', style: TextStyle(color: kMuted, fontSize: 13)),
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 13))),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<DateTime>(
            valueListenable: adminDate,
            builder: (_, d, __) => InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickDate(context),
              child: Container(
                height: 46,
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kCardLine)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: kNavy),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    Text(DateFormat('d MMMM yyyy', 'id_ID').format(d), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: kNavy)),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: kNavy),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Lonceng: jumlah pesanan lunas yang masih menunggu dikerjakan.
          ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final n = app.bookings.where((b) => !b.cancelled && !b.pack.isShop && b.paid && b.status == 0).length;
              return IconButton(
                tooltip: '$n pesanan menunggu dikerjakan',
                onPressed: () => showAllActivities(context),
                icon: Badge(
                  isLabelVisible: n > 0,
                  backgroundColor: kRed,
                  label: Text(n > 99 ? '99+' : '$n'),
                  child: const Icon(Icons.notifications_none_rounded, color: kNavy, size: 26),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: app,
            builder: (context, _) => PopupMenuButton<String>(
              tooltip: 'Akun admin',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'logout') {
                  app.logout();
                } else {
                  onGo(9);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
                PopupMenuItem(value: 'logout', child: Text('Keluar')),
              ],
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                InitialAvatar(app.user ?? 'Admin', size: 42),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.user ?? 'Admin', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: kNavy)),
                      const Text('Super Admin', style: TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: kMuted),
                ],
              ]),
            ),
          ),
        ]),
      );
}
