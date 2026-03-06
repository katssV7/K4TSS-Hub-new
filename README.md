# K4TSS V2.0 — Waypoint Hub

<div align="center">

![Version](https://img.shields.io/badge/Version-2.0-red?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Roblox-blue?style=for-the-badge)
![Language](https://img.shields.io/badge/Language-Lua-purple?style=for-the-badge)
![License](https://img.shields.io/badge/License-Free-green?style=for-the-badge)

**Script teleport waypoint berbasis folder untuk Roblox, dengan fitur Loop TP dan Auto-Save.**

</div>

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 📁 **Folder System** | Kelompokkan waypoint ke dalam folder terpisah |
| 📍 **Waypoint Manager** | Tambah, urutkan, hapus, dan teleport ke waypoint |
| 🔁 **Loop Teleport** | Auto-teleport berurutan antar waypoint dengan delay kustom |
| 👤 **Player Teleport** | Scan, pilih, dan teleport langsung ke posisi player lain |
| 💾 **Auto-Save** | Data tersimpan otomatis via `writefile` (file lokal executor) |
| 🖥️ **Mobile & PC** | Drag GUI support untuk Touch (HP) dan Mouse (PC) |
| ⌨️ **Hotkey** | Tekan `G` untuk toggle GUI kapan saja |

---

## 📋 Cara Pakai

1. **Execute** script di executor kamu (Synapse X, KRNL, dll)
2. **Buat Folder** — ketik nama folder, klik `+ Folder`
3. **Pilih Folder** — klik baris folder untuk memilihnya
4. **Tambah Waypoint** — jalan ke lokasi, ketik nama, klik `+ WP`
5. **Teleport** — klik tombol `TP` di sebelah waypoint
6. **Loop TP** — klik `▶ Start` untuk mulai loop otomatis, `■ Stop` untuk berhenti
7. **Toggle GUI** — tekan `G` kapan saja untuk sembunyikan / tampilkan

---

## 👤 Player Teleport

Fitur untuk scan dan teleport langsung ke posisi player lain di server yang sama.

### Cara Pakai
1. Buka tab **Players** di GUI
2. Klik **🔍 Scan** untuk memuat daftar player yang sedang online
3. Klik nama player yang ingin dituju
4. Klik **TP ke Player** untuk teleport ke posisinya

### UI Player Teleport
```
╔══════════════════════════════════════════════╗
║  👤 Player Teleport                          ║
║  ┌────────────────────────────────────────┐  ║
║  │ 🟢 PlayerOne          [TP ke Player]   │  ║
║  │ 🟢 PlayerTwo          [TP ke Player]   │  ║
║  │ 🟢 PlayerThree        [TP ke Player]   │  ║
║  └────────────────────────────────────────┘  ║
║  [🔍 Scan Player]   Ditemukan: 3 player      ║
╚══════════════════════════════════════════════╝
```

### Catatan
> - Kamu **tidak akan muncul** di daftar (hanya player lain)
> - Klik **🔍 Scan** ulang untuk refresh daftar jika ada player masuk/keluar
> - Teleport akan menempatkan karakter **tepat di atas** posisi player target
> - Jika player target **tidak memiliki karakter** (sedang respawn), tombol TP akan dinonaktifkan

---

## 💾 Sistem Auto-Save

Script ini menggunakan **Executor File API** untuk menyimpan data secara permanen:

```
File tersimpan di: workspace/K4TSS_Waypoints.json
```

| Kondisi | Perilaku |
|---|---|
| Executor support `writefile` | Data disimpan ke file lokal (permanen) |
| Executor tidak support `writefile` | Data tersimpan in-memory (hilang saat close) |

- Auto-save berjalan **setiap 30 detik**
- Manual save tersedia di tab **Settings**

---

## 🖼️ UI Overview

```
╔══════════════════════════════════════════════╗
║         K4TSS V2.0 - WAYPOINT HUB           ║
╠══════════════╦═══════════════════════════════╣
║  [Waypoints] ║  📁 Folders                  ║
║  [Players]   ║  ┌──────────────────────┐    ║
║  [Settings]  ║  │ 1 📁 MOUNT    3 WP 🔁│    ║
║              ║  │ 2 📁 FARM     5 WP   │    ║
║              ║  └──────────────────────┘    ║
║              ║  📍 Waypoints (MOUNT)        ║
║              ║  ┌──────────────────────┐    ║
║              ║  │ 1 📍 Gate   [TP][✕]  │    ║
║              ║  │ 2 📍 Summit [TP][✕]  │    ║
║              ║  └──────────────────────┘    ║
║              ║  🔁 Loop TP  [▶ Start][■ Stop]║
╠══════════════╩═══════════════════════════════╣
║  👤 Welcome, Player          💾 Auto-save   ║
╚══════════════════════════════════════════════╝
```

---

## ⚙️ Konfigurasi

Kamu bisa mengubah beberapa nilai di bagian atas script:

```lua
local SAVE_FILE = "K4TSS_Waypoints.json"  -- Nama file save
-- Default loop delay: 3 detik (bisa diubah dari UI)
-- Hotkey: G (bisa diubah di bagian HOTKEY)
```

---

## 🔧 Persyaratan

- Roblox executor yang mendukung `LocalScript` injection
- Untuk auto-save permanen: executor yang mendukung `writefile` / `readfile`
  - ✅ Synapse X
  - ✅ KRNL
  - ✅ Fluxus
  - ⚠️ Executor lain: data tersimpan sesi saja

---

## 📦 Struktur Data (JSON)

Data waypoint disimpan dalam format berikut:

```json
[
  {
    "name": "MOUNT",
    "loopActive": false,
    "loopDelay": 3,
    "waypoints": [
      { "name": "Gate",   "x": 120, "y": 10, "z": -340 },
      { "name": "Summit", "x": 80,  "y": 95, "z": -290 }
    ]
  }
]
```

---

## 🚀 Load Script

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/katssV7/K4TSS-Hub/refs/heads/main/K4TSS-HUB"))()
```

---

## ⚠️ Disclaimer

> Script ini dibuat untuk keperluan **edukasi dan eksplorasi pribadi**.
> Penggunaan script di server publik dapat melanggar **Terms of Service Roblox**.
> Gunakan dengan bijak dan tanggung jawab sendiri.

---

## 📝 Changelog

### v2.0
- Sistem folder untuk organisasi waypoint
- Loop Teleport dengan delay yang dapat dikustomisasi
- **Player Teleport** — scan, pilih, dan TP ke player lain
- Auto-save via executor file API (`writefile`/`readfile`)
- Support drag GUI untuk mobile (Touch) dan desktop (Mouse)
- Tombol reorder waypoint (▲ / ▼)
- Status bar dengan avatar pemain
- Tab Settings dengan manual save & clear data
- Close dialog dengan konfirmasi simpan

---

<div align="center">

Made with ❤️ by **K4TSS**

</div>
