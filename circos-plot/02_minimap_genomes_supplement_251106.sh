#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=100GB
#SBATCH --time=25:00:00
#SBATCH --account=ag-waldvogel
#SBATCH --job-name=pmapthreegenomes


module purge
module load bio/minimap2/2.28-GCCcore-13.2.0


OUTDIR=/projects/ag-waldvogel/CRC1211/PanasGenomeReport/05_assembly-stats/06_circos_supplement_251106

ASM1=/projects/ag-waldvogel/CRC1211/PanasGenomeReport/10_final-assemblies/wwl115/wwl115.draft.softmasked.fasta
ASM2=/projects/ag-waldvogel/CRC1211/PanasGenomeReport/10_final-assemblies/wwl072/wwl072.draft.softmasked.fasta
ASM3=/home/lpettric/genomes/ES5/es5.curated.fasta

PAF=$OUTDIR/wwl115_wwl072_ES5_minimap2_asm10.paf


cd $OUTDIR

# rename contigs
# For wwl115
awk '
/^>/ {
  name = substr($0, 2)
  if (name ~ /^scaffold_/) {
    gsub(/^scaffold_/, "scf", name)
    print ">wwl115_" name
  } else {
    print ">" name
  }
  next
}
{ print }
' $ASM1 > wwl115.renamed.fasta


# For wwl072
awk '
/^>/ {
  name = substr($0, 2)
  if (name ~ /^scaffold_/) {
    gsub(/^scaffold_/, "scf", name)
    print ">wwl072_" name
  } else {
    print ">" name
  }
  next
}
{ print }
' $ASM2 > wwl072.renamed.fasta


# For ES5
awk '
/^>/ {
  name = substr($0, 2)
  if (name ~ /^scaffold[0-9_]*$/) {
    gsub(/^scaffold/, "scf", name)
    print ">ES5_" name
  } else {
    print ">" name
  }
  next
}
{ print }
' $ASM3 > ES5.renamed.fasta


ASM1=wwl115.renamed.fasta
ASM2=wwl072.renamed.fasta
ASM3=ES5.renamed.fasta


# run mapping

PAF=$OUTDIR/wwl115_wwl072_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM2 $ASM3 > $PAF

PAF=$OUTDIR/wwl115_wwl072_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM2 > $PAF

PAF=$OUTDIR/wwl115_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM1 $ASM3 > $PAF

PAF=$OUTDIR/wwl072_ES5_minimap2_asm10.paf
minimap2 -x asm10 $ASM2 $ASM3 > $PAF


