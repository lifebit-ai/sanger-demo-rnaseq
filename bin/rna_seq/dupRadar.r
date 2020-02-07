#!/usr/bin/env Rscript

# Command line argument processing
args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 3) {
  stop("Usage: dupRadar.r <input.bam> <annotation.gtf> <paired/single>", call.=FALSE)
}

input_bam <- args[1]
annotation_gtf <- args[2]
paired_end <- if(args[3]=='paired') TRUE else FALSE
input_bam_basename <- strsplit(input_bam, "\\.")[[1]][1]

# Load packages
library(dupRadar)
library(parallel)

# Duplicate stats
stranded <- 2
threads <- detectCores()
dm <- analyzeDuprates(input_bam, annotation_gtf, stranded, paired_end, threads)
write.table(dm, file=paste(input_bam_basename, "_dupMatrix.txt", sep=""), quote=F, row.name=F, sep="\t")

# 2D density scatter plot
pdf(paste0(input_bam, "_duprateExpDens.pdf"))
duprateExpDensPlot(DupMat=dm)
title("Density scatter plot")
mtext(input_bam_basename, side=3)
dev.off()
fit <- duprateExpFit(DupMat=dm)
cat(
  paste("- dupRadar Int (duprate at low read counts):", fit$intercept),
  paste("- dupRadar Sl (progression of the duplication rate):", fit$slope),
  fill=TRUE, labels=input_bam_basename,
  file=paste0(input_bam_basename, "_intercept_slope.txt"), append=FALSE
)

# Get numbers from dupRadar GLM
curve_x <- sort(log10(dm$RPK))
curve_y = 100*predict(fit$glm, data.frame(x=curve_x), type="response")
# Remove all of the infinite values
infs = which(curve_x %in% c(-Inf,Inf))
curve_x = curve_x[-infs]
curve_y = curve_y[-infs]
# Reduce number of data points
curve_x <- curve_x[seq(1, length(curve_x), 10)]
curve_y <- curve_y[seq(1, length(curve_y), 10)]
# Convert x values back to real counts
curve_x = 10^curve_x
# Write to file
line="#id: DupRadar
#section_name: 'DupRadar'
#section_href: 'bioconductor.org/packages/release/bioc/html/dupRadar.html'
#description: \"provides duplication rate quality control for RNA-Seq datasets. Highly expressed genes can be expected to have a lot of duplicate reads, but high numbers of duplicates at low read counts can indicate low library complexity with technical duplication.
#    This plot shows the general linear models - a summary of the gene duplication distributions. \"
#pconfig:
#    title: 'DupRadar General Linear Model'
#    xLog: True
#    xlab: 'expression (reads/kbp)'
#    ylab: '% duplicate reads'
#    ymax: 100
#    ymin: 0
#    tt_label: '<b>{point.x:.1f} reads/kbp</b>: {point.y:,.2f}% duplicates'
#    xPlotLines:
#        - color: 'green'
#          dashStyle: 'LongDash'
#          label:
#                style: {color: 'green'}
#                text: '0.5 RPKM'
#                verticalAlign: 'bottom'
#                y: -65
#          value: 0.5
#          width: 1
#        - color: 'red'
#          dashStyle: 'LongDash'
#          label:
#                style: {color: 'red'}
#                text: '1 read/bp'
#                verticalAlign: 'bottom'
#                y: -65
#          value: 1000
#          width: 1"

write(line,file=paste0(input_bam_basename, "_duprateExpDensCurve_mqc.txt"),append=TRUE)
write.table(
  cbind(curve_x, curve_y),
  file=paste0(input_bam_basename, "_duprateExpDensCurve_mqc.txt"),
  quote=FALSE, row.names=FALSE, col.names=FALSE, append=TRUE, 
)

# Distribution of expression box plot
pdf(paste0(input_bam_basename, "_duprateExpBoxplot.pdf"))
duprateExpBoxplot(DupMat=dm)
title("Percent Duplication by Expression")
mtext(input_bam_basename, side=3)
dev.off()

# Distribution of RPK values per gene
pdf(paste0(input_bam_basename, "_expressionHist.pdf"))
expressionHist(DupMat=dm)
title("Distribution of RPK values per gene")
mtext(input_bam_basename, side=3)
dev.off()

# Print sessioninfo to standard out
print(input_bam_basename)
citation("dupRadar")
sessionInfo()
