# Diagram CleanDrive

Diagram memakai Mermaid. GitHub, VS Code (ekstensi *Markdown Preview Mermaid Support*), dan https://mermaid.live
dapat menampilkannya. Untuk laporan, ekspor sebagai gambar dari mermaid.live.

## 1. Arsitektur

```mermaid
flowchart LR
    subgraph Klien
      A[Aplikasi Flutter<br/>Pelanggan]
      B[Panel Admin<br/>Flutter]
    end
    A -- HTTP JSON + Bearer token --> C
    B -- HTTP JSON + Bearer token --> C
    subgraph Server
      C[Laravel API<br/>54+ rute, Sanctum]
      C --> D[Services<br/>Booking, Payment, Coin,<br/>Membership, Voucher, Queue]
    end
    D --> E[(MySQL cleandrive)]
    E -. foto produk MEDIUMBLOB .-> C
```

Semua perhitungan (harga, diskon, kapasitas slot, stok, Coins) dilakukan di server. Flutter hanya menampilkan.
Mode demo tanpa server: `--dart-define=USE_MOCK=true` (data tiruan di memori).

## 2. Relasi antartabel (ERD)

```mermaid
erDiagram
    users ||--o{ vehicles : punya
    users ||--o{ bookings : membuat
    users ||--o{ payments : membayar
    users ||--o{ reviews : menulis
    users ||--o{ coin_entries : "riwayat Coins"
    users ||--o{ coin_promo_claims : klaim
    users ||--o{ voucher_claims : klaim
    users ||--o| memberships : "satu aktif"
    users ||--o{ membership_orders : memesan
    users ||--o{ membership_transactions : riwayat
    users ||--o{ app_notifications : menerima
    bookings ||--o{ booking_items : berisi
    products ||--o{ booking_items : dipesan
    products ||--o{ product_images : foto
    bookings ||--o{ payments : dibayar
    bookings ||--o| reviews : diulas
    bookings ||--o{ coin_entries : "terkait"
    vouchers ||--o{ voucher_claims : diklaim
    voucher_claims }o--o| bookings : "dipakai di"
    membership_plans ||..o{ memberships : "tier"
    wash_packages ||..o{ bookings : "nama paket"

    users { bigint id PK
            string email
            string role "customer | admin" }
    bookings { bigint id PK
               string code
               string package
               datetime slot
               int price
               tinyint status "0 tunggu, 1 proses, 2 finishing, 3 selesai"
               string pay_status }
    payments { bigint id PK
               string trx
               string method
               int amount
               string status "pending | paid | expired" }
    products { string id PK
               string name
               int price
               int stock }
    settings { string key PK
               json value }
```

Catatan: `membership_plans.tier` dan `wash_packages.name` dihubungkan lewat nilai (bukan foreign key).
Tabel `settings` menyimpan pengaturan reward Coins buatan admin.

## 3. Alur pemesanan dan pembayaran

```mermaid
sequenceDiagram
    actor P as Pelanggan
    participant F as Flutter
    participant S as Laravel API
    participant D as MySQL
    P->>F: pilih paket, slot, voucher
    F->>S: POST /bookings
    S->>D: cek slot (maks 3 per jam), hitung total
    S-->>F: pesanan (belum dibayar)
    P->>F: pilih metode, tukar Coins
    F->>S: POST /payments
    S-->>F: QR / e-wallet (kedaluwarsa 10 menit)
    F->>S: POST /payments/{id}/simulate-qris atau /confirm
    S->>D: tandai lunas, kurangi stok, potong dan beri Coins
    S-->>F: pembayaran berhasil + tiket QR
    actor A as Admin
    A->>S: POST /admin/verify lalu /admin/bookings/{id}/advance
    S-->>F: status antrean berubah (Flutter memuat ulang berkala)
```
