#Forma parte de la pipeline de Lofreq
#Imprime el histograma de las frecuencias de las variantes
#Version sin necesidad de librerias externas

args=commandArgs(trailingOnly = TRUE)

muestra<-read.delim(args[1])

pdf( paste(args[2],".pdf",sep="") )

hist(muestra$ALLELE.FREQUENCY,col="lightcyan",main=args[2], xlab="Allele frequency", ylab="count",breaks = 20)

dev.off()
