#!/bin/bash

OUT="paf_summary.tsv"

# header
echo -e "File\tAligned_bp\tMean_identity" > "$OUT"

for paf in *.paf
do
    name=$(basename "$paf")

    awk -v name="$name" '
    BEGIN {
        aligned=0;
        total=0;
        id_sum=0;
    }

    {
        # alignment length (query)
        aln = $4 - $3;
        aligned += aln;
        total++;

        # extract dv tag
        for (i=13; i<=NF; i++) {
            if ($i ~ /^dv:f:/) {
                split($i, a, ":");
                dv = a[3];
                id_sum += (1 - dv);
            }
        }
    }

    END {
        if (total == 0) mean_id = 0;
        else mean_id = id_sum / total;

        printf "%s\t%d\t%.4f\n",
            name, aligned, mean_id;
    }
    ' "$paf" >> "$OUT"

done

echo "Done → $OUT"