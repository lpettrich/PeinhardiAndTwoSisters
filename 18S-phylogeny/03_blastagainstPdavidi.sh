#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32GB
#SBATCH --time=04:00:00
#SBATCH --account=ag-waldvogel
#SBATCH --job-name=blast_18S


# ===============================================

# MODULES / ENVIRONMENT

# ===============================================

module purge
module load lang/Miniconda3/23.9.0-0
conda activate 18Senv

# ===============================================

# VERSION CHECK

# ===============================================

echo "Tool versions:"
echo -n "blastn: "; blastn -version
echo -n "makeblastdb: "; makeblastdb -version
echo -n "seqkit: "; seqkit version
echo "==============================="

# ===============================================

# CONFIGURATION

# ===============================================

INPUT_GENOME="/projects/ag-waldvogel/CRC1211/PanasGenomeReport/11_18S-phylogeny/Panagrolaimusdavidi.fasta"
QUERY_18S="/projects/ag-waldvogel/CRC1211/PanasGenomeReport/11_18S-phylogeny/01_sequences/18S_Panagrolaimusdavidi.fasta"
RESULTS_DIR="${QUERY_18S%/*}/blast_results"

mkdir -p "$RESULTS_DIR"
cd "$RESULTS_DIR"

BLAST_DB="$RESULTS_DIR/genome_db_pdavidi"

# ===============================================

# CREATE BLAST DATABASE

# ===============================================

echo "[INFO] Creating BLAST database from genome"
makeblastdb -in "$INPUT_GENOME" -dbtype nucl -out "$BLAST_DB"

# ===============================================

# SPLIT MULTI-SEQUENCE QUERY AND RUN BLAST

# ===============================================

seqkit split -i "$QUERY_18S" -O "$RESULTS_DIR/temp_query"

for SINGLE_SEQ in "$RESULTS_DIR"/temp_query/*.fasta; do
SEQ_NAME=$(basename "$SINGLE_SEQ" .fasta)
OUTPUT_BLAST="$RESULTS_DIR/genome_vs_${SEQ_NAME}.tsv"
EXTRACTED_18S="$RESULTS_DIR/top_hit_${SEQ_NAME}.fasta"


echo "[INFO] Running BLASTN: $SINGLE_SEQ vs genome"
blastn -query "$SINGLE_SEQ" \
       -db "$BLAST_DB" \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sseq" \
       -max_target_seqs 1 \
       -evalue 1e-20 \
       -num_threads 4 \
       > "$OUTPUT_BLAST"

# Extract aligned sequence directly from BLAST output
if [ -s "$OUTPUT_BLAST" ]; then
    ALIGNED_SEQ=$(awk 'NR==1{print $13}' "$OUTPUT_BLAST")
    SUBJECT_ID=$(awk 'NR==1{print $2}' "$OUTPUT_BLAST")
    echo ">$SUBJECT_ID" > "$EXTRACTED_18S"
    echo "$ALIGNED_SEQ" >> "$EXTRACTED_18S"
    echo "[INFO] Top hit extracted to $EXTRACTED_18S"
else
    echo "[WARN] No hits found for $SEQ_NAME"
fi


done

# Clean up temporary split files

rm -r "$RESULTS_DIR/temp_query"
