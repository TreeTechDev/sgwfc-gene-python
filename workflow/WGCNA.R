#!/usr/bin/env Rscript

DOC = "WGCNA for CRC consensus molecular subtypes"


renv::restore(prompt = FALSE)

args = commandArgs(trailingOnly=TRUE)

# The following setting is important, do not omit.
options(stringsAsFactors = FALSE);

vsd <- read.csv2(paste0(getwd(), args[1]))
vsd <- `row.names<-`(vsd[-1], vsd$X)
outdir <- paste0(getwd(), args[2])

### load packages
library(plyr)
library(dplyr)
library(DESeq2)
library(SummarizedExperiment)
library(matrixStats)
library(WGCNA)

####### selecting genes #######
rv = rowMedians(as.matrix(vsd))
select = order(rv, decreasing = TRUE)[seq_len(min(15000, length(rv)))] # Top 15000 most variable genes
vsd <- vsd[select,]
vsd <- as.data.frame(vsd)

gene.names=rownames(vsd)
SubGeneNames=gene.names
WGCNA_matrix <- t(vsd)
### Transpose matrix

### similarity measure between gene profiles: biweight midcorrelation

allowWGCNAThreads() # Uses all available cores; check function help to set specific number if needed

### test for best beta value
powers = c(c(1:10), seq(from = 12, to=20, by=2))
sft = pickSoftThreshold(WGCNA_matrix, powerVector = powers, verbose = 5, corOptions = list(maxPOutliers =0.1),
                        networkType ="unsigned", corFnc= "bicor")

beta = min(which(-sign(sft$fitIndices[,3])*sft$fitIndices[,2]>=0.9))

print(beta)

#in case beta doesn't cross the threshold
if(beta == Inf){
  ifelse(ncol(vsd) > 40,beta = 6,
  ifelse(ncol(vsd) >= 30, beta = 7,
  ifelse(ncol(vsd) >= 20, beta = 8, beta = 9)))
}


#turn adjacency matrix into topological overlap to minimize the effects of noise and spurious associations
adj= adjacency(WGCNA_matrix,type = "unsigned", power = beta,corOptions = list(maxPOutliers =0.1),
               corFnc= "bicor");
TOM=TOMsimilarity(adj)

colnames(TOM) =rownames(TOM) =SubGeneNames
dissTOM=1-TOM

#hierarchical clustering of the genes based on the TOM dissimilarity measure
library(flashClust)
geneTree = flashClust(as.dist(dissTOM),method="average");

# Set the minimum module size
minModuleSize = 100;

# Module identification using dynamic tree cut

### dynamicMods = cutreeDynamic(dendro = geneTree,  method="tree", minClusterSize = minModuleSize);
dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM, method="hybrid", 
                            deepSplit = 1, pamRespectsDendro = FALSE, 
                            minClusterSize = minModuleSize);

#the following command gives the module labels and the size of each module. Label 0 is reserved for unassigned genes

table(dynamicMods)

dynamicColors = labels2colors(dynamicMods)

sink(paste0(outdir,"/modules.txt"),append = TRUE)
print("Adding color labels to modules")
table(dynamicColors)
sink()

###Extract modules
module_colors= unique(dynamicColors)
module <- list()

library(AnnotationDbi)
library(EnsDb.Hsapiens.v86)

for (color in module_colors){
  module[[color]]=SubGeneNames[which(dynamicColors==color)]
  module[[color]] <- data.frame(EnsemblID = module[[color]], Symbol = mapIds(EnsDb.Hsapiens.v86, keys = module[[color]], column = "SYMBOL", keytype = "GENEID", multiVals = "first"))
  write.table(module[[color]]$Symbol, paste(outdir,"/module_",color, ".txt",sep=""), 
              sep="\t", row.names=FALSE, col.names=FALSE,quote=FALSE)
}
cat(sprintf("module_%s.txt", module_colors))
q()