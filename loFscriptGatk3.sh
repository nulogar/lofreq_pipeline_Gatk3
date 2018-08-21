#!/bin/bash
#Lanzar desde el directorio donde queramos los resultados
#Para lanzar lofreq con TB. Se podría utilizar para otro organismo cambiando el genoma de referencia y la BBDD de SNPs ya conocidos
#Utilizando Best Practices de lofreq y con Gatk v3 y demas software en @laurapc a agosto de 2018. Rutas sin generalizar, ajustadas a @laurapc.
#Se esta utilizando java 7.
#Tiene que estar el archivo de la BBDD de SNPs alguna vez detectados en formato table
#El genoma de referencia, aparte de indexado para bwa etc, debe de tener creado un .dict para gatk (diccionario)
#Manejamos los argumentos de entrada
while getopts 1:2:n: option
do
        case "${option}"
        in
                1) FQ1=${OPTARG};;    #fastq (o .gz) forward                               
		2) FQ2=${OPTARG};;     #fastq (o .gz) reverse            
		n) nombre=${OPTARG};;  #Identificador
		\?) exit 1;;
		:) exit 1;;
        esac
done

if [[ -z "$FQ1" || -z "$FQ2" || -z "$nombre" ]];
then
	echo "Compulsory argument (-1, -2, -n) needed!"	
	exit 2
fi 

bwa mem -R'@RG\tID:'$nombre'\tSM:'$nombre'\tPL:illumina\tLB:bar\tPU:foo' -t 8 /home/laura/Documentos/referencias/ancestorII/MTB_ancestorII_reference.fas "$FQ1" "$FQ2" > "$nombre".sam
#Lo de -R es para ponerle un read group en la cabecera que pide GATK. Para salir del paso

java -Xmx8g -jar /home/laura/Documentos/Programas/picard-tools-1.114/picard-tools-1.114/FixMateInformation.jar I=$nombre.sam  O=$nombre.fixed.sam

java -Xmx8g -jar /home/laura/Documentos/Programas/picard-tools-1.114/picard-tools-1.114/CleanSam.jar I=$nombre.fixed.sam  O=$nombre.fixed.cleaned.sam

samtools sort $nombre.fixed.cleaned.sam -o $nombre.fixed.cleaned.sorted.bam

~/Documentos/Programas/lofreq_star-2.1.3.1/bin/lofreq viterbi --verbose -f /home/laura/Documentos/referencias/ancestorII/MTB_ancestorII_reference.fas $nombre.fixed.cleaned.sorted.bam  | samtools sort > $nombre.viterbi.sorted.bam

java -Xmx8g -jar /home/laura/Documentos/Programas/picard-tools-1.114/picard-tools-1.114/MarkDuplicates.jar INPUT=$nombre.viterbi.sorted.bam OUTPUT=$nombre.MarkDup.bam METRICS_FILE=$nombre.metrics.txt

samtools index $nombre.MarkDup.bam

java -Xmx8g -jar ~/Documentos/Programas/GenomeAnalysisTK-3.5/GenomeAnalysisTK.jar -T LeftAlignIndels -R /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/MTB_ancestorII_reference.fasta -I $nombre.MarkDup.bam -o $nombre.LeftAlign.bam

java -Xmx8g -jar ~/Documentos/Programas/GenomeAnalysisTK-3.5/GenomeAnalysisTK.jar -T BaseRecalibrator -R /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/MTB_ancestorII_reference.fasta -I $nombre.LeftAlign.bam -o $nombre.recal_data.table -knownSites:TABLE /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/BBDD_260718

java -Xmx8g -jar ~/Documentos/Programas/GenomeAnalysisTK-3.5/GenomeAnalysisTK.jar -T PrintReads -R /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/MTB_ancestorII_reference.fasta -I $nombre.LeftAlign.bam -BQSR $nombre.recal_data.table -o $nombre.BQSR.bam

~/Documentos/Programas/lofreq_star-2.1.3.1/bin/lofreq call -f /home/laura/Documentos/referencias/ancestorII/MTB_ancestorII_reference.fas -o $nombre.lofreq.vcf $nombre.BQSR.bam

python /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/filtrarZonasVCF.py $nombre.lofreq.vcf $nombre.lofreq.vcf.filtrado

sed 's/;/\t/g' $nombre.lofreq.vcf.filtrado > $nombre.lofreq.vcf.filtrado.tsv
sed -i 's/AF=//g' $nombre.lofreq.vcf.filtrado.tsv

sed -i '1i CHROM	POS	ID	REF	ALT	QUAL	FILTER	DEPTH	ALLELE FREQUENCY	SB	DP4' $nombre.lofreq.vcf.filtrado.tsv

Rscript --vanilla /home/laura/Documentos/Programas/scriptsNuria/LofreqGatk3/histogramLofreqRaw.R $nombre.lofreq.vcf.filtrado.tsv $nombre

#Borrar archivos intermedios. Si se quieren conservar comentar la siguiente linea
rm *sam *sorted* *MarkDup* *txt *LeftAlign* *table


