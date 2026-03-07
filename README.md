<div align="center">

# 🎮 K4TSS HUB V2.0

### Waypoint Hub Script untuk Roblox
*Fly · Teleport · Speed · Player TP*

[![Lua](https://img.shields.io/badge/Language-Lua-blue?style=flat-square&logo=lua)](https://lua.org)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-red?style=flat-square)](https://roblox.com)
[![Executor](https://img.shields.io/badge/Executor-Universal-green?style=flat-square)]()
[![Version](https://img.shields.io/badge/Version-2.0-orange?style=flat-square)]()

</div>

---

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Cara Pakai](#-cara-pakai)
- [Hotkey](#️-hotkey)
- [Tab & Fitur Detail](#-tab--fitur-detail)
- [Executor yang Didukung](#-executor-yang-didukung)
- [Changelog](#-changelog)
- [Disclaimer](#️-disclaimer)

---

## ✨ Fitur

| Fitur | Deskripsi |
|-------|-----------|
| 🗂️ **Waypoint Manager** | Buat folder & simpan waypoint, loop TP otomatis antar waypoint |
| ✈️ **Fly Script** | Terbang bebas dengan speed adjustable, kontrol WASD + Space/Shift |
| ⚡ **Speed & Jump** | WalkSpeed slider, Infinite Jump, preset speed instan |
| 👤 **Player Teleport** | Scan & TP ke player lain dengan anti-streaming step TP |
| 💾 **Auto-Save** | Waypoint tersimpan otomatis ke file lokal tiap 30 detik |
| 🖱️ **Draggable GUI** | Window bisa dipindah, minimize, dan toggle dengan hotkey **G** |

---

## 🚀 Cara Pakai

**1.** Download file `K4TSS-HUB.lua` dari repository ini

**2.** Buka game Roblox, lalu buka executor kamu

**3.** Paste **seluruh isi** file ke executor — jangan pakai loadstring

**4.** Execute → GUI langsung muncul di tengah layar

> ⚠️ **Jangan pakai loadstring** karena beberapa game memblokir `HttpGet`. Paste langsung isi scriptnya.

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

### 🗂️ Waypoints
- Buat **folder** untuk mengelompokkan waypoint
- Tambah waypoint dengan **posisi karakter saat ini** secara otomatis
- **Loop TP** — berpindah otomatis antar waypoint dengan delay yang bisa diatur
- Urutkan (naik/turun), hapus satuan atau seluruh folder
- Data disimpan ke `K4TSS_Waypoints.json` secara lokal

### 👤 Players
- **Scan** daftar player yang ada di server
- Klik **TP →** untuk teleport ke player pilihan
- **Step TP** otomatis untuk mengatasi streaming distance

### ⚡ Speed
- **WalkSpeed slider** (1–200) + input manual + tombol Set & Reset
- **Preset instan**: Normal (16) · Fast (50) · Super (100) · MAX (500)
- **Infinite Jump** — lompat berkali-kali di udara, reconnect otomatis saat respawn
- **Fly Toggle** — terbang bebas dengan speed yang bisa diatur
  - Pakai `LinearVelocity` (API baru) dengan fallback otomatis ke `BodyVelocity`

### ⚙️ Settings
- **Manual Save** waypoint kapan saja
- **Hapus semua** data waypoint
- Info mode save (file lokal / in-memory)

---

## 🖥️ Executor yang Didukung

| Executor | Status |
|----------|--------|
| Synapse X | ✅ |
| KRNL | ✅ |
| Fluxus | ✅ |
| Delta | ✅ |
| Arceus X | ✅ |
| Executor lainnya | ✅ Universal |

> **Catatan:** Fitur Auto-Save ke file hanya tersedia di executor yang mendukung `writefile`. Jika tidak, data tetap tersimpan in-memory selama sesi.

---

## 📦 Struktur File

```
K4TSS-HUB/
├── K4TSS-HUB.lua    # Script utama
└── README.md        # Dokumentasi ini
```

---

## 📝 Changelog

### v2.0 (Latest)
- ✅ Fix: GUI tidak muncul karena `LocalPlayer.Character` nil saat execute
- ✅ Fix: `ScreenGui` fallback otomatis ke `CoreGui` jika `PlayerGui` diblokir
- ✅ Fix: `BodyVelocity` & `BodyGyro` deprecated → diganti `LinearVelocity` + `AlignOrientation`
- ✅ Fix: Hapus World Tab (Lighting) yang menyebabkan error di beberapa game
- ✅ Tambah: Infinite Jump dengan reconnect otomatis saat respawn
- ✅ Tambah: Player Teleport dengan Step TP anti-streaming
- ✅ Tambah: Auto-save tiap 30 detik + manual save

### v1.0
- 🎉 Rilis pertama: Waypoint Manager + Fly + Speed

---

## ⚠️ Disclaimer

> Script ini dibuat untuk **tujuan edukasi dan penggunaan pribadi**.
> Penggunaan script exploit melanggar [Roblox Terms of Service](https://en.help.roblox.com/hc/en-us/articles/115004647846).
> Developer tidak bertanggung jawab atas akun yang terkena banned.
> **Gunakan dengan risiko sendiri.**

---

<div align="center">

Made with ❤️ by **K4TSS**

⭐ Star repo ini kalau script-nya berguna!

</div>
