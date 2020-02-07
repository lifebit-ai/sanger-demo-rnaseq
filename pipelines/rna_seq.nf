nextflow.preview.dsl=2

// list and dir location of input fastqs:
// $baseDir is to set paths relative to the location of this main script rna_seq.nf
params.lifebit_inputs_files = "$baseDir/../inputs/lifebit_input_files.tsv"
params.input_fastqs_dir = "$baseDir/../../samples"

// pipeline options:
params.min_reads = 500   // used by crams_to_fastq_gz
params.genome = 'GRCh38' // used by star aligner
params.fcextra = ""      // used by featurecounts
params.min_pct_aln  = 5 // used to filter STAR alignements, checking if align rate below threshold
params.singleend = false       // used by featurecounts
params.forward_stranded = false  // used by featurecounts
params.reverse_stranded = true  // used by featurecounts
params.unstranded = false  // used by featurecounts
params.biotypes_header= "$baseDir/../assets/biotypes_header.txt" // used by featurecounts
params.mito_name = 'MT' // used by mapsummary
params.runtag = 'lifebit-demo' // HG_UKBB_scRNA_Pilot I&II 
params.ensembl_lib = "Ensembl 91 EnsDb" // used by tximport, must match used genome version

params.run_star = true
def pick_aligner(String aligner) {
    return  aligner == 'star' || (!params.run_star && aligner == 'hisat2')
    ? true
    : false }

params.star_index = params.genome ? params.genomes[ params.genome ].star ?: false : false
Channel.fromPath(params.star_index)
    .ifEmpty { exit 1, "star index file not found: ${params.star_index}" }
    .set { ch_star_index}
    
params.gtf = params.genome ? params.genomes[ params.genome ].gtf ?: false : false
Channel.fromPath(params.gtf)
    .ifEmpty { exit 1, "GTF annotation file not found: ${params.gtf}" }
    .set { ch_gtf_star }

Channel.fromPath(params.biotypes_header)
    .ifEmpty { exit 1, "biotypes header file not found: ${params.biotypes_header}" }
    .set { ch_biotypes_header }

params.salmon_index = "$baseDir/../../genomes/salmon14_index/salmon"
Channel.fromPath(params.salmon_index)
    .ifEmpty { exit 1, "Salmon index dir not found: ${params.salmon_index}" }
    .set {ch_salmon_index}

params.salmon_trans_gene = "$baseDir/../../genomes/salmon14_index/trans_gene.txt"
Channel.fromPath(params.salmon_trans_gene)
    .ifEmpty { exit 1, "Salmon trans gene file not found: ${params.salmon_trans_gene}" }
    .set {ch_salmon_trans_gene}


include fastqc from '../modules/rna_seq/fastqc.nf' params(run: true, outdir: params.outdir)

include salmon from '../modules/rna_seq/salmon.nf' params(run: true, outdir: params.outdir)
include merge_salmoncounts from '../modules/rna_seq/merge_salmoncounts.nf' params(run: true, outdir: params.outdir,
						   runtag : params.runtag)
include tximport from '../modules/rna_seq/tximport.nf' params(run: true, outdir: params.outdir,
						 ensembl_lib: params.ensembl_lib)

include star_2pass_basic from '../modules/rna_seq/star_2pass_basicmode.nf' params(run: true, outdir: params.outdir)

include filter_star_aln_rate from '../modules/rna_seq/filter_star_aln_rate.nf' params(run: true,
									     min_pct_aln: params.min_pct_aln)
include leafcutter_bam2junc from '../modules/rna_seq/leafcutter_bam2junc.nf' params(run: true, outdir: params.outdir)
include leafcutter_clustering from '../modules/rna_seq/leafcutter_clustering.nf' params(run: true, outdir: params.outdir)
include featureCounts from '../modules/rna_seq/featurecounts.nf' params(run: true,outdir: params.outdir,
							       fcextra: params.fcextra,
							       singleend: params.singleend, 
							       forward_stranded: params.forward_stranded,
							       reverse_stranded: params.reverse_stranded,
							       unstranded: params.unstranded)
include samtools_index_idxstats from '../modules/rna_seq/samtools_index_idxstats.nf' params(run: true, outdir: params.outdir)
include merge_featureCounts from '../modules/rna_seq/merge_featureCounts.nf' params(run: true, outdir: params.outdir,
									   runtag : params.runtag)
include multiqc from '../modules/rna_seq/multiqc.nf' params(run: true, outdir: params.outdir,
						   runtag : params.runtag)
include heatmap from '../modules/rna_seq/heatmap.nf' params(run: true, outdir: params.outdir,
						   runtag : params.runtag)

workflow {

    Channel.fromPath(params.lifebit_inputs_files)
	.splitCsv(header: true, sep: '\t')
        .take(-1) // can replace -1 with a number to process only a subset of the samples (-1 takes all)
	.map{ row -> tuple( row.samplename, tuple(file("${params.input_fastqs_dir}/${row.fastq1}"),
						  file("${params.input_fastqs_dir}/${row.fastq2}")) ) }
	.set{ch_samplename_fastqs}
    
    fastqc(ch_samplename_fastqs)

    salmon(ch_samplename_fastqs, ch_salmon_index.collect(), ch_salmon_trans_gene.collect())

    merge_salmoncounts(salmon.out[0].collect(), salmon.out[1].collect())

    tximport(salmon.out[0].collect())
    heatmap(merge_salmoncounts.out[0].map{transcounts,transtpm,genecouts,genetpm-> genecouts})
    
    star_2pass_basic(ch_samplename_fastqs, ch_star_index.collect(), ch_gtf_star.collect())

    star_out = star_2pass_basic.out
    
    leafcutter_bam2junc(star_out[0])
    leafcutter_clustering(leafcutter_bam2junc.out.collect())

    filter_star_aln_rate(star_out[1].map{samplename,logfile,bamfile -> [samplename,logfile]}) // discard bam file, only STAR log required to filter
    
    filter_star_aln_rate.out.branch {
        filtered: it[1] == 'above_threshold'
        discarded: it[1] == 'below_threshold'}.set { star_filter }
    
    star_filter.filtered.combine(star_out[1], by:0) //reattach bam file
	.map{samplename,filter,logfile,bamfile -> ["star", samplename, bamfile]} // discard log file and attach aligner name
	.set{star_filtered} 
    
    samtools_index_idxstats(star_filtered)
    
    featureCounts(star_filtered, ch_gtf_star.collect(), ch_biotypes_header.collect())

    merge_featureCounts(featureCounts.out[0].map{samplename, gene_fc_txt -> gene_fc_txt}.collect())

    featureCounts.out[1]
	.filter{ pick_aligner(it[0]) }
	.map { it[1] }
	.set{ ch_multiqc_fc_aligner }

    featureCounts.out[2]
	.filter{ pick_aligner(it[0]) }
	.map{ it[1] }
	.set{ ch_multiqc_fcbiotype_aligner }

    multiqc(fastqc.out.collect().ifEmpty([]),
	    ch_multiqc_fc_aligner.collect().ifEmpty([]),
	    ch_multiqc_fcbiotype_aligner.collect().ifEmpty([]),
	    star_out[2].collect().ifEmpty([]),
	    salmon.out[2].collect().ifEmpty([]))
    
}
