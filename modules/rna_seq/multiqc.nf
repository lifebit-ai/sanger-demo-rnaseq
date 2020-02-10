params.run = true
params.runtag = 'runtag'

process multiqc {
    scratch '/tmp'
    stageInMode 'copy'
    stageOutMode 'rsync'
    container "nfcore/rnaseq:1.4.2"
    errorStrategy = { task.attempt <= 5 ? 'retry' : 'ignore' }
    cpus =   {  2 * 2 * Math.min(2, task.attempt) }
    memory = {  40.GB + 20.GB * (task.attempt-1) }
    maxRetries 5
    cpus 2
    queue 'long'
    time '900m'

    publishDir "${params.outdir}", mode: 'copy',
      saveAs: {filename ->
          if (filename.indexOf("multiqc.html") > 0) "combined/$filename"
          else if (filename.indexOf("_data") > 0) "$filename"
          else null
      }

    when:
    params.run

    input:
    file (fastqc:'fastqc/*') //from ch_multiqc_fastqc.collect().ifEmpty([])
    file ('featureCounts/*') //from ch_multiqc_fc_aligner.collect().ifEmpty([])
    file ('featureCounts_biotype/*') //from ch_multiqc_fcbiotype_aligner.collect().ifEmpty([])
    file ('star/*') //from ch_alignment_logs_star.collect().ifEmpty([])
    file ('salmon/*') //from ch_alignment_logs_salmon.collect().ifEmpty([])

    output:
    file "*_multiqc.html"
    file "*_data"

    script:
    def filename = "${params.runtag}_multiqc.html"
    def reporttitle = "${params.runtag}"
    """
    export PATH=/opt/conda/envs/nf-core-rnaseq-1.3/bin:\$PATH

    multiqc . -f --title "$reporttitle" --filename "$filename" -m featureCounts -m star -m fastqc -m salmon
    """
}
// multiqc . -f --title "$reporttitle" --filename "$filename" -m custom_content -m featureCounts -m star -m fastqc -m salmon
