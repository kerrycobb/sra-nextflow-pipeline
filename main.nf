params.ascp_key_path = "~/.aspera/connect/etc/asperaweb_id_dsa.openssh"
params.ascp_rate_limit = "100M"

process download {
    tag {run}
    maxRetries 3
    errorStrategy { (task.attempt <= maxRetries) ? "retry" : "ignore" }

    input:
        tuple val(sample), val(run), val(read1), val(read2), val(md5_1), val(md5_2)

    output:
        tuple val(sample), val(run), path("*.fq.gz")

    script:
    if (read2.length() == 0)
    """
    ascp -l $params.ascp_rate_limit -v -k 3 -T -P 33001 -i $params.ascp_key_path era-fasp@${read1} ${run}.fq.gz
    echo "$md5_1 ${run}.fq.gz" | md5sum -c -
    """
    else
    """
    ascp -l $params.ascp_rate_limit -v -k 3 -T -P 33001 -i $params.ascp_key_path era-fasp@${read1} ${run}_1.fq.gz
    echo "$md5_1 ${run}_1.fq.gz" | md5sum -c -
    ascp -l $params.ascp_rate_limit -v -k 3 -T -P 33001 -i $params.ascp_key_path era-fasp@${read1} ${run}_2.fq.gz
    echo "$md5_1 ${run}_2.fq.gz" | md5sum -c -
    """

    stub:
    """
    touch ${run}.fq.gz
    """
}

process fastp {
    tag { run }
    errorStrategy "ignore"

    input:
    tuple val(sample), val(run), path(reads)

    output:
    tuple val(sample), val(run), path("${run}_1.trimmed.fq.gz"), path("${run}_2.trimmed.fq.gz"), emit: trimmed
    path("*.fastp_stats.json"), emit: log

    script:
    if (reads.size() == 0)
    """
    fastp --interleaved_in --thread $task.cpus --in1 $read --out1 ${run}_1.trimmed.fq.gz \
    --out2 ${run}_2.trimmed.fq.gz --json ${run}.fastp_stats.json 
    """
    else:
    """
    fastp --thread $task.cpus --in1 ${read[0]} --in2 ${read[1]} --out1 ${run}_1.trimmed.fq.gz \
    --out2 ${run}_2.trimmed.fq.gz --json ${run}.fastp_stats.json 
    """

    stub:
    """
    touch ${run}_1.trimmed.fq.gz ${run}_2.trimmed.fq.gz ${run}.fastp_stats.json
    """
}

process fastqc {
    tag { run }
    errorStrategy "ignore"

    input:
    tuple val(sample), val(run), path(read1), path(read2)

    output:
    path "*_fastqc.zip"

    script:
    """
    fastqc --threads $task.cpus --quiet $read1 $read2
    """

    stub:
    """
    touch ${run}_fastqc.zip
    """
}

process multiqc {
    // Needs multiqc v1.18 to parse fastp
    publishDir params.outdir, mode: "symlink"

    input:
    path multiqc_files 

    output:
    path "multiqc_report.html"

    shell:
    """
    multiqc . 
    """

    stub:
    """
    touch multiqc_report.html
    """
}

process bwa_mem {
    tag { run }
    maxRetries 3 
    errorStrategy { (task.attempt <= maxRetries) ? "retry" : "ignore" }

    input:
    tuple val(sample), val(run), path(read1), path(read2)

    output:
    tuple val(sample), val(run), path("${run}.bam")

    script:
    """
    bwa-mem2 mem -p -t $task.cpus $params.index $read1 $read2 | samtools sort --threads $task.cpus -o ${run}.bam
    """

    stub:
    """
    touch ${run}.bam
    """
}

process samtools_merge {
    tag {sample}
    errorStrategy "ignore"
    publishDir params.outdir, mode: "move", overwrite:true

    input: 
    tuple val(sample), path(runs)

    output:
    path("${sample}.bam")

    script:
    if (runs.size() > 1)
    """
    samtools merge --threads $task.cpus -o ${sample}.bam $runs
    """
    else
    """
    mv $runs ${sample}.bam
    """

    stub:
    if ( runs.size() > 1 )
    """
    cat $runs > ${sample}.bam
    """
    else
    """
    mv $runs ${sample}.bam
    """
}


workflow  {
    runs = Channel.fromPath(params.samplesheet).splitCsv(header:true)
    download(runs)
    fastp(download.out)
    fastqc(fastp.out.trimmed)
    bwa_mem(fastp.out.trimmed)
    // Merge bam files by sample
    grouped = bwa_mem.out.map{ it -> tuple(it[0], it[2]) }.groupTuple()
    samtools_merge(grouped)
    // QC
    Channel.empty()
        .mix(fastqc.out)
        .mix(fastp.out.log)
        .collect()
        .set { log_files }
    multiqc(log_files)
}