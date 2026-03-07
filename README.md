<div align="center">

# K4TSS V2.0 — Waypoint Hub

![Version](https://img.shields.io/badge/version-2.0-red?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Roblox-blue?style=for-the-badge)
![Language](https://img.shields.io/badge/language-Lua-yellow?style=for-the-badge)
![Device](https://img.shields.io/badge/device-PC%20%7C%20Mobile-green?style=for-the-badge)

Script executor Roblox multi-fitur dengan UI modern — mendukung PC dan HP.

</div>

---

## 📥 Load Script

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/katssV7/K4TSS-Hub-new/refs/heads/main/K4TSS-HUB.lua"))()
```

> Tekan **G** untuk toggle GUI setelah script dijalankan.

---

## ✨ Fitur

| Tab | Fitur |
|-----|-------|
| 🗂 Waypoints | Simpan & teleport ke titik koordinat, folder, loop TP otomatis |
| 👤 Players | Teleport ke player lain, support StreamingEnabled |
| ⚡ Speed | Custom WalkSpeed + toggle ON/OFF, Infinite Jump, Fly |
| ⚙ Settings | Manual save, clear data |

---

## 🗂 Tab Waypoints

Sistem penyimpanan titik teleport berbasis folder.

- **Buat Folder** — ketik nama lalu tekan `+ Folder`
- **Simpan Waypoint** — tekan `+ WP` untuk menyimpan posisi saat ini
- **Teleport** — tekan `TP` di samping nama waypoint
- **Urutkan** — gunakan tombol `▲` / `▼` untuk mengubah urutan
- **Loop TP** — teleport otomatis berurutan ke semua waypoint dalam folder
  - Atur delay antar teleport (0.5 – 60 detik)
  - Tekan `▶ Start` untuk mulai, `■ Stop` untuk berhenti

### Auto-Save
Waypoint disimpan otomatis setiap **30 detik** ke file `K4TSS_Waypoints.json`.

| Executor | Status |
|----------|--------|
| Synapse X, KRNL, Script-Ware | ✅ File save |
| Executor tanpa writefile/readfile | ⚠️ In-memory (hilang setelah close) |

---

## 👤 Tab Players

Teleport ke player lain di server yang sama.

- Tekan **🔍 Scan** untuk memuat daftar player
- Setiap player menampilkan **jarak dalam studs** (hijau < 100, kuning < 500, merah = jauh)
- Tekan **TP →** untuk teleport ke samping player tersebut

### StreamingEnabled
Beberapa game menggunakan StreamingEnabled sehingga karakter player jauh tidak di-load. Script menangani ini dengan **step-TP** — bergerak bertahap menuju player hingga karakternya muncul, lalu teleport langsung.

---

## ⚡ Tab Speed

### WalkSpeed
- Slider **1 – 200** untuk mengatur kecepatan jalan
- Input manual dan tombol `Set` / `Reset`
- **Toggle ON/OFF** — matikan custom speed untuk kembali ke kecepatan default (16)
- Speed dipertahankan saat respawn

### Infinite Jump
- Toggle untuk mengaktifkan lompat berkali-kali di udara
- Hanya aktif saat **tap** tombol jump (bukan tahan) — jump pertama dari tanah tetap normal
- Kompatibel PC (Space) dan HP (tombol Jump)

### 🕊 Fly
Toggle terbang bebas dengan kontrol kamera penuh.

**PC:**
| Tombol | Aksi |
|--------|------|
| `W` | Terbang ke arah pandang kamera |
| `S` | Mundur |
| `A` / `D` | Kiri / Kanan |
| `Space` | Naik |
| `Left Shift` | Turun |

**HP / Mobile:**
| Input | Aksi |
|-------|------|
| Joystick kiri | Terbang mengikuti arah kamera (termasuk naik saat kamera diarahkan ke atas) |
| Tombol Jump | Naik lurus |

> Fly speed bisa diatur via input box di samping tombol (default: 50).
> Fly otomatis berhenti saat respawn/mati atau saat GUI ditutup.

### Preset Speed
| Preset | WalkSpeed |
|--------|-----------|
| Normal | 16 |
| Fast | 50 |
| Super | 100 |
| MAX | 500 |

---

## ⚙ Tab Settings

- **Manual Save** — simpan data waypoint sekarang
- **Clear All Data** — hapus semua folder dan waypoint

---

## 🖥 UI

```
┌─────────────────────────────────────────────────────┐
│  K4TSS V2.0 · Waypoint Hub                  – ×    │
├──────────┬──────────────────────────────────────────┤
│          │                                          │
│Waypoints │         [Konten Tab Aktif]               │
│          │                                          │
│ Players  │                                          │
│          │                                          │
│  Speed   │                                          │
│          │                                          │
│ Settings │                                          │
│          │                                          │
└──────────┴──────────────────────────────────────────┘
```

- **Drag** — tahan titlebar untuk memindahkan window (PC & HP)
- **Minimize** — tekan `–` untuk memperkecil jadi bar kecil
- **Close** — tekan `×`, akan muncul konfirmasi save sebelum tutup
- **Hotkey** — tekan `G` untuk show/hide GUI

---

## 📋 Requirement

- Executor yang mendukung **LocalScript** / **getgenv** (Synapse X, KRNL, Fluxus, dll)
- Roblox versi terbaru
- Koneksi internet untuk loadstring via GitHub

---

## ⚠️ Disclaimer

Script ini dibuat untuk keperluan pribadi dan edukasi. Penggunaan di server publik dapat melanggar **Terms of Service Roblox**. Gunakan dengan bijak dan tanggung jawab sendiri.

---

## 📝 Changelog

### v2.0
- UI baru dengan sidebar tab
- Sistem folder waypoint
- Loop teleport dengan delay yang bisa diatur
- Tab Player Teleport dengan step-TP untuk StreamingEnabled
- WalkSpeed slider + toggle ON/OFF
- Infinite Jump (tap-based, bukan hold)
- Fly dengan kontrol kamera penuh (PC + Mobile analog)
- Auto-save ke file JSON setiap 30 detik
- Drag window support PC & Mobile
- Hotkey G untuk toggle GUI
