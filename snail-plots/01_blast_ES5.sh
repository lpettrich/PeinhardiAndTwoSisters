#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --cpus-per-task=35
#SBATCH --mem=200GB
#SBATCH --time=25:00:00
#SBATCH --account=ag-waldvogel


module purge
module load bio/SAMtools/1.19.2-GCC-13.2.0
module load bio/BCFtools/1.19-GCC-13.2.0
module load bio/minimap2/2.28-GCCcore-13.2.0
module load lang/Miniconda3/23.9.0-0

OUTDIR=/projects/ag-waldvogel/CRC1211/PanasGenomeReport/10_final-assemblies/ES5

samtools faidx $OUTDIR/es5.curated.fasta

conda activate blast_env

mkdir -p /scratch/lpettric/blobtools/ES5

blastn -db /scratch/lpettric/nt/nt \
       -query $OUTDIR/es5.curated.fasta \
       -outfmt "6 qseqid staxids bitscore std" \
       -max_target_seqs 10 \
       -max_hsps 1 \
       -evalue 1e-25 \
       -num_threads 35 \
       -out /scratch/lpettric/blobtools/ES5/es5.curated.fasta_genome_20250722.ncbi.blastn.run.out
       
       
mkdir -p $OUTDIR/blast
cp /scratch/lpettric/blobtools/ES5/es5.curated.fasta_genome_20250722.ncbi.blastn.run.out $OUTDIR/blast
