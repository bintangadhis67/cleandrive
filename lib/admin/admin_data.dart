import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../app_state.dart';
import '../data/repository.dart';
import '../models.dart';

// ---------------------------------------------------------------------------
// FORMAT ANGKA (gaya Indonesia: titik ribuan, koma desimal)
// ---------------------------------------------------------------------------
final _nf = NumberFormat.decimalPattern('id_ID');

String fmtNum(num n) => _nf.format(n);

String fmtPct(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// Label sumbu grafik: 15 jt, 250 rb, 0.
String fmtAxis(double v) {
  String t(double x) => x.toStringAsFixed(x == x.roundToDouble() ? 0 : 1).replaceAll('.', ',');
  if (v >= 1e6) return '${t(v / 1e6)} jt';
  if (v >= 1e3) return '${t(v / 1e3)} rb';
  return v.round().toString();
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Tanggal yang dipilih di header admin (dipakai "Antrean Hari Ini").
final ValueNotifier<DateTime> adminDate = ValueNotifier<DateTime>(dayOf(DateTime.now()));

// ---------------------------------------------------------------------------
// TREN MINGGUAN: 7 hari terakhir dibanding 7 hari sebelumnya
// ---------------------------------------------------------------------------
class Trend {
  final bool up;
  final String text;
  const Trend(this.up, this.text);
}

Trend? weeklyTrend(Iterable<Booking> list, num Function(Booking) value) {
  final today = dayOf(DateTime.now());
  final startThis = today.subtract(const Duration(days: 6));
  final startPrev = today.subtract(const Duration(days: 13));
  final end = today.add(const Duration(days: 1));
  num now = 0, prev = 0;
  for (final b in list) {
    if (!b.slot.isBefore(startThis) && b.slot.isBefore(end)) {
      now += value(b);
    } else if (!b.slot.isBefore(startPrev) && b.slot.isBefore(startThis)) {
      prev += value(b);
    }
  }
  if (now == 0 && prev == 0) return null;
  if (prev == 0) return const Trend(true, 'Baru minggu ini');
  final pct = (now - prev) / prev * 100;
  return Trend(pct >= 0, '${fmtPct(pct.abs())}% dari minggu lalu');
}

// ---------------------------------------------------------------------------
// PENDAPATAN PER BULAN (pesanan selesai dan lunas, sama dengan definisi Ringkasan lama)
// ---------------------------------------------------------------------------
class MonthRevenue {
  final DateTime month;
  final int amount;
  const MonthRevenue(this.month, this.amount);
}

List<MonthRevenue> monthlyRevenue(Iterable<Booking> list, int months) {
  final now = DateTime.now();
  final out = <MonthRevenue>[];
  for (var i = months - 1; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    final sum = list
        .where((b) => !b.cancelled && b.status >= 3 && b.paid && b.slot.year == m.year && b.slot.month == m.month)
        .fold<int>(0, (s, b) => s + b.total);
    out.add(MonthRevenue(m, sum));
  }
  return out;
}

// ---------------------------------------------------------------------------
// PEMUAT DATA ADMIN
// Pesanan memakai app.bookings (sudah ada). Ringkasan, ulasan, dan data lintas pelanggan dimuat di sini
// dan diperbarui otomatis tiap 8 detik selama panel admin terbuka.
// ---------------------------------------------------------------------------
class AdminData extends ChangeNotifier {
  AdminSummary? summary;
  AdminOverview? overview;
  List<Booking> reviews = const [];
  bool loaded = false;
  String? error;

  Timer? _timer;
  int _users = 0;
  bool _busy = false;

  void attach() {
    if (_users++ == 0) {
      load();
      _timer = Timer.periodic(const Duration(seconds: 8), (_) => load());
    }
  }

  void detach() {
    if (--_users <= 0) {
      _users = 0;
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    try {
      await app.refreshAll();
      summary = await app.summary();
      overview = await app.repo.adminOverview();
      reviews = await app.allReviews();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Gagal memuat data. Tarik layar atau tekan Coba Lagi.';
    }
    _busy = false;
    loaded = true;
    notifyListeners();
  }
}

final AdminData adminData = AdminData();
