<div align="center">

# 🎮 K4TSS HUB V2.0

### Waypoint Hub Script untuk Roblox
*Fly · Teleport · Speed · World Modifier · Player TP*

[![Lua](https://img.shields.io/badge/Language-Lua-blue?style=flat-square&logo=lua)](https://lua.org)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-red?style=flat-square)](https://roblox.com)
[![Executor](https://img.shields.io/badge/Executor-Universal-green?style=flat-square)]()
[![Version](https://img.shields.io/badge/Version-2.0-orange?style=flat-square)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

</div>

---

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Screenshot](#-screenshot)
- [Cara Pakai](#-cara-pakai)
- [Hotkey](#️-hotkey)
- [Tab & Fitur Detail](#-tab--fitur-detail)
- [Executor yang Didukung](#-executor-yang-didukung)
- [Changelog](#-changelog)
- [Disclaimer](#%EF%B8%8F-disclaimer)

---

## ✨ Fitur

| Fitur | Deskripsi |
|-------|-----------|
| 🗂️ **Waypoint Manager** | Buat folder & simpan waypoint dengan nama, loop TP otomatis |
| ✈️ **Fly Script** | Terbang bebas dengan speed adjustable, kontrol WASD + Space/Shift |
| ⚡ **Speed & Jump** | WalkSpeed slider, Infinite Jump, preset speed (Normal/Fast/Super/MAX) |
| 👤 **Player Teleport** | Scan & TP ke player lain, anti-streaming step TP |
| 🌍 **World Modifier** | Ganti Time of Day, Brightness, Fog secara real-time |
| 💾 **Auto-Save** | Data waypoint tersimpan otomatis ke file lokal (tiap 30 detik) |
| 🖱️ **Draggable GUI** | Window bisa dipindah, minimize, dan toggle dengan hotkey |

---

## 📸 Screenshot

> *Tambahkan screenshot GUI di sini*

---

## 🚀 Cara Pakai

### 1. Copy script
Download file `K4TSS-HUB.lua` dari repository ini.

### 2. Execute via Executor
Buka executor kamu (Synapse X, KRNL, Fluxus, dll), paste isi script, lalu execute.

```lua
-- Atau bisa loadstring langsung (jika sudah dihost):
loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/K4TSS-HUB.lua"))()
```

### 3. GUI akan muncul otomatis
Setelah execute, GUI K4TSS Hub langsung muncul di tengah layar. Tekan **G** untuk toggle tampil/sembunyikan.

---

## ⌨️ Hotkey

| Tombol | Fungsi |
|--------|--------|
| `G` | Toggle GUI (tampil / sembunyikan) |
| `W A S D` | Gerak saat Fly aktif |
| `Space` | Naik saat Fly aktif |
| `Left Shift` | Turun saat Fly aktif |

---

## 📂 Tab & Fitur Detail

### 🗂️ Tab Waypoints
- Buat **folder** untuk mengelompokkan waypoint
- Tambah waypoint dengan **posisi karakter saat ini** secara otomatis
- **Loop TP** — karakter otomatis berpindah antar waypoint dengan delay yang bisa diatur
- Urutkan waypoint (naik/turun), hapus satuan atau seluruh folder
- Data tersimpan ke file `K4TSS_Waypoints.json` secara lokal

### 👤 Tab Players
- **Scan** daftar player di server saat ini
- Klik **TP →** untuk teleport ke player pilihan
- Dilengkapi **Step TP** (anti-streaming) — mendekati player secara bertahap jika karakter tidak ter-load karena streaming distance

### ⚡ Tab Speed
- **WalkSpeed slider** (1–200), input manual, tombol Set & Reset
- **Preset** cepat: Normal (16) · Fast (50) · Super (100) · MAX (500)
- **Infinite Jump** — lompat berkali-kali di udara
- **Fly Toggle** — terbang bebas, fly speed bisa diatur langsung di input
  - Menggunakan `LinearVelocity` (API baru) dengan fallback otomatis ke `BodyVelocity` (API lama)

### 🌍 Tab World
- **Time of Day** slider (jam 0–24) dengan format jam digital
- **Brightness** slider (0–10)
- **Fog** slider (50–100,000)
- Tombol **Reset Lighting** ke nilai default

### ⚙️ Tab Settings
- **Manual Save** data waypoint
- **Hapus semua** data waypoint
- Info save mode (file lokal / in-memory)

---

## 🖥️ Executor yang Didukung

Script ini dibuat **universal** dan kompatibel dengan semua executor populer:

- ✅ Synapse X
- ✅ KRNL
- ✅ Fluxus
- ✅ Arceus X
- ✅ Delta
- ✅ Executor lain yang mendukung `LocalScript` environment

> **Catatan:** Fitur Auto-Save ke file (`writefile`) hanya tersedia di executor yang mendukung filesystem API. Jika tidak tersedia, data tetap tersimpan **in-memory** selama sesi berlangsung.

---

## 📦 Struktur File

```
K4TSS-HUB/
├── K4TSS-HUB.lua        # Script utama
├── README.md             # Dokumentasi ini
└── LICENSE               # Lisensi
```

---

## 📝 Changelog

### v2.0 (Latest)
- ✅ Fix: `BodyVelocity` & `BodyGyro` deprecated → diganti `LinearVelocity` + `AlignOrientation` dengan auto-fallback
- ✅ Fix: GUI tidak muncul karena `LocalPlayer.Character` nil saat execute
- ✅ Fix: `ScreenGui` gagal parent ke `PlayerGui` di beberapa game → fallback ke `CoreGui`
- ✅ Fix: `MakeSmallBtn` parameter `AnchorPoint` tidak konsisten
- ✅ Tambah: Tab World Modifier (Time, Brightness, Fog)
- ✅ Tambah: Infinite Jump dengan reconnect otomatis saat respawn
- ✅ Tambah: Player Teleport dengan Step TP anti-streaming
- ✅ Tambah: Auto-save tiap 30 detik + manual save

### v1.0
- 🎉 Rilis pertama: Waypoint Manager + basic Fly + Speed

---

## ⚠️ Disclaimer

> Script ini dibuat **untuk tujuan edukasi dan penggunaan pribadi**.
>
> - Penggunaan script exploit di Roblox melanggar [Roblox Terms of Service](https://en.help.roblox.com/hc/en-us/articles/115004647846).
> - Developer tidak bertanggung jawab atas akun yang terkena banned atau konsekuensi lainnya.
> - Gunakan dengan risiko sendiri.

---

<div align="center">

Made with ❤️ by **K4TSS**

⭐ Jangan lupa kasih star kalau script ini berguna!

</div>
