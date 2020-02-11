FROM lifebitai/rstudio-seurat-tximport:latest

COPY ./tximport.R /usr/local/bin
COPY ./heatmap.R /usr/local/bin
RUN chmod +x /usr/local/bin/tximport.R /usr/local/bin/heatmap.R