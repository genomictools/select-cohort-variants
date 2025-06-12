#!/usr/bin/env Rscript

# Capture command-line arguments
args <- commandArgs(trailingOnly = TRUE)

chrom   <- args[1]
start   <- args[2]
end     <- args[3]
genome  <- args[4]
style   <- args[5]
coding  <- args[6]
output  <- args[7]

# load genes
if (genome == 'hg38') txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene::TxDb.Hsapiens.UCSC.hg38.knownGene
# elseif (genome == 'hg37') txdb <- TxDb.Hsapiens.UCSC.hg37.knownGene::TxDb.Hsapiens.UCSC.hg37.knownGene

if ( coding == 'true' ) {
  gene_coordinates <- GenomicFeatures::genes(
    txdb,
    filter = list(tx_chrom = chrom),
    columns = AnnotationDbi::columns(txdb)
  )
} else if ( coding == 'false' ) {
  gene_coordinates <- GenomicFeatures::cds(
    txdb,
    filter = list(tx_chrom = chrom),
    columns = AnnotationDbi::columns(txdb)
  )
} else {
  stop("coding can be 'true' or 'false'.")
}

if ( start != 'null' && end != 'null') {
  q <- GenomicRanges::GRanges(
    seqnames = chrom,
    ranges = IRanges::IRanges(start = as.integer(start), end = as.integer(end))
  )
  
  gene_coordinates <- IRanges::subsetByOverlaps(gene_coordinates, q)
}

GenomeInfoDb::seqlevels(gene_coordinates) <- chrom
GenomeInfoDb::seqlevelsStyle(gene_coordinates) <- style

rtracklayer::export.bed(
  gene_coordinates,
  output
)
