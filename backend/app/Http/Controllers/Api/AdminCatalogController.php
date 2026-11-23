<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Models\BookingItem;
use App\Models\Product;
use App\Services\ProductImageService;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Admin: tambah, ubah, dan hapus produk Toko / oli, termasuk unggah foto.
 * Dikirim sebagai multipart/form-data. Ubah memakai POST (bukan PUT) karena PHP tidak membaca file dari PUT.
 */
class AdminCatalogController extends ApiController
{
    /** Awalan ID produk per kategori: mk1, mn1, ol1, ... (sama dengan katalog Flutter). */
    private const PREFIX = ['makanan' => 'mk', 'minuman' => 'mn', 'oli' => 'ol'];

    public function store(Request $request): JsonResponse
    {
        $f = $this->fields($request);

        $product = DB::transaction(function () use ($request, $f) {
            $id = $this->nextId($f['category']);

            // Baris produk dibuat dulu karena tabel product_images mereferensikan products.id.
            $p = Product::create([
                'id' => $id,
                'name' => $f['name'],
                'description' => $f['description'],
                'details' => $f['details'] !== '' ? $f['details'] : null,
                'price' => $f['price'],
                'category' => $f['category'],
                'image' => '',
                'stock' => $f['stock'],
                'vehicles' => $f['vehicles'] ?: null,
                'sort' => (int) Product::max('sort') + 1,
                'is_active' => true,
            ]);
            if ($file = $request->file('image')) {
                $p->update(['image' => ProductImageService::saveUpload($id, $file)]);
            }

            return $p;
        });

        return response()->json(Presenter::product($product->fresh()), 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $p = Product::find($id) ?? throw new ApiException('Produk tidak ditemukan.', 404);
        $f = $this->fields($request);

        $data = [
            'name' => $f['name'],
            'description' => $f['description'],
            'details' => $f['details'] !== '' ? $f['details'] : null,
            'price' => $f['price'],
            'category' => $f['category'],
            'stock' => $f['stock'],
            'vehicles' => $f['vehicles'] ?: null,
            'is_active' => true, // mengubah produk yang tadinya nonaktif sekaligus mengaktifkannya lagi
        ];
        if ($file = $request->file('image')) {
            $old = $p->image;
            $data['image'] = ProductImageService::saveUpload($p->id, $file); // menggantikan gambar lama di database
            ProductImageService::deleteLegacyFile($old);
        }
        $p->update($data);

        return response()->json(Presenter::product($p->fresh()));
    }

    /**
     * Produk yang belum pernah dipesan dihapus beserta fotonya. Yang sudah pernah dipesan hanya
     * dinonaktifkan, supaya riwayat pesanan tetap utuh.
     */
    public function destroy(string $id): JsonResponse
    {
        $p = Product::find($id) ?? throw new ApiException('Produk tidak ditemukan.', 404);

        if (BookingItem::where('product_id', $p->id)->exists()) {
            $p->update(['is_active' => false]);

            return response()->json([
                'message' => "{$p->name} dinonaktifkan karena sudah pernah dipesan. Riwayat pesanan tetap utuh.",
                'deactivated' => true,
            ]);
        }

        ProductImageService::deleteLegacyFile($p->image);
        $name = $p->name;
        $p->delete(); // baris gambar di product_images ikut terhapus (foreign key cascade)

        return response()->json(['message' => "{$name} dihapus.", 'deactivated' => false]);
    }

    // ---------------------------------------------------------------- helper

    /** Validasi dan rapikan isian form. Pesan error berbahasa Indonesia, tampil apa adanya di aplikasi. */
    private function fields(Request $request): array
    {
        $name = trim((string) $request->input('name'));
        $description = trim((string) $request->input('description', ''));
        $details = trim((string) $request->input('details', ''));
        $category = (string) $request->input('category');
        $price = $request->input('price');
        $stock = $request->input('stock');

        if ($name === '') {
            throw new ApiException('Nama produk wajib diisi.');
        }
        if (mb_strlen($name) > 120) {
            throw new ApiException('Nama produk maksimal 120 karakter.');
        }
        if (mb_strlen($description) > 255) {
            throw new ApiException('Deskripsi singkat maksimal 255 karakter.');
        }
        if (mb_strlen($details) > 2000) {
            throw new ApiException('Keterangan lengkap maksimal 2000 karakter.');
        }
        if (! isset(self::PREFIX[$category])) {
            throw new ApiException('Kategori tidak valid.');
        }
        if (! is_numeric($price) || (int) $price < 1 || (int) $price > 100000000) {
            throw new ApiException('Harga harus berupa angka lebih dari 0.');
        }
        if (! is_numeric($stock) || (int) $stock < 0 || (int) $stock > 99999) {
            throw new ApiException('Stok harus berupa angka 0 atau lebih.');
        }

        // Kendaraan hanya berlaku untuk oli. Kosong = cocok untuk semua kendaraan.
        $vehicles = [];
        if ($category === 'oli') {
            $raw = $request->input('vehicles', '');
            $list = is_array($raw) ? $raw : explode(',', (string) $raw);
            $vehicles = array_values(array_unique(array_filter(array_map(fn ($v) => strtolower(trim((string) $v)), $list))));
            if (array_diff($vehicles, ['motor', 'mobil'])) {
                throw new ApiException('Jenis kendaraan tidak valid.');
            }
        }

        $check = Validator::make($request->all(), [
            'image' => ['nullable', 'file', 'mimes:png,jpg,jpeg,webp', 'max:2048'],
        ], [
            'image.file' => 'Foto gagal diunggah.',
            'image.uploaded' => 'Foto gagal diunggah (ukuran melebihi batas server).',
            'image.mimes' => 'Foto harus berformat PNG, JPG, atau WEBP.',
            'image.max' => 'Ukuran foto maksimal 2 MB.',
        ]);
        if ($check->fails()) {
            throw new ApiException($check->errors()->first());
        }

        return [
            'name' => $name,
            'description' => $description,
            'details' => $details,
            'price' => (int) $price,
            'category' => $category,
            'stock' => (int) $stock,
            'vehicles' => $vehicles,
        ];
    }

    /** ID berikutnya untuk kategori itu: mk17, mn11, ol11, ... */
    private function nextId(string $category): string
    {
        $prefix = self::PREFIX[$category];
        $max = Product::where('id', 'like', $prefix.'%')->lockForUpdate()->pluck('id')
            ->map(fn (string $id) => (int) substr($id, strlen($prefix)))
            ->max() ?? 0;

        return $prefix.($max + 1);
    }
}
