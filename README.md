# lifebit-demo
RNAseq pipeline

## Example usage
```bash
# HPC (local files)
nextflow run pipelines/rna_seq.nf \
--lifebit_inputs_files inputs/lifebit_input_files.tsv \
--input_fastqs_dir testdata/samples/ \
--genomes_base testdata/genomes/ \
--salmon_index testdata/genomes/salmon14_index/salmon/ \
--salmon_trans_gene testdata/genomes/salmon14_index/trans_gene.txt

# Cloud (remote files)
nextflow run https://github.com/lifebit-ai/sanger-demo-rnaseq \
--lifebit_inputs_files s3://lifebit-demo/sanger/demo-data/inputs/lifebit_input_files.tsv \
--input_fastqs_dir s3://lifebit-demo/sanger/demo-data/samples \
--genomes_base s3://lifebit-demo/sanger/demo-data/genomes \
--max_memory 122.GB
```
