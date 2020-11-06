### igraph with STRING and WGCNA interaction information ###

#Setting directories
projdir <- "."

workdir <- paste0(projdir,"/results/WGCNA/CMS/2019-03-11/menos_modulos")
libdir  <- paste0(projdir,"/lib/Rpackages/4.0/")
resultsdir <- paste0(projdir,"/results/")

setwd(workdir)
.libPaths(libdir)
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.11")
install.packages("Formula")
install.packages("base64enc")
install.packages("latticeExtra")
install.packages("htmlTable")
install.packages("data.table")
install.packages("mnormt")
install.packages("pbivnorm")
install.packages("rjson")
install.packages("whisker")

library(dplyr)
library(tidyr)
library(viridis)
library(RColorBrewer)
library(circlize)
library(autoimage)
library(png)
library(igraph)

#Carrega arquivos 

lfcall <- read.csv("data/lfcall.csv")
exc1 <- read.csv("data/DEGs/exc1.csv")
exc2 <- read.csv("data/DEGs/exc2.csv")
exc3 <- read.csv("data/DEGs/exc3.csv")
exc4e <- read.csv("data/DEGs/exc4e.csv")
exc4s <- read.csv("data/DEGs/exc4s.csv")
sig1 <- read.csv("data/DEGs/sig1.csv")
sig2 <- read.csv("data/DEGs/sig2.csv")
sig3 <- read.csv("data/DEGs/sig3.csv")
sig4e <- read.csv("data/DEGs/sig4e.csv")
sig4s <- read.csv("data/DEGs/sig4s.csv")

# Adding custom shapes

############################# custom circle vertex shape ####################################

mycircle <- function(coords, v=NULL, params) {
  vertex.color <- params("vertex", "color")
  if (length(vertex.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.color[v]
  }
  vertex.size  <- 1/200 * params("vertex", "size")
  if (length(vertex.size) != 1 && !is.null(v)) {
    vertex.size <- vertex.size[v]
  }
  vertex.frame.color <- params("vertex", "frame.color")
  if (length(vertex.frame.color) != 1 && !is.null(v)) {
    vertex.frame.color <- vertex.frame.color[v]
  }
  vertex.frame.width <- params("vertex", "frame.width")
  if (length(vertex.frame.width) != 1 && !is.null(v)) {
    vertex.frame.width <- vertex.frame.width[v]
  }
  
  mapply(coords[,1], coords[,2], vertex.color, vertex.frame.color,
         vertex.size, vertex.frame.width,
         FUN=function(x, y, bg, fg, size, lwd) {
           symbols(x=x, y=y, bg=bg, fg=fg, lwd=lwd,
                   circles=size, add=TRUE, inches=FALSE)
         })
}

############################# custom square vertex shape ####################################

mysquare <- function(coords, v=NULL, params) {
  vertex.size  <- 1/200 * params("vertex", "size")
  if (length(vertex.size) != 1 && !is.null(v)) {
    vertex.size <- vertex.size[v]
  }
  vertex.frame.color <- params("vertex", "frame.color")
  if (length(vertex.frame.color) != 1 && !is.null(v)) {
    vertex.frame.color <- vertex.frame.color[v]
  }
  vertex.frame.width <- params("vertex", "frame.width")
  if (length(vertex.frame.width) != 1 && !is.null(v)) {
    vertex.frame.width <- vertex.frame.width[v]
  }
  vertex.color <- params("vertex", "color")
  if (length(vertex.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.color[v]
  }
  mapply(coords[,1], coords[,2], vertex.frame.width, vertex.frame.color,
         vertex.size,  vertex.color,
         FUN=function(x, y, lwd, fg, size, bg) {
           symbols(x=x, y=y, lwd=lwd, fg=fg, bg=bg,
                   squares=size*2, add=TRUE, inches=FALSE)
         })
}

############################# triangle vertex shape ####################################

mytriangle <- function(coords, v=NULL, params) {
  vertex.size <- 1/200 * params("vertex", "size")
  if (length(vertex.size) != 1 && !is.null(v)) {
    vertex.size <- vertex.size[v]
  }
  vertex.frame.color <- params("vertex", "frame.color")
  if (length(vertex.frame.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.frame.color[v]
  }
  vertex.frame.width <- params("vertex", "frame.width")
  if (length(vertex.frame.width) != 1 && !is.null(v)) {
    vertex.frame.width <- vertex.frame.width[v]
  }
  vertex.color <- params("vertex", "color")
  if (length(vertex.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.color[v]
  }
  symbols(x=coords[,1], y=coords[,2], fg=vertex.frame.color, 
          lwd=vertex.frame.width,
          bg=vertex.color,
          stars=cbind(vertex.size, vertex.size, vertex.size),
          add=TRUE, inches=FALSE)
}


############################# star vertex shape with parameter for number of vertices ####################################
mystar <- function(coords, v=NULL, params) {
  vertex.size  <- 1/200 * params("vertex", "size")
  if (length(vertex.size) != 1 && !is.null(v)) {
    vertex.size <- vertex.size[v]
  }
  norays <- params("vertex", "norays")
  if (length(norays) != 1 && !is.null(v)) {
    norays <- norays[v]
  }
  vertex.frame.color <- params("vertex", "frame.color")
  if (length(vertex.frame.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.frame.color[v]
  }
  vertex.frame.width <- params("vertex", "frame.width")
  if (length(vertex.frame.width) != 1 && !is.null(v)) {
    vertex.frame.width <- vertex.frame.width[v]
  }
  vertex.color <- params("vertex", "color")
  if (length(vertex.color) != 1 && !is.null(v)) {
    vertex.color <- vertex.color[v]
  }
  mapply(coords[,1], coords[,2], vertex.frame.color, vertex.frame.width, vertex.size, norays, vertex.color,
         FUN=function(x, y, fg, lwd, size, nor, bg) {
           symbols(x=x, y=y, 
                   fg=vertex.frame.color,
                   lwd=vertex.frame.width,
                   bg=vertex.color, 
                   stars=matrix(c(size,size/2), nrow=1, ncol=nor*2),
                   add=TRUE, inches=FALSE)
         })
}

#################################################################

# Don't forget to load the shapes

add.vertex.shape("fcircle", clip=igraph.shape.noclip,
                 plot=mycircle, parameters=list(vertex.frame.color=1,
                                                vertex.frame.width=1))

add.vertex.shape("fsquare", clip=igraph.shape.noclip,
                 plot=mysquare, parameters=list(vertex.frame.color=1,
                                                vertex.frame.width=1))
add_shape("triangle", clip=shape_noclip,
          plot=mytriangle, parameters = list(vertex.color=1,vertex.frame.color=1,vertex.frame.width=1))
#
add_shape("star", clip=shape_noclip,
          plot=mystar, parameters=list(vertex.color=1,vertex.frame.color=1,vertex.frame.width=1,vertex.norays=8)) # set number of star points!


# loading module genes...
yellow_wgcna <- read.table(paste0(resultsdir, "module_yellow.txt"))
colnames(yellow_wgcna) <- "gene"

# ...and complementary data

yellow_wgcna <- left_join(yellow_wgcna,lfcall, by = "gene")

# STRING interaction tables from Cytoscape's StringApp

yellow_string <- read.csv(file = paste0(resultsdir, "yellow_interactions.csv"), header = T, stringsAsFactors = F)
yellow_string <- mutate(yellow_string,node1 = unlist(lapply(strsplit(yellow_string$name, " \\(pp\\) "), "[[", 1)), node2 = unlist(lapply(strsplit(yellow_string$name, " \\(pp\\) "), "[[", 2)))

filteryellow <- select(yellow_string,node1,node2,experiments,databases,score) %>%
  filter(experiments >= 0.500 | (experiments >= 0.300 & databases >= 0.900))

#check if all gene names correspond
table(filteryellow$node1[which(!filteryellow$node1 %in% yellow_wgcna$gene)])
table(filteryellow$node2[which(!filteryellow$node2 %in% yellow_wgcna$gene)])

filteryellow$node2 <- gsub("DP2","TFDP2",filteryellow$node2)
filteryellow$node2 <- gsub("CCL4L1","CCL4L2",filteryellow$node2)
filteryellow <- filteryellow[-428,] # remove ENSP00000412457 which apparently did not correspond to the right gene

# now we generate the graph

gyellow <- graph_from_data_frame(d = filteryellow, vertices = yellow_wgcna, directed = F)

plot(gyellow)

E(gyellow)
V(gyellow)

#check if it is simple
is_simple(gyellow)

gyellow <- simplify(gyellow, remove.multiple = T, remove.loops = T) # should I remove loops?
gyellow <- delete.vertices(gyellow, degree(gyellow) == 0)

# all subgroups are too small!

# Identifying communities

# yellow.eigenvectors <- leading.eigenvector.community(gyellow, steps = -1, options=list(maxiter=1000000)) #based on vertex connectivity
# #/\ had to increase max number of iterations bc it was reaching its limit
# yellow.clustering <- make_clusters(gyellow, membership = yellow.eigenvectors$membership)

yellow.communities <- edge.betweenness.community(gyellow, weights=NULL, directed=FALSE) #based on edge weight
yellow.clustering <- make_clusters(gyellow, membership=yellow.communities$membership)

V(gyellow)$comp2 <- yellow.communities$membership
table(V(gyellow)$comp2)

# making lfc color ramps

scale1 <- data.frame(lfc1 = V(gyellow)$lfc1[order(V(gyellow)$lfc1, decreasing = FALSE)],
                     lfcolor1 = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(gyellow)$lfc1)),
                     stringsAsFactors = FALSE)

m1 <- scale1[match(V(gyellow)$lfc1,scale1$lfc1),]

V(gyellow)$lfcolor1 <- m1$lfcolor1 # greater correlation with yellow

scale2 <- data.frame(lfc2 = V(gyellow)$lfc2[order(V(gyellow)$lfc2, decreasing = FALSE)],
                     lfcolor2 = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(gyellow)$lfc2)),
                     stringsAsFactors = FALSE)

m2 <- scale2[match(V(gyellow)$lfc2,scale2$lfc2),]

V(gyellow)$lfcolor2 <- m2$lfcolor2


scale3 <- data.frame(lfc3 = V(gyellow)$lfc3[order(V(gyellow)$lfc3, decreasing = FALSE)],
                     lfcolor3 = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(gyellow)$lfc3)),
                     stringsAsFactors = FALSE)

m3 <- scale3[match(V(gyellow)$lfc3,scale3$lfc3),]

V(gyellow)$lfcolor3 <- m3$lfcolor3

scale4e <- data.frame(lfc4e = V(gyellow)$lfc4e[order(V(gyellow)$lfc4e, decreasing = FALSE)],
                      lfcolor4e = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(gyellow)$lfc4e)),
                      stringsAsFactors = FALSE)

m4e <- scale4e[match(V(gyellow)$lfc4e,scale4e$lfc4e),]

V(gyellow)$lfcolor4e <- m4e$lfcolor4e

scale4s <- data.frame(lfc4s = V(gyellow)$lfc4s[order(V(gyellow)$lfc4s, decreasing = FALSE)],
                      lfcolor4s = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(gyellow)$lfc4s)),
                      stringsAsFactors = FALSE)

m4s <- scale4s[match(V(gyellow)$lfc4s,scale4s$lfc4s),]

V(gyellow)$lfcolor4s <- m4s$lfcolor4s

# selecting subgraphs with at least 5 elements
subgroups <- list()
n = 1
for(i in 1:length(yellow.communities)) {
  if(length(yellow.communities[[i]]) >= 5) {
    subgroups[[n]] <-  induced_subgraph(gyellow,V(gyellow)$comp2 == i)
    subgroups[[n]] <- delete.vertices(subgroups[[n]], degree(subgroups[[n]]) == 0) # remove unconnected vertices inside subgroups
    n = n+1
  }
}

# selecting the vertices with the highest connectivity inside each subgraph
hubnames <- c()
for(i in 1:length(subgroups)) {
  index <- order(degree(subgroups[[i]]),decreasing = T)
  hubnames <- c(hubnames,names(subgroups[[i]][[which(degree(subgroups[[i]]) >= quantile(degree(subgroups[[i]]),0.9))]])) # selecting genes above 9th percentile as hubs
}

write.table(hubnames, file = paste0(resultsdir, "yellow_hubs.txt"), quote = F, col.names = F, row.names = F)

# identifying hubs inside each subgraph

for(i in 1:length(subgroups)){
  V(subgroups[[i]])$cex <- ifelse(names(V(subgroups[[i]])) %in% hubnames, 0.8, 0.7) #hubs have bigger labels
  V(subgroups[[i]])$label.dist <- ifelse(names(V(subgroups[[i]])) %in% hubnames, 1.5, 1)
  V(subgroups[[i]])$size <- ifelse(names(V(subgroups[[i]])) %in% hubnames, 12, 6) #different sizes for pie and circle vertices
}

# selecting druggable and resistance genes

dgidb_drugs_yellow <- read.table(paste0(resultsdir, "dgidb_yellow_interactions.tsv"),sep = "\t",header = T)

dgidb_categories_yellow <- read.table(paste0(resultsdir, "dgidb_yellow_categories.tsv"),sep = "\t",header = T)
druggable_yellow <- dgidb_categories_yellow %>%
  mutate(gene = search_term) %>%
  select(gene,category,sources) %>%
  filter(category == "DRUGGABLE GENOME")

druggable_families_yellow <- dgidb_categories_yellow %>%
  mutate(gene = search_term) %>%
  select(gene, category, sources) %>%
  filter(category == "SERINE THREONINE KINASE" | category == "TYROSINE KINASE" | category == "KINASE" | category == "NEUTRAL ZINC METALLOPEPTIDASE" | category == "G PROTEIN COUPLED RECEPTOR" | category == "ION CHANNEL" |category == "NUCLEAR HORMONE RECEPTOR") # druggable target categories according to literature

resistance_yellow <- dgidb_categories_yellow %>%
  mutate(gene = search_term) %>%
  select(gene,category,sources) %>%
  filter(category == "DRUG RESISTANCE")

# Selecting hubs with no drug-gene interactions

newhubs <- hubnames[which(!hubnames %in% dgidb_drugs_yellow$gene)]

write.table(newhubs, file = paste0(resultsdir, "yellow_hubs_no_dgi.txt"), quote = F, col.names = F, row.names = F)

newhubs_lfc <- lfcall[which(lfcall$gene %in% newhubs),]

# values <- list()
# for(i in 1:length(subgroups)){
#   V(subgroups[[i]])$color1 <- ifelse(names(V(subgroups[[i]])) %in% druggable_yellow$gene, "SeaGreen", ifelse(names(V(subgroups[[i]])) %in% resistance_yellow$gene, "Goldenrod", "black")) # identifying druggable or resistance genes
#   V(subgroups[[i]])$color2 <- ifelse(V(subgroups[[i]])$scale > 0, "FireBrick", "RoyalBlue")
#   colors<-c("SeaGreen","Goldenrod","FireBrick","RoyalBlue")
#   values[[i]]<-apply(cbind(V(subgroups[[i]])$color1,V(subgroups[[i]])$color2),1,function(x){
#     sapply(colors,function(y){ifelse(y %in% x,1,0)})
#   })
#   values[[i]]<-as.list(as.data.frame(values[[i]])) 
# }

# change shape of druggable and resistance genes

for(i in 1:length(subgroups)){
  V(subgroups[[i]])$shape <- "fcircle"
  V(subgroups[[i]])$shape <- ifelse(names(V(subgroups[[i]])) %in% resistance_yellow$gene, "triangle", ifelse(names(V(subgroups[[i]])) %in% druggable_yellow$gene, "star", ifelse(names(V(subgroups[[i]])) %in% druggable_families_yellow$gene, "fsquare", "fcircle"))) # setting shapes according to category
  V(subgroups[[i]])$label.color <- ifelse(names(V(subgroups[[i]])) %in% dgidb_drugs_yellow$gene, "red", "black") # changing label color for genes with known drug interactions
}

# identifying DEGs and exclusive DEGs by subtype
for(i in 1:length(subgroups)){
  V(subgroups[[i]])$frame.color1 <- ifelse(names(V(subgroups[[i]])) %in% sig1$gene, "black", "white") #DEGs have black frames
  V(subgroups[[i]])$frame.width1 <- ifelse(names(V(subgroups[[i]])) %in% sig1$gene, 3, 1) #DEGs have thick frames
  V(subgroups[[i]])$label.font1 <- ifelse(names(V(subgroups[[i]])) %in% exc1$gene, 4, 2) # exclusive DEGs have italic labels
  
  V(subgroups[[i]])$frame.color2 <- ifelse(names(V(subgroups[[i]])) %in% sig2$gene, "black", "white") #DEGs have black frames
  V(subgroups[[i]])$frame.width2 <- ifelse(names(V(subgroups[[i]])) %in% sig2$gene, 3, 1) #DEGs have thick frames
  V(subgroups[[i]])$label.font2 <- ifelse(names(V(subgroups[[i]])) %in% exc2$gene, 4, 2) # exclusive DEGs have italic labels
  
  V(subgroups[[i]])$frame.color3 <- ifelse(names(V(subgroups[[i]])) %in% sig3$gene, "black", "white") #DEGs have black frames
  V(subgroups[[i]])$frame.width3 <- ifelse(names(V(subgroups[[i]])) %in% sig3$gene, 3, 1) #DEGs have thick frames
  V(subgroups[[i]])$label.font3 <- ifelse(names(V(subgroups[[i]])) %in% exc3$gene, 4, 2) # exclusive DEGs have italic labels
  
  V(subgroups[[i]])$frame.color4e <- ifelse(names(V(subgroups[[i]])) %in% sig4e$gene, "black", "white") #DEGs have black frames
  V(subgroups[[i]])$frame.width4e <- ifelse(names(V(subgroups[[i]])) %in% sig4e$gene, 3, 1) #DEGs have thick frames
  V(subgroups[[i]])$label.font4e <- ifelse(names(V(subgroups[[i]])) %in% exc4e$gene, 4, 2) # exclusive DEGs have italic labels
  
  V(subgroups[[i]])$frame.color4s <- ifelse(names(V(subgroups[[i]])) %in% sig4s$gene, "black", "white") #DEGs have black frames
  V(subgroups[[i]])$frame.width4s <- ifelse(names(V(subgroups[[i]])) %in% sig4s$gene, 3, 1) #DEGs have thick frames
  V(subgroups[[i]])$label.font4s <- ifelse(names(V(subgroups[[i]])) %in% exc4s$gene, 4, 2) # exclusive DEGs have italic labels
}

#setting edge weight according to STRING connectivity

for(i in 1:length(subgroups)){
  E(subgroups[[i]])$width <- E(subgroups[[i]])$score*3.0
}

# setting layout

library(qgraph)

l <- list()
for(i in 1:length(subgroups)){
  e <- get.edgelist(subgroups[[i]], names = F)
  l[[i]] <- qgraph.layout.fruchtermanreingold(edgelist = e, vcount = vcount(subgroups[[i]]), area=15*(vcount(subgroups[[i]])^2),repulse.rad=(vcount(subgroups[[i]])^2.8))
}


#Output information for each community, including vertex-to-community assignments and modularity
commSummary <- data.frame(
  yellow.communities$names,
  yellow.communities$membership
  #yellow.communities$modularity
)
colnames(commSummary) <- c("Gene", "Community", "Modularity")
options(scipen=999)
commSummary


par(mfrow=c(2,length(subgroups)/2))
#pdf("~/alvoscrccms/results/WGCNA/CMS/2019-03-11/menos_modulos/Graphs/yellow_networks.pdf" )

cairo_pdf("results/yellow_networks.pdf", width = 8.27, height = 11.69, onefile = TRUE)
for(i in 1:length(subgroups)){
  layout(1:2, height=c(5,1))
  plot.igraph(subgroups[[i]], # the graph to be plotted
              main = paste0("Yellow module (component ",i,")"), # graph title
              vertex.frame.color = V(subgroups[[i]])$frame.color1, # vertex frame color
              vertex.frame.width = V(subgroups[[i]])$frame.width1, # vertex frame width
              vertex.label = V(subgroups[[i]])$label,
              vertex.label.color = V(subgroups[[i]])$label.color,
              vertex.label.dist = V(subgroups[[i]])$label.dist, # distance of vertex label from vertex
              vertex.label.degree = pi/2, # position of vertex label
              vertex.label.family = "sans", # font family for labels
              vertex.label.font = V(subgroups[[i]])$label.font1, # bold; see igraph help
              vertex.label.cex  = V(subgroups[[i]])$cex,
              vertex.color = V(subgroups[[i]])$lfcolor1, # vertex fill color
              vertex.shape = V(subgroups[[i]])$shape,
              #vertex.pie = values[[i]],
              #vertex.pie.color = list(colors),
              vertex.size = V(subgroups[[i]])$size,
              #vertex.width = 8,
              #edge.color = , # change edge color
              edge.curved = FALSE,
              edge.width = E(subgroups[[i]])$width,
              layout = l[[i]]) #change layout
  
  legend('topright',legend=c("Non-hub gene","Hub gene","Exclusive DEG","Druggable genome","Drug resistance","Druggable families"), cex = 0.8, pt.cex=c(0.75,1.5,1.5,1.5,1.5,1.5),col=c('grey','grey','black','grey','grey','grey'),
         pch=c(21,21,21,-10040,-9658,15), pt.bg='grey',pt.lwd = 2, bty = "n")
  par(mar=c(2,1,2,1))
  legend.scale(zlim = c(min(V(subgroups[[i]])$lfc1),max(V(subgroups[[i]])$lfc1)),horizontal = TRUE, col = colorRampPalette(colors = rev(brewer.pal(10,"RdYlBu")))(length(V(subgroups[[i]])$lfc1)))
}

# Precisa rodar junto
dev.off()

i=10
plot.igraph(subgroups[[i]], # the graph to be plotted
            main = paste0("Yellow module (component ",i,")"), # graph title
            vertex.frame.color = V(subgroups[[i]])$frame.color4s, # vertex frame color
            vertex.frame.width = V(subgroups[[i]])$frame.width4s, # vertex frame width
            vertex.label = V(subgroups[[i]])$label,
            vertex.label.color = V(subgroups[[i]])$label.color,
            vertex.label.dist = V(subgroups[[i]])$label.dist, # distance of vertex label from vertex
            vertex.label.degree = pi/2, # position of vertex label
            vertex.label.family = "sans", # font family for labels
            vertex.label.font = V(subgroups[[i]])$label.font4s, # bold; see igraph help
            vertex.label.cex  = V(subgroups[[i]])$cex,
            vertex.color = V(subgroups[[i]])$lfcolor4s, # vertex fill color
            vertex.shape = V(subgroups[[i]])$shape,
            #vertex.pie = values[[i]],
            #vertex.pie.color = list(colors),
            vertex.size = V(subgroups[[i]])$size,
            #vertex.width = 8,
            #edge.color = , # change edge color
            edge.curved = FALSE,
            edge.width = E(subgroups[[i]])$width,
            layout = l[[i]]) #change layout

# Sending graph data to Cytoscape for KEGG enrichment

library(RCy3)

#First contact Cytoscape (which must be running)…
cytoscapePing()

#…then send your graph
createNetworkFromIgraph(subgroups[[10]],"Yellow10")

# check number of druggable targets 
length(unique(c(names(table(druggable_families_yellow$gene)), names(table(druggable_yellow$gene)))))

# Looking at a target's pathway context using KEGG
library(org.Hs.eg.db)
library(clusterProfiler)

geneList7 <- V(subgroups[[7]])$lfc1
geneNames7 <- bitr(V(subgroups[[7]])$name, fromType = "SYMBOL", toType = "ENTREZID", OrgDb="org.Hs.eg.db") # convert gene symbols to Entrez for enrichment
names(geneList7) <- geneNames7$ENTREZID

kegg7 <- enrichKEGG(geneNames7$ENTREZID, organism = "hsa", keyType = "ncbi-geneid", pAdjustMethod = "BH", qvalueCutoff = 0.1, use_internal_data = FALSE)

kegg7read <- setReadable(kegg7, OrgDb = "org.Hs.eg.db", keyType = "ENTREZID") # make gene IDs readable (symbol)
head(kegg7read)

browseKEGG(kegg1, pathID = "hsa04062") #opens pathway in browser

# Testing with genes from all subgroups - MAKE A LOOP OF THIS LATER
geneList <- c(V(subgroups[[1]])$lfc1,V(subgroups[[2]])$lfc1,V(subgroups[[3]])$lfc1,V(subgroups[[4]])$lfc1,V(subgroups[[5]])$lfc1,V(subgroups[[6]])$lfc1,V(subgroups[[7]])$lfc1,V(subgroups[[8]])$lfc1,V(subgroups[[9]])$lfc1,V(subgroups[[10]])$lfc1,V(subgroups[[11]])$lfc1,V(subgroups[[12]])$lfc1,V(subgroups[[13]])$lfc1,V(subgroups[[14]])$lfc1)
geneNames <- bitr(c(V(subgroups[[1]])$name,V(subgroups[[2]])$name,V(subgroups[[3]])$name,V(subgroups[[4]])$name,V(subgroups[[5]])$name,V(subgroups[[6]])$name,V(subgroups[[7]])$name,V(subgroups[[8]])$name,V(subgroups[[9]])$name,V(subgroups[[10]])$name,V(subgroups[[11]])$name,V(subgroups[[12]])$name,V(subgroups[[13]])$name,V(subgroups[[14]])$name), fromType = "SYMBOL", toType = "ENTREZID", OrgDb="org.Hs.eg.db", drop = FALSE)

names(geneList) <- geneNames$ENTREZID

kegg <- enrichKEGG(geneNames$ENTREZID, organism = "hsa", keyType = "ncbi-geneid", pAdjustMethod = "BH", qvalueCutoff = 0.1, use_internal_data = FALSE)
keggread <- setReadable(kegg, OrgDb = "org.Hs.eg.db", keyType = "ENTREZID") # make gene IDs readable (symbol)

head(keggread)

#Making a pathway image highlighting enriched genes with fold change
library(pathview)

#KEGG pathway representation based on pathways enriched above
hsa04062 <- pathview(gene.data  = geneList1,
                     pathway.id = "hsa04062",
                     species    = "hsa",
                     limit      = list(gene=max(abs(geneList1)), cpd=1))

hsa04060 <- pathview(gene.data  = geneList1,
                     pathway.id = "hsa04060",
                     species    = "hsa",
                     limit      = list(gene=max(abs(geneList1)), cpd=1))

hsa04062_all <- pathview(gene.data  = geneList,
                     pathway.id = "hsa04062",
                     species    = "hsa",
                     limit      = list(gene=max(abs(geneList)), cpd=1))

hsa04060_all <- pathview(gene.data  = geneList,
                     pathway.id = "hsa04060",
                     species    = "hsa",
                     limit      = list(gene=max(abs(geneList1)), cpd=1))
