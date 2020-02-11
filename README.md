# lifebit-demo
RNAseq pipeline

## Example usage
```bash
# local files
nextflow run pipelines/rna_seq.nf \
--lifebit_inputs_files inputs/lifebit_input_files.tsv \
--input_fastqs_dir testdata/samples/ \
--genomes_base testdata/genomes/ \
--salmon_index testdata/genomes/salmon14_index/salmon/ \
--salmon_trans_gene testdata/genomes/salmon14_index/trans_gene.txt \
-resume

# remote files
nextflow run pipelines/rna_seq.nf \
--lifebit_inputs_files inputs/lifebit_input_files.tsv \
--input_fastqs_dir s3://lifebit-user-data-b8e5f61f-9552-45bc-bf51-edbe6d387d1a/projects/5e3dc3fee3474100f472d547/demo-data/samples/ \
--genomes_base s3://lifebit-user-data-b8e5f61f-9552-45bc-bf51-edbe6d387d1a/projects/5e3dc3fee3474100f472d547/demo-data/genomes/ \
--salmon_index s3://lifebit-user-data-b8e5f61f-9552-45bc-bf51-edbe6d387d1a/projects/5e3dc3fee3474100f472d547/demo-data/genomes/salmon14_index/salmon/ \
--salmon_trans_gene s3://lifebit-user-data-b8e5f61f-9552-45bc-bf51-edbe6d387d1a/projects/5e3dc3fee3474100f472d547/demo-data/genomes/salmon14_index/trans_gene.txt \
-resume
```