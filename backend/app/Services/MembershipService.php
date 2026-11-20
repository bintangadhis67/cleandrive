<?php

namespace App\Services;

use App\Models\Membership;
use App\Models\MembershipPlan;
use App\Models\User;
use App\Models\WashPackage;
use Carbon\CarbonInterface;

class MembershipService
{
    /** Membership yang masih aktif (status active dan belum lewat masa berlaku), atau null. */
    public static function active(User|int $user, bool $lock = false): ?Membership
    {
        $id = $user instanceof User ? $user->id : $user;
        $q = Membership::where('user_id', $id);
        if ($lock) {
            $q->lockForUpdate();
        }
        $m = $q->first();

        return $m && $m->isActive() ? $m : null;
    }

    public static function plan(string $tier): ?MembershipPlan
    {
        return MembershipPlan::where('tier', $tier)->first();
    }

    /** 0 = tidak ada membership aktif, 1 Bronze ... 4 Platinum. */
    public static function rank(User|int $user): int
    {
        $m = self::active($user);

        return $m ? MembershipPlan::rankOf($m->tier) : 0;
    }

    public static function label(string $tier): string
    {
        return ucfirst($tier);
    }

    /** Kunci minggu = tanggal Senin, mis. 20261116 (sama dengan weekKey di Flutter). */
    public static function weekKey(CarbonInterface $d): string
    {
        return $d->copy()->startOfWeek()->format('Ymd');
    }

    /** Benefit kunjungan: makanan dan minuman gratis, ruang tunggu VIP, kursi pijat. */
    public static function visitPerks(MembershipPlan $p): array
    {
        return array_values(array_filter([
            $p->snack ? 'Makanan & minuman gratis' : null,
            $p->vip ? 'Ruang tunggu VIP (TV & AC)' : null,
            $p->massage ? 'Kursi pijat saat menunggu' : null,
        ]));
    }

    /** "Motor & Mobil", "Motor", atau "Mobil". */
    public static function freeVehiclesLabel(MembershipPlan $p): string
    {
        return implode(' & ', array_map('ucfirst', $p->free_vehicles ?? []));
    }

    /**
     * Alasan cuci gratis TIDAK bisa dipakai (null = boleh). Aturan sama dengan UserMembership.freeWashBlock di Flutter:
     * paket dan kendaraan sesuai, jadwal dalam masa aktif, kuota masih ada, maksimal 1x per minggu.
     */
    public static function freeWashBlock(Membership $m, WashPackage $pack, string $vehicle, CarbonInterface $slot): ?string
    {
        $p = self::plan($m->tier);
        $name = self::label($m->tier);

        if (! $m->isActive() || ! $p) {
            return 'Membership tidak aktif.';
        }
        if ($p->free_wash_quota <= 0 || $p->free_package === '') {
            return "Paket {$name} tidak mendapat cuci gratis.";
        }
        if ($pack->kind !== 'wash' || $pack->name !== $p->free_package) {
            return "Cuci gratis {$name} hanya untuk paket {$p->free_package} Wash.";
        }
        if (! in_array($vehicle, $p->free_vehicles ?? [], true)) {
            return "Cuci gratis {$name} hanya untuk ".self::freeVehiclesLabel($p).'.';
        }
        if ($m->end_date && $slot->gt($m->end_date)) {
            return 'Jadwal ini melewati masa aktif membership (berakhir '.$m->end_date->format('j/n/Y').').';
        }
        if ($m->free_total - $m->free_used <= 0) {
            return 'Kuota cuci gratis membership sudah habis.';
        }
        if (in_array(self::weekKey($slot), $m->free_weeks ?? [], true)) {
            return 'Cuci gratis di minggu itu sudah terpakai (maksimal 1x per minggu). Pilih tanggal di minggu lain.';
        }

        return null;
    }
}
