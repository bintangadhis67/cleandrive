@echo off
rem Membuat token uji untuk akun Budi (variabel TOKEN) dan akun admin (variabel ADMIN).
rem Jalankan di Terminal Laragon:  call C:\cleandrive\tools\tokens.cmd
rem Variabel hanya hidup di jendela terminal tempat skrip ini dijalankan.
set "TOKEN="
set "ADMIN="
pushd "%~dp0..\backend"
for /f "usebackq delims=" %%a in (`php artisan tinker --execute="echo App\Models\User::where('email','budi@mail.com')->first()->createToken('uji')->plainTextToken;"`) do set "TOKEN=%%a"
for /f "usebackq delims=" %%a in (`php artisan tinker --execute="echo App\Models\User::where('email','admin@cleandrive.com')->first()->createToken('uji')->plainTextToken;"`) do set "ADMIN=%%a"
popd
if not defined TOKEN goto gagal
if not defined ADMIN goto gagal
echo Selesai. TOKEN untuk Budi dan ADMIN untuk admin sudah terisi di jendela ini.
echo Cek dengan perintah: set TOKEN
goto :eof
:gagal
echo GAGAL membuat token. Pastikan MySQL di Laragon hidup lalu coba lagi.
