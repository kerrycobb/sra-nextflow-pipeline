# Nextflow Pipeline for SRA Data
Download with `ascp`, trim with `fastp`, quality check with `fastqc`, map SRA reads to a reference genome with `bwa-mem2`, sort bam with `samtools` and then merge multiple runs for a single sample into a single `.bam` if necessary.

## Usage 

#### 1. Prepare a csv samplesheet with the following format:

|sample_accession|run_accession|read1_url|read2_url|read1_md5|read2_md5|
|----------------|-------------|---------|---------|---------|---------|
|SAMN12345|SRR12345|fasp.sra.ebi.ac.uk:...|fasp.sra.ebi.ac.uk:...|\<checksum>|\<checksum>|

The urls for read 1 and read 2 should be `ascp` download urls.
Unpaired reads are not supported.

#### 2. Create an index for the reference genome.

#### 3. Prepare configuration file. 
Modify the example `main.config` file. The most important parameters are the cpus and memory for the bwa_mem process. 

#### 4. Execute the pipeline with:
```
nextflow run main.nf \
  --samplesheet <SAMPLESHEET PATH> \ 
  --outdir <OUTDIR PATH> \ 
  --index <INDEX PATH> \
  --ascp_key_path [KEY PATH] \ 
  --ascp_rate_limit [LIMIT] 
```
The `ascp_key_path` and `ascp_rate_limit` arguments are optional.  
`ascp_key_path` defaults to: ~/.aspera/connect/etc/asperaweb_id_dsa.openssh  
`ascp_rate_limit` defaults to: 100M

