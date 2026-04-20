#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --mem=100GB
#SBATCH --time=20:00:00
#SBATCH --account=ag-waldvogel
#SBATCH --job-name=extract18S28S


module purge
module load lang/Miniconda3/23.9.0-0
conda activate rRNAenv

### CONFIGURATION ###
FASTA_DIR="/projects/ag-waldvogel/CRC1211/PanasGenomeReport/11_18S-phylogeny"
OUT_DIR="/projects/ag-waldvogel/CRC1211/PanasGenomeReport/11_18S-phylogeny/01_sequences"
mkdir -p "$OUT_DIR"

echo "=== Tool check ==="
echo "barrnap: $(command -v barrnap)"
echo "seqkit: $(command -v seqkit)"
echo "=================="

shopt -s nullglob
for fasta in "$FASTA_DIR"/*.fasta; do
    base=$(basename "${fasta%.fasta}")
    rrna_fa="$OUT_DIR/${base}_rrna.fa"
    rrna_gff="$OUT_DIR/${base}_rrna.gff"

    echo "[+] Running barrnap on: $fasta"
    # write FASTA and GFF
    barrnap --kingdom euk -o "$rrna_fa" "$fasta" > "$rrna_gff"

    echo "    Extracting 18S sequences for $base"
    grep -i "18S" "$rrna_fa" -A 1 | grep -v "^--$" > "$OUT_DIR/${base}_18S.fasta"

    echo "    Extracting 28S sequences for $base"
    grep -i "28S" "$rrna_fa" -A 1 | grep -v "^--$" > "$OUT_DIR/${base}_28S.fasta"


    # remove empty files if no sequences found
    [ ! -s "$OUT_DIR/${base}_18S.fasta" ] && rm -f "$OUT_DIR/${base}_18S.fasta"
    [ ! -s "$OUT_DIR/${base}_28S.fasta" ] && rm -f "$OUT_DIR/${base}_28S.fasta"
done
shopt -u nullglob

echo "=== Done extracting 18S and 28S from all genomes ==="
