#!/usr/bin/env bash
# Erzeugt scenes/deko.tscn — echte Knoten, im Editor frei verschiebbar.
set -e
OUT=/c/Users/vase/Projekte/Oktoberfest2/scenes/deko.tscn
NODES=$(mktemp)
EXTS=$(mktemp)

declare -A SEEN
res() {  # res <id> <pfad>
  if [ -z "${SEEN[$1]}" ]; then
    SEEN[$1]=1
    echo "[ext_resource type=\"PackedScene\" path=\"$2\" id=\"$1\"]" >> "$EXTS"
  fi
}
F() { res "$1" "res://assets/kirmes/Models/Foliage/$2.fbx"; }
P() { res "$1" "res://assets/kirmes/Models/Props/$2.fbx"; }
S() { res "$1" "res://assets/kirmes/Models/Shops/$2.fbx"; }
R() { res "$1" "res://scenes/props/$2.tscn"; }

CNT=0
grp() { echo "" >> "$NODES"; echo "[node name=\"$1\" type=\"Node3D\" parent=\".\"]" >> "$NODES"; GRP=$1; }
# n <resid> <x> <z> <grad> [skalierung] [y]
n() {
  CNT=$((CNT+1))
  local id=$1 x=$2 z=$3 d=${4:-0} s=${5:-1} y=${6:-0}
  read c sn nsn <<< $(awk -v d="$d" -v s="$s" 'BEGIN{r=d*3.14159265/180; printf "%.5f %.5f %.5f", s*cos(r), s*sin(r), -s*sin(r)}')
  echo "" >> "$NODES"
  echo "[node name=\"${id}_$CNT\" parent=\"$GRP\" instance=ExtResource(\"$id\")]" >> "$NODES"
  echo "transform = Transform3D($c, 0, $nsn, 0, $s, 0, $sn, 0, $c, $x, $y, $z)" >> "$NODES"
}

# ---------- Ressourcen ----------
F t1 Tree_1; F t2 Tree_2; F t3 Tree_3; F t4 Tree_4
F ct1 C.Tree_1; F ct2 C.Tree_2; F tap Tree_Apple; F tpe Tree_Pear
F bu Bush; F bub Bush_Berry
F stl Stone_L; F stm Stone_M; F sts Stone_S
F gbl GardenBed_L; F gbm GardenBed_M; F gbs GardenBed_S
F pop Poppies; F popa Poppies_A; F popb Poppies_B
F gra Grass_2; F ree Reeds
P ben Bench; P pic PicnicTable; P picp Picnic_Place
P cch CafeChair; P cta CafeTable; P cum CafeUmberella; P cme CafeMenu
P tca TrashCan; P tbi TrashBin; P tba TrashBag
P qbc QueueBarrier_Closed; P qbo QueueBarrier_Open
P fou Fountain; P pfa Park_Fence_A; P fwo Fence_Wood; P hyd FireHydrant
S ice IceCream_Shop; S pcn PopCorn_Shop; S sod Soda_Shop; S hot HotDogs_Shop
S gif Gift_Shop; S bak Bld_Bakery; S gaz Gazebo
S tba1 Ticket_Box_A; S tbb Ticket_Box_B
R rak raketen; R wav wave; R tur turm

# =================== GRUEN: Baumreihen an den Mauern ===================
grp Gruen
TR=(t1 t2 t3 ct1 ct2 t4 tap tpe)
i=0
for x in -32 -27 -22 -17 -12 -7 -2 3 8 13 18 23 28 32; do
  n ${TR[$((i%8))]} $x 29.6 $(( (i*47) % 360 )) $(awk -v i=$i 'BEGIN{printf "%.2f", 0.9+0.5*((i*7)%5)/5}')
  i=$((i+1))
done
for z in -14 -9 -4 1 6 11; do
  n ${TR[$((i%8))]} 32.6 $z $(( (i*61) % 360 )) $(awk -v i=$i 'BEGIN{printf "%.2f", 0.9+0.5*((i*3)%5)/5}')
  i=$((i+1))
  n ${TR[$(((i+3)%8))]} -32.6 $z $(( (i*29) % 360 )) $(awk -v i=$i 'BEGIN{printf "%.2f", 0.9+0.5*((i*5)%5)/5}')
  i=$((i+1))
done
# Buesche und Steine dazwischen
for x in -30 -25 -20 -15 -10 -5 0 5 10 15 20 25 30; do
  n $([ $((i%2)) -eq 0 ] && echo bu || echo bub) $x 31.4 $(( (i*83) % 360 ))
  i=$((i+1))
done
for z in -16 -11 -6 -1 4 9; do
  n bu 34.2 $z $(( (i*37) % 360 )); i=$((i+1))
  n bub -34.2 $z $(( (i*53) % 360 )); i=$((i+1))
done
for p in "-33 26" "33 26" "-33 -25" "33 -25" "-20 30.5" "20 30.5"; do
  set -- $p; n stl $1 $2 $(( (i*71) % 360 )) 1.3; i=$((i+1))
  n stm $(awk -v a=$1 'BEGIN{print a+1.4}') $(awk -v b=$2 'BEGIN{print b+0.9}') $(( (i*19) % 360 )); i=$((i+1))
  n sts $(awk -v a=$1 'BEGIN{print a-1.1}') $(awk -v b=$2 'BEGIN{print b+1.3}') $(( (i*23) % 360 )); i=$((i+1))
done

# =================== BLUMEN: Rabatten rund ums Zelt ===================
grp Blumen
BB=(gbl gbm gbs pop popa popb gra ree)
i=0
# Nordseite Zelt (vor dem Eingang), Suedseite, Ost, West
for x in -15 -12 -9 -6 -3 0 3 6 9 12 15; do
  n ${BB[$((i%8))]} $x 14.5 $(( (i*67) % 360 )); i=$((i+1))
  n ${BB[$(((i+4)%8))]} $x -17.3 $(( (i*41) % 360 )); i=$((i+1))
done
for z in -14 -11 -8 -5 -2 1 4 7 10 13; do
  n ${BB[$((i%8))]} 16.6 $z $(( (i*31) % 360 )); i=$((i+1))
  n ${BB[$(((i+2)%8))]} -16.6 $z $(( (i*59) % 360 )); i=$((i+1))
done
# Grasbueschel entlang der Wegraender
for x in -30 -26 -18 -10 -2 6 14 26 30; do
  n gra $x 23.7 $(( (i*13) % 360 )) 1.6; i=$((i+1))
  n gra $x -26.7 $(( (i*17) % 360 )) 1.6; i=$((i+1))
  n popa $(awk -v a=$x 'BEGIN{print a+1.6}') 23.9 $(( (i*11) % 360 )) 1.4; i=$((i+1))
done
for z in -14 -6 2 10 18; do
  n gra 26.8 $z $(( (i*7) % 360 )) 1.6; i=$((i+1))
  n gra -26.8 $z $(( (i*43) % 360 )) 1.6; i=$((i+1))
  n popb 27.1 $(awk -v b=$z 'BEGIN{print b+1.7}') $(( (i*3) % 360 )) 1.4; i=$((i+1))
done

# =================== SITZEN: zwei Biergaerten + Baenke ===================
grp Sitzen
# Biergarten Nordwest um (-30.5, 20)
bg() {  # bg <cx> <cz>
  local cx=$1 cz=$2 k=0
  for dx in -3 0 3; do
    for dz in -2.6 2.6; do
      n pic $(awk -v a=$cx -v b=$dx 'BEGIN{print a+b}') $(awk -v a=$cz -v b=$dz 'BEGIN{print a+b}') $(( (k*90) % 360 )) 1.4
      k=$((k+1))
    done
  done
  for dx in -3 0 3; do
    n cum $(awk -v a=$cx -v b=$dx "BEGIN{print a+b}") $cz 0 1.25
  done
  n cme $(awk -v a=$cx 'BEGIN{print a+4.4}') $(awk -v b=$cz 'BEGIN{print b-3.4}') 200
  n tca $(awk -v a=$cx 'BEGIN{print a-4.4}') $(awk -v b=$cz 'BEGIN{print b+3.4}') 0
  for dx in -4.6 4.6; do
    n pfa $(awk -v a=$cx -v b=$dx 'BEGIN{print a+b}') $cz 90 1.0
  done
}
bg -30.5 20
bg 30.5 20
# Baenke an den Wegraendern, zum Weg hin ausgerichtet
for x in -30 -24 -18 -12 -6 0 6 12 18 24 30; do
  n ben $x 23.9 180 1.2
  n ben $x -26.9 0 1.2
done
for z in -14 -8 -2 4 10 16; do
  n ben 26.9 $z 270 1.2
  n ben -26.9 $z 90 1.2
done
# Cafe-Ecke am Suedost-Weg
for p in "24.5 -14 0" "24.5 -11 90" "27.5 -14 180" "27.5 -11 270"; do
  set -- $p; n cch $1 $2 $3
done
n cta 26 -12.5 0
n cum 26 -12.5 0 1.2

# =================== LAEDEN: Luecken in den Standreihen ===================
grp Laeden
n ice 2.5 27 180 1.2
n pcn 6.5 27 180 1.2
n sod 10 27 180 1.2
n hot 13 27 180 1.2
n gif -30.5 24.5 180 1.1
n bak 30.5 24.5 180 1.0
n gaz -30.5 13 0 1.3
n tba1 20 22 225 1.1
n tbb -20 22 135 1.1
n ice -1 -30 0 1.2
n hot 2 -30 0 1.2

# =================== KLEINKRAM ===================
grp Kleinkram
for p in "-18.5 23.6" "18.5 23.6" "-18.5 -26.6" "18.5 -26.6" "26.6 18.5" "-26.6 18.5" "26.6 -18.5" "-26.6 -18.5"; do
  set -- $p; n tca $1 $2 0; n tbi $(awk -v a=$1 'BEGIN{print a+0.9}') $2 0
done
n tba -19.4 23.2 40
n tba 19.4 -26.2 210
for p in "-17 23.4" "17 23.4" "-17 -26.4" "17 -26.4"; do
  set -- $p; n hyd $1 $2 0
done
# Absperrungen vor den Fahrgeschaeften
for x in 25 27 29 31 33; do
  n qbc $x -23.6 90 1.1
done
for x in 25 27 29 31 33; do
  n qbo $x -21.5 90 1.1
done
n fou -30.5 -13 0 1.0
for x in -6 -3 0 3 6; do
  n fwo $x 31.2 0 1.4
done

# =================== FAHRGESCHAEFTE (Silhouette hinter der Mauer) ===================
grp Fahrgeschaefte
n rak 30.5 -19.5 0 1.0
n wav 40 -3 270 1.0
n tur -40 6 0 1.0

# ---------- Datei schreiben ----------
{
  echo "[gd_scene load_steps=$(( $(wc -l < "$EXTS") + 1 )) format=3]"
  echo
  cat "$EXTS"
  echo
  echo '[node name="Deko" type="Node3D"]'
  cat "$NODES"
} > "$OUT"
echo "Knoten: $CNT   Ressourcen: $(wc -l < "$EXTS")"
