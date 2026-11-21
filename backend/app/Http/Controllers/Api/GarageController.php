<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Models\Vehicle;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Garasi kendaraan milik pengguna. */
class GarageController extends ApiController
{
    public function index(Request $request): JsonResponse
    {
        $list = $request->user()->vehicles()->orderBy('id')->get();

        return response()->json($list->map(fn (Vehicle $v) => Presenter::vehicle($v))->values());
    }

    public function store(Request $request): JsonResponse
    {
        $v = $this->save($request, new Vehicle(['user_id' => $request->user()->id]));

        return response()->json(Presenter::vehicle($v), 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $v = $request->user()->vehicles()->find($id);
        if (! $v) {
            throw new ApiException('Kendaraan tidak ditemukan.', 404);
        }

        return response()->json(Presenter::vehicle($this->save($request, $v)));
    }

    /** Menghapus kendaraan yang sudah tidak ada dianggap berhasil (sama dengan perilaku di Flutter). */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $request->user()->vehicles()->where('id', $id)->delete();

        return response()->json(['message' => 'Kendaraan dihapus']);
    }

    private function save(Request $request, Vehicle $v): Vehicle
    {
        $type = (string) $request->input('type');
        $plate = mb_strtoupper(trim((string) $request->input('plate')));
        $brand = trim((string) $request->input('brand'));
        $model = trim((string) $request->input('model'));
        $color = trim((string) $request->input('color', ''));
        $year = (int) $request->input('year');

        if ($plate === '') {
            throw new ApiException('Nomor polisi wajib diisi.');
        }
        if ($brand === '' || $model === '') {
            throw new ApiException('Merek dan model wajib diisi.');
        }
        if (! in_array($type, ['motor', 'mobil'], true)) {
            throw new ApiException('Jenis kendaraan tidak valid.');
        }
        if ($year < 1980 || $year > (int) now()->year + 1) {
            throw new ApiException('Tahun kendaraan tidak valid.');
        }
        if (mb_strlen($plate) > 20 || mb_strlen($brand) > 60 || mb_strlen($model) > 60 || mb_strlen($color) > 40) {
            throw new ApiException('Data kendaraan terlalu panjang.');
        }

        // Nomor polisi unik per pengguna, spasi diabaikan ("L 1234 AB" sama dengan "L1234AB").
        $norm = str_replace(' ', '', $plate);
        $dup = $request->user()->vehicles()
            ->when($v->exists, fn ($q) => $q->where('id', '!=', $v->id))
            ->get()
            ->contains(fn (Vehicle $e) => str_replace(' ', '', mb_strtoupper($e->plate)) === $norm);
        if ($dup) {
            throw new ApiException("Nomor polisi {$plate} sudah ada di garasimu.");
        }

        $v->fill(compact('type', 'brand', 'model', 'year', 'color', 'plate'))->save();

        return $v;
    }
}
