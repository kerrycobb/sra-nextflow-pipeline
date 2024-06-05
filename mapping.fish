set basedir "/mnt/scratch/smithlab/cobb/bears"
set workdir "$basedir/nf-mapping"
set outdir "$basedir/mapped"
set index "$basedir/brown-bear-genome/GCF_023065955.2_UrsArc2.0_genomic"
set samplesheet "/mnt/home/kc2824/bears/data/bear-samples-run-data-part.csv"

sub -n mapping -w "nextflow -C mapping.config run -w $workdir mapping.nf "\
  "--outdir $outdir --samplesheet $samplesheet --index $index"