#!/usr/bin/Rscript
########################################################################
# Alexey Pindyurin, Anton Ivankin, September 12, 2014, DAM_count_statistics.R
#
# DESCRIPTION:
#   
#
# DATA:
#   input data is specified in the samples list file which is supplied as
#   argument to this runner script. File with samples to generate mannualy.
#
# OUTPUT:
#   
#
# VERSIONS:
#   140912: First revision!
#     
########################################################################
library(gplots)
# Declare variables
###################
workDir <- getwd()	# worked directory (WD)
outputGff <- "gff"	# output folder for gff in WD
outputWig <- "wig"	# output folder for wig in WD
outputScttr <- "scatter_plots"	# output folder for scatter plots in WD
startCol <- 7	# the number of last column in GATCs file 
gatcFile <- paste(workDir, "/GATCs.txt", sep="")	# location you GATCs file
samplesListFile <- paste(workDir, "/source.csv", sep="")	# location you file with source data
needCombine <- F	# are you need to combine some columns into one (T or F)? we recommend set the "F"; if you select "T" - edit the "combine" vector on row №78 
usePseudoCounts <- T	# are you need to add pseudo counts into source data (T or F)?
pseudoCounts <- c(1)		# the vector of pseudo counts
corrMethod <- c("pearson", "spearman")	# the vector of type correlation method - please don't change this setting
heatmapColors <- greenred(200)	# check you color into heatmap
labelHeatmap <- c("B", "C")	# the vector of heatmap label - please don't change this setting
labelAcf <- c("A_ALL", "B_MA")	# the vector of acf label - please don't change this setting
writeTemp <- F		# use this option if you need to get the intermediate files
dir.create(file.path(workDir, outputGff), showWarnings = FALSE)
dir.create(file.path(workDir, outputWig), showWarnings = FALSE)
dir.create(file.path(workDir, outputScttr), showWarnings = FALSE)

# Whether a script run earlier?
###############################
setwd(workDir)
alreadyRun <- list.files(".", "^.*Step_01.*")
if (length(alreadyRun) == 1) {
startCol <- 0
}

############################################
################ FUNCTIONS #################
############################################

# Write intermediate files function
################################### 
WriteIntermediateFiles <- function(source, output.file) {
	if (writeTemp == T) {
		write.table(source, file=output.file, sep="\t", row.names=F, col.names=T, quote=F, dec=".", append=F)
	}
}

# Pearson and spearman correlations function
############################################
PearsonAndSpearmanCorrelations <- function(dataSet, use.method, use.opt) {
  corr <- matrix(data=NA, nrow=ncol(dataSet)-7, ncol=ncol(dataSet)-7, byrow=T)
  rownames(corr) <- names(dataSet)[8:(ncol(dataSet))]
  colnames(corr) <- names(dataSet)[8:(ncol(dataSet))]
  for (j in 1:(ncol(dataSet)-7)){
     for (i in 1:(ncol(dataSet)-7)){
     corr[i,j] <- round(cor(dataSet[,7+i], dataSet[,7+j], method=use.method, use=use.opt), digits=2)
     }
  rm(i)
  }
  rm(j)
  invisible(corr)
 }

# Combine samples function
##########################
CombineSamples <- function(dataFrame) {
with(dataFrame, data.frame(DAM.1=`DAM-1.FCC4JPEACXX_L6_R1` + `DAM-1.FCC4JPEACXX_L6_R2`, DAM.2=`DAM-2.FCC4JPEACXX_L6_R1` + `DAM-2.FCC4JPEACXX_L6_R2`, LAM.1=`LAM-1.FCC4JPEACXX_L6_R1` + `LAM-1.FCC4JPEACXX_L6_R2`, LAM.2=`LAM-2.FCC4JPEACXX_L6_R1` + `LAM-2.FCC4JPEACXX_L6_R2`))
}
# Main correlations function
############################
MainCorrelations <- function(dataSet, corrMethod, labelHeatmap, use.opt="everything", suffixCSV, suffixPDF, corr.on.file, createPDF=T, counts=F) {  
for (m in corrMethod) {
	if (counts == T) {
	name <- "DATA"
	}
    corr.file <- assign(paste(m, ".cor", sep=""), as.data.frame(PearsonAndSpearmanCorrelations(dataSet, m, use.opt)))
		if (writeTemp == T) {
    	write.table(corr.file, file=paste("DF_Counts_Step_", suffixCSV, "_", name, "_", m, "_", currentDate, ".csv", sep=""), sep="\t", row.names=T, col.names=T, quote=F, dec=".", append=F)
		}
    corr.file <- as.matrix(corr.file)
    if (createPDF == T){
			for (label in labelHeatmap) {
      	options(warn=-1)
      	pdf(file=paste("DF_Counts_Step_", suffixPDF, "_", label, "_", name, "_", m, "_", currentDate, ".pdf", sep=""), width=12, height=12)
      		if (label == "B") {
        		KEY <- F
        		densityInfo <- "density"
      		} else {
				KEY <- T
        		densityInfo <- "none"
        		}
       heatmap.2(x=corr.file, col=heatmapColors, breaks=seq(from=-1, to=1, by=0.01), Rowv=T, Colv=T, dendrogram="both", trace="none", cellnote=corr.file, notecol="white", notecex = 0.5, margins=c(7,7), main=paste(m, "'s correlation coefficients and hierarchical clustering on\n", "'", corr.on.file, "'", sep=""), cex.lab=1.1, cexRow=0.6, cexCol=0.6, lmat=matrix(c(4,2,3,1), ncol=2), lwid=c(0.1, 0.9), lhei=c(0.15, 0.85), key=KEY, density.info=densityInfo)
       options(warn=0)
       dev.off()
    	}  
		}
  }
}
# ACF on data function
######################
AcfOnData <- function(dataSet, labelAcf, method, suffixPDF, ylab.val, na.data) {
for (label in labelAcf) {
    pdf(file=paste("DF_Counts_Step_", suffixPDF, "_", label, "_", name, "_", currentDate, ".pdf", sep=""), width=11.69, height=8.27)
    par(mfrow=c(3, 4))
    par(mai=c(0.7, 0.7, 0.7, 0.5))
	if (label == "A_ALL") {
		DATAs.acf <- dataSet
		descr <- "all"
    } else {
		DATAs.acf <- dataSet[dataSet$presence.ma == 1, ]
		descr <- "ma"
      }
	acf.order.list <- order(names(DATAs.acf[, 8:ncol(DATAs.acf)])) + 7
	if (method == "acf") {    
		for (i in acf.order.list) {
			if (na.data == T) {
				acf.na.data <- sum(!is.na(DATAs.acf[, i]))
			} else {
				acf.na.data <- sum(DATAs.acf[, i] != 0)
			}
			acf(DATAs.acf[, i], na.action=na.pass, main=paste(names(DATAs.acf[i]), "\n(", descr," GATCs: ", acf.na.data, "\nout of ", nrow(DATAs.acf), ")", sep=""), ylab=ylab.val)
		}
	} else {
		for (i in acf.order.list) {
			if (na.data == T) {
				acf.na.data <- sum(!is.na(DATAs.acf[, i]))
			} else {
				acf.na.data <- sum(DATAs.acf[, i] != 0)
			}
		plot(density(DATAs.acf[, i], na.rm=T), main=paste(names(DATAs.acf[i]), "\n(", descr," GATCs: ", acf.na.data, "\nout of ", nrow(DATAs.acf), ")", sep=""), ylab=ylab.val)
		}
	}		
	rm(i)
    dev.off()
  }
}

# DamID to WIG&GFF function
###########################
DamIdSeqToWigGff <- function(dataSet) {
	for (step in c(1:2)) {
		if (step == 1) {
			tag <- ""
			data.wg <- dataSet
		} else {
			tag <- ".ma"
			data.wg <- dataSet[dataSet$presence.ma == 1, ]
		}
	# Calculate WIG
  data.wg$start <- round((data.wg$start + data.wg$end)/2)
  data.wg$start <- sprintf("%d", data.wg$start)
  	for (j in 8:(ncol(data.wg))) {
			wig.file <- paste(workDir, "/", outputWig, "/", names(data.wg[j]), tag, "_", name, ".wig", sep="")
    	chrs <- unique(data.wg$chr)
    	  for (i in 1:length(unique(data.wg$chr))){
	  	    selected.chr <- data.wg[(data.wg$chr == chrs[i]), c(3, j)]
    	    selected.chr <- selected.chr[!is.na(selected.chr[, 2]), ]
	  	      if (i == 1) {
							write.table(paste("variableStep chrom=", chrs[i], sep=""), file=wig.file, sep="\t", row.names=F, col.names=F, quote=F, dec=".", append=F)
						} else {
								write.table(paste("variableStep chrom=", chrs[i], sep=""), file=wig.file, sep="\t", row.names=F, col.names=F, quote=F, dec=".", append=T)
						}
					write.table(selected.chr, file=wig.file, sep=" ", row.names=F, col.names=F, quote=F, dec=".", append=T)
    	  }
		}
	rm(j, i)		
	# Calculate GFF
		for (j in 8:(ncol(data.wg))) {
			selected.set <- data.wg[, c(1:7, j)];
  	  selected.set <- cbind(selected.set, NA);
  	  selected.set[, 2] <- paste("chr", selected.set[, 2], sep="");
  	  selected.set <- selected.set[, c(2, 7, 5, 3, 4, 8, 7, 9, 1)];
  	  selected.set[, 2] <- ".";
  	  selected.set[, 3] <- paste(names(data.wg)[j], tag, sep="");
  	  selected.set[, 7] <- ".";
  	  selected.set[, 8] <- ".";
  	  selected.set <- selected.set[!is.na(selected.set[, 6]), ];
  	  gff.file <- paste(workDir, "/", outputGff, "/", names(dataSet)[j], tag, "_", name, ".gff", sep="");
  	  write.table(selected.set, file=gff.file, sep="\t", row.names=F, col.names=F, quote=F, dec=".", append=F);
		}
	rm(j)
	}
}
# Scatter Plots on Averaged data function
#########################################
ScatterPlottingOnAveraged <- function(dataSet) {
  for (j in 8:(ncol(dataSet))){
  	for (i in 8:(ncol(dataSet))){
  		if (j != i) {
			  bmp(filename=paste(paste(workDir, "/", outputScttr, "/", sep=""), "scatter_", j, "_vs_", i, "_", name, ".bmp", sep=""), width=600, height=600, units = "px")
				Cor.P <- round(cor(dataSet[, j], dataSet[, i], method="pearson", use="pairwise.complete.obs"), digits=2)
				Cor.S <- round(cor(dataSet[, j], dataSet[, i], method="spearman", use="pairwise.complete.obs"), digits=2)
				plot(x=dataSet[, j], y=dataSet[, i], cex=0.3, xlab=names(dataSet[j]), ylab=names(dataSet[i]), text(x=min(dataSet[, j], na.rm=T) + 0.5, y=max(dataSet[, i], na.rm=T) - 0.5, labels=c(paste("r = ", Cor.P, "\n\n", sep=""), paste("s = ", Cor.S, sep=""))))
     		rm(Cor.P)
     		rm(Cor.S)
     		dev.off()
     	}
		}
	}
}
#######################################
################# END #################
#######################################

# Load GATC counts in data frame
################################
if (startCol == 0) {
    step01 <- read.delim(alreadyRun, header=T, as.is=T, dec=".")
    startCol <- ncol(step01)
    gatcs <- step01
    } else {
        gatcs <- read.delim(gatcFile, header=T, as.is=T, dec=".")
      }
  samplesList <- read.delim(file=samplesListFile, header=T, dec=".", stringsAsFactors=F, as.is=T)
  gatcs <- cbind(gatcs, matrix(data=NA, nrow=nrow(gatcs), ncol=nrow(samplesList)))
    for (i in 1:nrow(samplesList)){
    colnames(gatcs)[startCol+i] <- samplesList$id[i]
    load(file=samplesList$path[i])
    if (all(gatcs$ID.il == reads2GATC$ID)) gatcs[, startCol + i] <- reads2GATC$count
    }
  rm(i)
  currentDate <- format(Sys.time(), "%d-%m-%Y")
  load.gatc.df <- paste("DF_Counts_Step_01_Raw_Counts_", currentDate, ".csv", sep="")
	WriteIntermediateFiles(source=gatcs, output.file=load.gatc.df)

# Remove unimportant data
#########################
  DATA <- gatcs[!(gatcs$chr %in% c("U", "M", "Uextra" )), ]
  use.chr.only <- paste("DF_Counts_Step_02_Useful_Chrs_Only_", currentDate, ".csv", sep="")
	WriteIntermediateFiles(source=DATA, output.file=use.chr.only)

# Combine data into one
#######################
if (needCombine == T) {
DATA <- cbind(DATA[,1:7], CombineSamples(DATA))
opt.sum.samples <- paste("DF_Counts_Step_03_Summed_Samples_", currentDate, ".csv", sep="")
WriteIntermediateFiles(source=DATA, output.file=opt.sum.samples)
}

# Counts statistics
###################
  chrs <- unique(DATA$chr)
  DATA.only <- DATA[, 8:ncol(DATA)]
  stat <- as.data.frame(matrix(data=NA, nrow=length(chrs), ncol=ncol(DATA.only)+4, byrow=F, dimnames=NULL))
  names(stat) <- c("chr", "GATCs.number", "chr.length.bp", "chr.length.proportion", colnames(DATA.only)[1:(ncol(DATA.only))])
  stat$chr <- chrs
  stat$chr.length.bp <- c(23011544, 21146708, 24543557, 27905053, 1351857, 22422827, 368872, 3288761, 2555491, 2517507, 204112, 347038)
  genome.length <- sum(stat$chr.length.bp)
  stat$chr.length.proportion <- round(100 * stat$chr.length.bp / genome.length, digits=2)
  for (j in 1:(ncol(DATA.only))){
     for (i in 1:length(chrs)){
        Data.only.chr <- DATA.only[(DATA$chr == chrs[i]), j]
        if (j == 1) stat$GATCs.number[i] <- length(Data.only.chr)
        stat[i, 4+j] <- sum(Data.only.chr)
        rm(Data.only.chr)
     }
     rm(i)
  }
  rm(j)
  statistics.a <- paste("DF_Counts_Step_04_Statistics_A_", currentDate, ".csv", sep="")
	WriteIntermediateFiles(source=stat, output.file=statistics.a)
  for (j in 1:(ncol(DATA.only))){
     totalCounts <- sum(stat[, 4+j])
     for (i in 1:length(chrs)){
        stat[i, 4+j] <- round(100 * stat[i, 4+j] / totalCounts, digits=2)
     }
     rm(i)
     rm(totalCounts)
  }
  rm(j)
  statistics.b <- paste("DF_Counts_Step_04_Statistics_B_", currentDate, ".csv", sep="")
	WriteIntermediateFiles(source=stat, output.file=statistics.b)

# Add Pseudo counts
###################
 DATAs <- list(DATA=DATA)
if (usePseudoCounts == T) {
 for ( i in pseudoCounts) {
  num <- sub("^([0-1]*)(.?)([0-1]*$)", "\\1\\3", i)
  DATA.pseudo <- assign(paste("pseudo", num, sep=""), DATA)
  DATA.pseudo[, 8:ncol(DATA.pseudo)] <- DATA[, 8:ncol(DATA)] + i
  pseudo.filename <- assign(paste("pseudo.fn", num, sep=""), paste("DF_Counts_Step_05_Pseudo_", num, "_Added_", currentDate, ".csv", sep=""))
  DATA.pseudo.strname <- assign(paste("pseudo", num, sep=""), paste("pseudo", num, sep=""))
	WriteIntermediateFiles(source=DATA.pseudo, output.file=pseudo.filename)
  DATAs[[DATA.pseudo.strname]] <- DATA.pseudo
 }
rm(i)
 }

# Correlation on Counts
#######################
MainCorrelations(dataSet=DATA, corrMethod=corrMethod, suffixCSV="07a_On_Counts", createPDF=F, counts=T)

#################################
# Run many functions from Step_06
#################################

# Declare variables and load library
DATAs.rpm <- DATAs
DATAs.norm <- DATAs
DATAs.norm.ave <- DATAs
####################################

for (name in names(DATAs.rpm)) {

# Calculation reads per million
###############################
  for (i in 8:(ncol(DATAs.rpm[[name]]))){
    column.sum <- sum(DATAs.rpm[[name]][, i])
    DATAs.rpm[[name]][, i] <- DATAs.rpm[[name]][, i] / column.sum * 10^6
    rm(column.sum)
  }
  rm(i)
  calc.rpm.file <- paste("DF_Counts_Step_06_RPMs_", name, "_", currentDate, ".csv", sep="")
	WriteIntermediateFiles(source=DATAs.rpm[[name]], output.file=calc.rpm.file)

# Correlation on Channels
#########################
MainCorrelations(dataSet=DATAs.rpm[[name]], corrMethod=corrMethod, labelHeatmap=labelHeatmap, suffixCSV="07b_On_Channels_A", suffixPDF="07b_On_Channels", corr.on.file=calc.rpm.file, createPDF=T)

# ACF plots for all GATC fragments
##################################
AcfOnData(dataSet=DATAs.rpm[[name]], labelAcf=labelAcf, method="acf", suffixPDF="08_ACF_Channels", ylab.val="ACF on seq counts", na.data=F)

# Plot boxplots on channels
###########################
  bmp(filename=paste("DF_Counts_Step_09_Boxplot_Channels_", name, "_", currentDate, ".bmp", sep=""), width=2000, height=1000, units="px")
  par(mar=c(12, 8, 0.5, 0.5))
  boxplot(DATAs.rpm[[name]][, 8:(ncol(DATAs.rpm[[name]]))], names=colnames(DATAs.rpm[[name]])[8:(ncol(DATAs.rpm[[name]]))], las=2, ylab="RPM")
  dev.off()

# DAM Normalization
###################
DATAs.norm[[name]] <- DATAs.norm[[name]][, -c(8:ncol(DATAs.norm[[name]]))]
listNorm <- samplesList[1:5]
listNorm$normalization <- paste(listNorm$tissue, listNorm$conditions, listNorm$replicate, sep="")
uniqueSamples <- unique(listNorm$normalization)
  for (sample in uniqueSamples) {
    tissue.id <- subset(subset(listNorm, normalization == sample), protein != "DAM")$id
    dam.id <- subset(subset(listNorm, normalization == sample), protein == "DAM")$id
    for (protein in tissue.id) {
      tissue.norm <- paste(protein, ".norm", sep="")
      DATAs.norm[[name]][[tissue.norm]] <- log2(DATAs.rpm[[name]][[protein]] / DATAs.rpm[[name]][[dam.id]])
    }
  }
  for (i in 8:(ncol(DATAs.norm[[name]]))){
    nan.index <- is.nan(DATAs.norm[[name]][, i])
    inf.index <- is.infinite(DATAs.norm[[name]][, i])
    DATAs.norm[[name]][nan.index, i] <- NA
    DATAs.norm[[name]][inf.index, i] <- NA
    rm(nan.index)
    rm(inf.index)
  }
  rm(i)
dam.norm <- assign(paste("dam.norm", name, sep="."), paste("DF_Counts_Step_10_Dam_norm_", name, "_", currentDate, ".csv", sep=""))
WriteIntermediateFiles(source=DATAs.norm[[name]], output.file=dam.norm)
} 
############################
# Stop counting from Step_06
############################
rm(name)

#################################
# Run many functions from Step_10
#################################

for (name in names(DATAs.norm)) {
# Correlation on NormData
#########################
MainCorrelations(dataSet=DATAs.norm[[name]], corrMethod=corrMethod, labelHeatmap=labelHeatmap, use.opt="pairwise.complete.obs", suffixCSV="11_On_Normalized_A", suffixPDF="11_On_Normalized", corr.on.file=dam.norm, createPDF=T)

# Averaging Replicates !!!!! Only for two replicates !!!!!
######################
DATAs.norm.ave[[name]] <- DATAs.norm.ave[[name]][, -c(8:ncol(DATAs.norm.ave[[name]]))]
listNormAve <- listNorm[!(listNorm$protein == "DAM"), ]  # remove row's with DAM
listNormAve$normalizationAve <- paste(listNormAve$tissue, listNormAve$protein, listNormAve$conditions, sep=".")
uniqueAveSamples <- unique(listNormAve$normalizationAve)
	for (item in uniqueAveSamples) {
		item.norm.ave <- paste(item, ".norm.ave", sep="")
		first.item.id <- paste(subset(subset(listNormAve, normalizationAve == item), replicate == 1)$id, ".norm", sep="")
    second.item.id <- paste(subset(subset(listNormAve, normalizationAve == item), replicate != 1)$id, ".norm", sep="")
		DATAs.norm.ave[[name]][[item.norm.ave]] <- (DATAs.norm[[name]][[first.item.id]] + DATAs.norm[[name]][[second.item.id]]) / 2
	}
dam.norm.ave <- assign(paste("dam.norm.ave", name, sep="."), paste("DF_Counts_Step_12_Averaged_", name, "_", currentDate, ".csv", sep=""))
WriteIntermediateFiles(source=DATAs.norm.ave[[name]], output.file=dam.norm.ave)

# Correlations on Averaged NormData
###################################
MainCorrelations(dataSet=DATAs.norm.ave[[name]], corrMethod=corrMethod, labelHeatmap=labelHeatmap, use.opt="pairwise.complete.obs", suffixCSV="13_On_Averaged_A", suffixPDF="13_On_Averaged", corr.on.file=dam.norm.ave, createPDF=T)

# ACF plots on Averaged
#######################
AcfOnData(dataSet=DATAs.norm.ave[[name]], labelAcf=labelAcf, method="acf", suffixPDF="14_ACF_Averaged", ylab.val="ACF on rpms", na.data=T)

# Density on Averaged
#######################
AcfOnData(dataSet=DATAs.norm.ave[[name]], labelAcf=labelAcf, method="density", suffixPDF="15_Density_Averaged", ylab.val="density", na.data=T)

# Create WIG & GFF on Averaged data
###################################
DamIdSeqToWigGff(dataSet=DATAs.norm.ave[[name]])

# Scatter Plots on Averaged data
################################
ScatterPlottingOnAveraged(dataSet=DATAs.norm.ave[[name]])
}
print("Congratulations!!!")


