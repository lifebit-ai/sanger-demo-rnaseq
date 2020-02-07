#!/usr/bin/env bash
echo starting nextflow

export NXF_VER=19.12.0-edge
export NXF_OPTS="-Xms3G -Xmx3G -Dnxf.pool.maxThreads=2000"
nextflow run ./lifebit-demo/pipelines/rna_seq.nf -c ./lifebit-demo/nextflow.config -profile farm4_singularity_gn5 -resume 
