set basedir "/mnt/scratch/smithlab/cobb/bears"
set workdir "basedir/nf-mapping"
set run_accessions "/mnt/home/kc2824/bears/data/bear-samples-run-data-part.csv"
set outdir "$basedir/mapped"
set index = "$basedir/brown-bear-genome/GCF_023065955.2_UrsArc2.0_genomic"

sub -n mapping -w "nextflow -config mapping.config run -resume -work-dir $workdir calling.nf "\
  "--outdir $outdir --run_accessions $run_accessions --index $index"

