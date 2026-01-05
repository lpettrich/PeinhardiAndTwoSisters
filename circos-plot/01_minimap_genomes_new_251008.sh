#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=100GB
#SBATCH --time=25:00:00
#SBATCH --account=ag-waldvogel
#SBATCH --job-name=pmapthreegenomes
#SBATCH --error /scratch/lpettric/jobs/%x-%N-%j.err
#SBATCH --output /scratch/lpettric/jobs/%x-%N-%j.out
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=lpettric@smail.uni-koeln.de

module purge
module load bio/minimap2/2.28-GCCcore-13.2.0


OUTDIR=/projects/ag-waldvogel/CRC1211/PanasGenomeReport/05_assembly-stats/05_circos_new_251008

ASM1=/home/lpettric/genomes/wwl115/wwl115.draft.softmasked.fasta
ASM2=/home/lpettric/genomes/wwl072/wwl072.draft.softmasked.fasta
ASM3=/home/lpettric/genomes/ES5/es5.curated.fasta

PAF=$OUTDIR/wwl115_wwl072_ES5_minimap2_asm10.paf


cd $OUTDIR

PAF=$OUTDIR/wwl115_wwl072_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM2 $ASM3 > $PAF

PAF=$OUTDIR/wwl115_wwl072_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM2 > $PAF

PAF=$OUTDIR/wwl115_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM3 > $PAF

PAF=$OUTDIR/wwl072_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM2 $ASM3 > $PAF


