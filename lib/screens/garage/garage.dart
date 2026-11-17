import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

// ---------- GARASI KENDARAAN ----------
class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  Future<void> _delete(BuildContext context, GarageVehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kendaraan?'),
        content: Text('${v.title} (${v.plate}) akan dihapus dari garasimu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = await guard(context, () async {
      await app.deleteVehicle(v.id);
      return true;
    });
    if (done == true && context.mounted) toast(context, 'Kendaraan dihapus');
  }

  Widget _card(BuildContext context, GarageVehicle v) => Panel(
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(16)),
            child: Icon(vehicleIcon(v.type), color: kCream, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              Text('${v.plate} • ${v.type.label}', style: const TextStyle(color: kMuted, fontSize: 13)),
              Text('${v.year}${v.color.isEmpty ? '' : ' • ${v.color}'}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, color: kNavy),
            onPressed: () => showVehicleForm(context, vehicle: v),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline_rounded, color: kError),
            onPressed: () => _delete(context, v),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kendaraan Saya')),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kRed,
          foregroundColor: Colors.white,
          onPressed: () => showVehicleForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah Kendaraan'),
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) => PageList(
            bottom: 96,
            onRefresh: app.refreshAll,
            children: [
              if (app.garage.isEmpty)
                EmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'Garasi masih kosong',
                  message: 'Simpan kendaraanmu supaya booking lebih cepat.',
                  actionLabel: 'Tambah Kendaraan',
                  onAction: () => showVehicleForm(context),
                )
              else
                AutoGrid(minWidth: 420, children: [for (final v in app.garage) _card(context, v)]),
            ],
          ),
        ),
      );
}

/// Formulir tambah / edit kendaraan (dialog).
Future<void> showVehicleForm(BuildContext context, {GarageVehicle? vehicle}) => showDialog<void>(
      context: context,
      builder: (_) => _VehicleForm(vehicle: vehicle),
    );

class _VehicleForm extends StatefulWidget {
  final GarageVehicle? vehicle;
  const _VehicleForm({this.vehicle});
  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _key = GlobalKey<FormState>();
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.mobil;
  late final _brand = TextEditingController(text: widget.vehicle?.brand ?? '');
  late final _model = TextEditingController(text: widget.vehicle?.model ?? '');
  late final _year = TextEditingController(text: widget.vehicle?.year.toString() ?? '');
  late final _color = TextEditingController(text: widget.vehicle?.color ?? '');
  late final _plate = TextEditingController(text: widget.vehicle?.plate ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _plate.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _yearRule(String? v) {
    final y = int.tryParse((v ?? '').trim());
    if (y == null) return 'Isi tahun dengan angka';
    if (y < 1980 || y > DateTime.now().year + 1) return 'Tahun tidak valid';
    return null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      await app.saveVehicle(GarageVehicle(
        id: widget.vehicle?.id ?? '',
        type: _type,
        brand: _brand.text,
        model: _model.text,
        year: int.parse(_year.text.trim()),
        color: _color.text,
        plate: _plate.text,
      ));
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      Navigator.pop(context);
      toast(context, widget.vehicle == null ? 'Kendaraan ditambahkan' : 'Kendaraan diperbarui');
    }
  }

  Widget _typeTile(VehicleType v) {
    final sel = _type == v;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: v == VehicleType.values.last ? 0 : 8),
        child: GestureDetector(
          onTap: () => setState(() => _type = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? kRed : Colors.white,
              borderRadius: BorderRadius.circular(kRadiusButton),
              border: Border.all(color: sel ? kRed : kLine),
            ),
            child: Column(children: [
              Icon(vehicleIcon(v), color: sel ? Colors.white : kNavy),
              Text(v.label, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? Colors.white : kNavy, fontSize: 12.5)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.vehicle == null ? 'Tambah Kendaraan' : 'Edit Kendaraan'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [for (final v in VehicleType.values) _typeTile(v)]),
                const SizedBox(height: 12),
                TextFormField(controller: _brand, validator: _req, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Merek')),
                const SizedBox(height: 12),
                TextFormField(controller: _model, validator: _req, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Model')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      validator: _yearRule,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tahun'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(controller: _color, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Warna')),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plate,
                  validator: _req,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Nomor polisi', hintText: 'mis. L 1234 AB'),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Simpan'),
          ),
        ],
      );
}