params.run = true 

process heatmap {
    tag "heatmap"
    memory = '30G'
    container "lifebitai/rstudio-seurat-tximport:1.0"
    time '400m'
    cpus 1
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }
    maxRetries 3
    
    publishDir "${params.outdir}/heatmap/", mode: 'symlink'

    when:
    params.run

    input:
    file (count_matrix_tsv)

    output:
    tuple file("outputs/salmon_PCA_unbiased_toppc.pdf"), file("outputs/salmon_heatmap_toppc.pdf"), emit: pca_heatmap

    script:
    """
    heatmap.R $count_matrix_tsv
    """
}
