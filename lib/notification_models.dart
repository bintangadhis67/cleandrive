import 'package:flutter/material.dart';

import 'theme.dart';

enum NotifType {
  order(Icons.local_car_wash_rounded, Color(0xFF3B5FB8)),
  payment(Icons.verified_rounded, kGreen),
  points(Icons.monetization_on_rounded, Color(0xFFD08A00)),
  voucher(Icons.local_offer_rounded, kRed),
  promo(Icons.campaign_rounded, Color(0xFF8E44AD)),
  reminder(Icons.alarm_rounded, Color(0xFF0E8FA3));

  const NotifType(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// Notifikasi dalam aplikasi.
/// [target] menentukan layar tujuan saat diketuk: `order:<id>`, `vouchers`, `loyalty`, `shop`.
/// [push] = true untuk kejadian dari sisi layanan (status cucian, pengingat, naik level),
/// yang juga ditampilkan sebagai banner. Konfirmasi atas aksi pengguna sendiri tidak ditampilkan sebagai banner.
class AppNotification {
  final String id, title, body;
  final NotifType type;
  final DateTime createdAt;
  final String? target;
  final bool push;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.target,
    this.push = true,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'].toString(),
        type: NotifType.values.firstWhere((t) => t.name == j['type'], orElse: () => NotifType.promo),
        title: j['title'] as String,
        body: (j['body'] ?? '') as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        target: j['target'] as String?,
        push: (j['push'] ?? true) as bool,
        read: (j['read'] ?? false) as bool,
      );
}
