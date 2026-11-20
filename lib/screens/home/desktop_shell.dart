import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../profile/profile_widgets.dart' show kProNavy, kProRoyal, kProGold;

// ===========================================================================
// TATA LETAK LAPTOP / DESKTOP (lebar >= kDesktopShellMin).
// Menu samping (sidebar) menggantikan menu bawah, dan isi halaman dibatasi
// selebar kContentMax lalu dipusatkan agar tidak melebar di monitor besar.
// Di HP (lebar kurang dari itu) tampilan tidak berubah.
// ===========================================================================

/// Lebar layar mulai dari ini memakai menu samping.
const double kDesktopShellMin = 900;

/// Lebar maksimum isi halaman di layar lebar.
const double kContentMax = 1180;

/// Lebar area isi (tanpa sidebar) mulai dari ini dianggap "lebar": halaman memakai beberapa kolom.
const double kWideContentMin = 820;

/// Jarak tepi horizontal isi halaman di layar lebar.
const double kWidePad = 28;

class DesktopSidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const DesktopSidebar({super.key, required this.index, required this.onSelect});

  static const _items = [
    (Icons.home_rounded, 'Beranda'),
    (Icons.history_rounded, 'Riwayat'),
    (Icons.directions_car_filled_rounded, 'Booking'),
    (Icons.storefront_rounded, 'Toko'),
    (Icons.person_rounded, 'Akun'),
  ];

  Widget _item(int i) {
    final on = index == i;
    final isBooking = i == 2;
    final (icon, label) = _items[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isBooking ? const LinearGradient(colors: [Color(0xFFE5393F), kRed]) : null,
              color: isBooking ? null : (on ? Colors.white.withValues(alpha: .14) : Colors.transparent),
              border: isBooking && on ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isBooking ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 16, offset: Offset(0, 6))] : null,
            ),
            child: Row(children: [
              Icon(icon, size: 24, color: on || isBooking ? Colors.white : Colors.white70),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: on || isBooking ? FontWeight.w800 : FontWeight.w600,
                        color: on || isBooking ? Colors.white : Colors.white70)),
              ),
              if (on && !isBooking) Container(width: 4, height: 22, decoration: BoxDecoration(color: kProGold, borderRadius: BorderRadius.circular(4))),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final name = (app.user ?? '').trim();
          final initial = name.isEmpty ? '?' : name[0].toUpperCase();
          return Container(
            width: 252,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kProNavy, Color(0xFF0B3380), kProRoyal]),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Row(children: [
                      Image.asset('assets/images/profile_logo_mark.png', height: 42),
                      const SizedBox(width: 10),
                      const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'Clean', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'Drive', style: TextStyle(color: kProGold)),
                        ]),
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.3),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 34),
                  for (var i = 0; i < _items.length; i++) _item(i),
                  const Spacer(),
                  // kartu pengguna (ketuk = buka Akun)
                  Material(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onSelect(4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: kProGold),
                            child: Text(initial, style: const TextStyle(color: kProNavy, fontWeight: FontWeight.w800, fontSize: 19)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name.isEmpty ? 'Pengguna' : name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                              Row(children: [
                                const Icon(Icons.toll_rounded, color: kProGold, size: 14),
                                const SizedBox(width: 4),
                                Text('${app.loyalty.balance} Coins', style: const TextStyle(color: kProGold, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ]),
                            ]),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      );
}