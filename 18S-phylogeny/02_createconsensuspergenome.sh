#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --mem=100GB
#SBATCH --time=20:00:00
#SBATCH --account=ag-waldvogel
#SBATCH --job-name=consensus18S28S


module purge
module load lang/Miniconda3/23.9.0-0
conda activate 18Senv

# ==============================

# CONFIGURATION

# ==============================

INPUT_DIR="/projects/ag-waldvogel/CRC1211/PanasGenomeReport/11_18S-phylogeny/01_sequences"
ALIGNED_DIR="${INPUT_DIR}/aligned_rRNA"
CONSENSUS_DIR="${INPUT_DIR}/consensus_rRNA"

mkdir -p "$ALIGNED_DIR" "$CONSENSUS_DIR"

# ==============================

# VERSION CHECK

# ==============================

echo "Tool versions:"
echo -n "mafft: "; mafft --version
echo -n "cons (EMBOSS): "; cons -help | head -n 1
echo -n "seqkit: "; seqkit version
echo "============================="

# ==============================

# FUNCTION: process rRNA type

# ==============================

process_rRNA() {
rRNA_TYPE="$1" # "18S" or "28S"
echo "[INFO] Processing $rRNA_TYPE sequences"


# STEP 1 & 2: Filter ≥300bp sequences and generate consensus
for genome in "$INPUT_DIR"/*_"$rRNA_TYPE".fasta; do
    base=$(basename "${genome%_$rRNA_TYPE.fasta}")
    filtered="${ALIGNED_DIR}/${base}_${rRNA_TYPE}.filtered.fasta"
    aln="${ALIGNED_DIR}/${base}_${rRNA_TYPE}.aln.fasta"
    cons_out="$CONSENSUS_DIR/${base}_${rRNA_TYPE}.consensus.fasta"

    echo "[INFO] Filtering ≥300bp: $genome -> $filtered"
    seqkit seq -m 300 "$genome" > "$filtered"

    # Count sequences after filtering
    seq_count=$(seqkit stats -T "$filtered" | awk 'NR==2{print $4}')

    if [ "$seq_count" -eq 0 ]; then
        echo "[WARN] No sequences ≥300bp in $genome, skipping"
        continue
    elif [ "$seq_count" -eq 1 ]; then
        echo "[INFO] Only one sequence in $filtered, copying as consensus"
        cp "$filtered" "$cons_out"
    else
        echo "[INFO] Aligning $filtered -> $aln"
        mafft --auto "$filtered" > "$aln"

        echo "[INFO] Generating consensus: $aln -> $cons_out"
        cons -sequence "$aln" \
             -outseq "$cons_out" \
             -name "$base" \
             -plurality 1
    fi
done

# STEP 3: Merge all genome consensus sequences
MERGED_FILE="${INPUT_DIR}/all_genomes_${rRNA_TYPE}_consensus.fasta"
echo "[INFO] Merging all $rRNA_TYPE consensus sequences -> $MERGED_FILE"
# Remove old merged file if it exists
[ -f "$MERGED_FILE" ] && rm "$MERGED_FILE"
cat "$CONSENSUS_DIR"/*_"$rRNA_TYPE".consensus.fasta > "$MERGED_FILE"

# STEP 4: QC
echo "[INFO] QC for $rRNA_TYPE"
seqkit stats "$MERGED_FILE"


}

# ==============================

# PROCESS 18S & 28S

# ==============================

process_rRNA "18S"
process_rRNA "28S"

echo "[INFO] All steps completed successfully for 18S and 28S."
