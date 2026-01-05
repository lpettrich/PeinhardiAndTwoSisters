#!/bin/bash

# === SETUP ===
module load lang/Miniconda3/23.9.0-0
conda activate circos_env

cd /projects/ag-waldvogel/CRC1211/PanasGenomeReport/05_assembly-stats/05_circos_new_251008

# === INPUT FILES ===
BED=input.bed
OUTDIR=circos_project
mkdir -p "$OUTDIR"

# === STEP 1: Create contig -> assembly mapping ===
echo "Creating contig-assembly map..."

awk '
/\.fasta$/ {
  split($0, path_parts, "/");
  asm = path_parts[length(path_parts)];
  gsub(/\.fasta$/, "", asm);
  next;
}
/^\s*$/ { next; }

{
  contig = $1;
  print contig "\t" asm;
}
' "$BED" > "$OUTDIR/contig_assembly_map.tsv"


# === STEP 2: Generate karyotype file with inline color ===
echo "Generating karyotype.txt..."

awk '
BEGIN {
  OFS = "\t";
  # Assign simple color names to each assembly ID
  color["wwl115.draft.softmasked"] = "230,159,0";
  color["wwl072.draft.softmasked"] = "86,180,233";
  color["es5.curated"] = "204,121,167";

  while ((getline < "'$OUTDIR'/contig_assembly_map.tsv") > 0) {
    contig2asm[$1] = $2;
  }
}
/^\s*$/ || /\.fasta$/ { next }

{
  contig = $1;
  start = $2;
  end = $3;
  asm = contig2asm[contig];

  if (asm == "") next;

  start_adj = start - 1;
  if (start_adj < 0) start_adj = 0;

  # Label: part after first underscore
  label = contig;
  match(contig, /_/) && label = substr(contig, RSTART + 1);

  print "chr", "-", contig, label, start_adj, end, color[asm];
}
' "$BED" > "$OUTDIR/karyotype.txt"


# === STEP 3: Generate links.txt for each PAF and split by assembly pairs ===
echo "Generating links files for each PAF..."

> wwl115_ES5_links.txt
> wwl115_wwl072_links.txt
> ES5_wwl072_links.txt

for PAF in *.paf; do
  echo "Processing $PAF ..."

  awk -v map="$OUTDIR/contig_assembly_map.tsv" -v outdir="$OUTDIR" '
  BEGIN {
    OFS="\t";
    while ((getline < map) > 0) {
      contig2asm[$1] = $2;
    }
  }
  {
    q = $1; qstart = $3; qend = $4;
    t = $6; tstart = $8; tend = $9;

    if (q == t) next;

    qasm = contig2asm[q];
    tasm = contig2asm[t];

    if (qasm == "" || tasm == "") next;
    if (qasm == tasm) next;

    # Explicit map from full asm names to short uppercase names
    asm_map["wwl115.draft.softmasked"] = "wwl115";
    asm_map["wwl072.draft.softmasked"] = "wwl072";
    asm_map["es5.curated"] = "ES5";

    qasm_short = (qasm in asm_map) ? asm_map[qasm] : qasm;
    tasm_short = (tasm in asm_map) ? asm_map[tasm] : tasm;

    # Sort assembly names alphabetically
    if (qasm_short < tasm_short) {
      asm1 = qasm_short;
      asm2 = tasm_short;
    } else {
      asm1 = tasm_short;
      asm2 = qasm_short;
    }

    file = outdir "/" asm1 "_" asm2 "_links.txt";

    print q, qstart, qend, t, tstart, tend >> file;
  }
  ' "$PAF"
done



# === STEP 4: Create circos.conf ===
echo "Creating circos.conf..."

cat > "$OUTDIR/circos.conf" <<EOF
karyotype = karyotype_noscf.txt

<ideogram>
  radius           = 0.9r
  thickness        = 50p
  stroke_thickness = 3p
  stroke_color     = black
  show_label       = yes
  fill             = yes
  label_font       = default
  label_radius     = dims(ideogram,radius) + 0.03r
  label_size       = 50
  <spacing>
    default = 0.02r
  </spacing>
</ideogram>

<ticks>
  radius           = dims(ideogram,radius_outer)
  color            = black
  thickness        = 2p
  size             = 15p
  format           = %d
  multiplier       = 1e-6
  label_format     = %.1f Mb
</ticks>

<links>
<link>
  file            = wwl115_ES5_links.txt
  color           = 230,159,0,0.2     # transparent red
  thickness       = 1
  radius          = 0.9r
  bezier_radius   = 0.1r
</link>

<link>
  file            = wwl115_wwl072_links.txt
  color           = 86,180,233,0.2    # transparent blue
  thickness       = 1
  radius          = 0.9r
  bezier_radius   = 0.1r
</link>

<link>
  file            = ES5_wwl072_links.txt
  color           = 204,121,167,0.2   # transparent purple
  thickness       = 1
  radius          = 0.9r
  bezier_radius   = 0.1r
</link>
</links>

<image>
  dir             = .
  file            = circos.png
  png             = yes
  svg             = yes
  radius          = 2000p
  margin          = 300p 
  background      = white
  angle_offset    = -90
  auto_alpha_colors = yes
  auto_alpha_steps  = 5
</image>

<<include /scratch/lpettric/conda/circos_env/etc/colors_fonts_patterns.conf>>
<<include /scratch/lpettric/conda/circos_env/etc/housekeeping.conf>>
EOF


# === STEP 5: Run Circos ===
echo "Running Circos..."
cd "$OUTDIR"
circos -conf circos.conf

echo "Done. Circos plot generated at: $OUTDIR/circos.png"
