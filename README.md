# 🍺 Oktoberfest Simulator

2-4 arkadaşın kaotik bir Oktoberfest çadırında bira/yemek servis ederken didiştiği,
Overcooked/PlateUp! ruhunda co-op bir kaos oyunu.

## Teknik

| | |
|---|---|
| Motor | Godot 4.7.x |
| Dil | GDScript |
| Renderer | Forward+ |
| Fizik | Jolt Physics (3D) |
| Multiplayer | Host-as-server (ENetMultiplayerPeer, high-level API) |

## Klasör yapısı

```
scenes/    — .tscn sahneleri (main.tscn = giriş)
scripts/   — GDScript dosyaları
autoload/  — singleton'lar (net.gd, game.gd)
assets/    — models / textures / audio / ui (binary'ler Git LFS'te)
addons/    — Godot eklentileri
```

## Kurulum

1. Godot 4.7.x aç → `project.godot` dosyasını import et.
2. Repo Git LFS kullanıyor: `git lfs install` bir kez çalıştırılmalı.

## Yol haritası

Faz 0 konsept → Faz 1 kurulum (✅) → Faz 2 tek oyunculu çekirdek →
Faz 3 multiplayer → Faz 4 bira çadırı mekanikleri → Faz 5 kaos/mizah →
Faz 6 sanat/ses → Faz 7 UI → Faz 8 test → Faz 9 yayın.
