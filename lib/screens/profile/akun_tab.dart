import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/widgets.dart';
import '../home/customer.dart' show GoFn;
import '../notifications/notifications.dart';
import '../outlet/outlet.dart';
import '../rewards/membership.dart';
import '../rewards/voucher.dart';
import 'help.dart';
import 'profile_screens.dart';
import 'profile_widgets.dart';
import 'settings.dart';

// ===========================================================================
// HALAMAN AKUN / PROFIL (tab ke-5 di HomeScreen).
// Dipanggil dari customer.dart:  AkunTab(onGo: _go)
// ===========================================================================
class AkunTab extends StatelessWidget {
  final GoFn onGo;
  const AkunTab({super.key, required this.onGo});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _refresh() async {
    try {
      await app.refreshAll();
    } catch (_) {}
  }

  void _logout(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.logout_rounded, color: kRed, size: 30),
          title: const Text('Keluar dari akun?'),
          content: const Text('Kamu perlu masuk lagi untuk melihat pesanan dan Coins-mu.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                Navigator.pop(ctx);
                app.logout();
              },
              child: const Text('Keluar'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // ikon status bar (jam, baterai) putih karena header berwarna gelap
        value: SystemUiOverlayStyle.light,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final unread = app.unreadCount;
            return RefreshIndicator(
              color: kRed,
              edgeOffset: MediaQuery.paddingOf(context).top,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  ProfileHeader(
                    onSettings: () => _push(context, const SettingsScreen()),
                    onEdit: () => _push(context, const EditProfileScreen()),
                    onMembership: () => openMembership(context),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pagePadOf(context), 16, pagePadOf(context), 32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      // ---- Coins + Membership ----
                      const IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Expanded(child: ProfileCoinsCard()),
                          SizedBox(width: 12),
                          Expanded(child: ProfileMembershipCard()),
                        ]),
                      ),

                      // ---- Menu Utama ----
                      const ProfileSectionTitle('Menu Utama'),
                      ProfileTwoColumn(children: [
                        ProfileGridTile(
                          icon: Icons.person_rounded,
                          title: 'Edit Profil',
                          subtitle: 'Ubah informasi akun',
                          onTap: () => _push(context, const EditProfileScreen()),
                        ),
                        ProfileGridTile(
                          icon: Icons.local_activity_rounded,
                          title: 'Voucher Saya',
                          subtitle: 'Lihat voucher aktif',
                          onTap: () => _push(context, const MyVouchersScreen()),
                        ),
                        ProfileGridTile(
                          icon: Icons.storefront_rounded,
                          title: 'Lokasi Outlet',
                          subtitle: 'Cari outlet terdekat',
                          onTap: () => openOutlet(context),
                        ),
                        ProfileGridTile(
                          icon: Icons.notifications_rounded,
                          title: 'Notifikasi',
                          subtitle: unread > 0 ? '$unread belum dibaca' : 'Lihat pemberitahuan',
                          badge: unread,
                          onTap: () => _push(context, const NotificationScreen()),
                        ),
                      ]),

                      // ---- Aktivitas Saya ----
                      const ProfileSectionTitle('Aktivitas Saya'),
                      ProfileListTile(
                        icon: Icons.history_rounded,
                        title: 'Riwayat Transaksi',
                        subtitle: 'Lihat transaksi sebelumnya',
                        onTap: () => _push(context, const TransactionHistoryScreen()),
                      ),
                      ProfileListTile(
                        icon: Icons.event_available_rounded,
                        title: 'Riwayat Booking',
                        subtitle: 'Cek jadwal booking Anda',
                        onTap: () => _push(context, const BookingHistoryScreen()),
                      ),

                      // ---- Pengaturan Akun ----
                      const ProfileSectionTitle('Pengaturan Akun'),
                      ProfileListTile(
                        icon: Icons.security_rounded,
                        title: 'Keamanan Akun',
                        subtitle: 'Atur keamanan akun',
                        onTap: () => _push(context, const AccountSecurityScreen()),
                      ),
                      ProfileListTile(
                        icon: Icons.help_rounded,
                        title: 'Pusat Bantuan',
                        subtitle: 'FAQ & bantuan',
                        onTap: () => _push(context, const HelpScreen()),
                      ),
                      ProfileListTile(
                        icon: Icons.logout_rounded,
                        title: 'Keluar Akun',
                        subtitle: 'Keluar dari akun ini',
                        onTap: () => _logout(context),
                      ),

                      // ---- Tentang (fitur lama dipertahankan) ----
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: () => showAboutDialog(
                            context: context,
                            applicationName: 'CleanDrive',
                            applicationVersion: '1.3.0',
                            applicationLegalese: 'DRIVE CLEANER. GO FURTHER.',
                          ),
                          child: const Text('Tentang CleanDrive • v1.3.0', style: TextStyle(color: kMuted, fontSize: 12.5)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

/// Jarak tepi horizontal halaman (mengikuti pagePad di widgets.dart).
double pagePadOf(BuildContext context) => pagePad(MediaQuery.sizeOf(context).width);