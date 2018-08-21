## lofreq_pipeline_Gatk3

Para lanzar lofreq con Best Practices y Gatk 3. No generalizado, con las rutas de @laurapc. Faltan los archivos de las referencias.

El script principial es lofreqGatk3.sh. Se obtiene vcf de las variantes con sus frecuencias alelicas, el filtrado quitando las zonas pro
blematicas y el histograma de las frecuencias de las variantes. NO tiene en cuenta nada de indels.


Elaborado siguiendo Best Practices para Lofreq."https://github.com/CSB5/lofreq/blob/master/devel-doc/best-practices.txt"

El Base Recalibrator (BQSR) de Gatk necesita una lista de SNPs ya detectados. Se le puede dar una lista vacia, pero aprovechamos la BBDD
 que tenemos. Se puede utilizar el formato table. Para gatk3 hay que hacer:
sed -i "s|^|MTB_anc:|g" BBDD_260718
Y se pone HEADER como primera linea (a mano o no)
mv BBDD_260718 BBDD_260718.table
Hay que darle extension .table para que gatk3 sepa lo que es. Despues lo indexa solo

Tambien hace falta crear un sequence dictionary del genoma de referencia:
java -Xmx8g -jar /home/laura/Documentos/Programas/picard-tools-1.114/picard-tools-1.114/CreateSequenceDictionary.jar REFERENCE=MTB_ancestorII_reference.fasta OUTPUT=MTB_ancestorII_reference.dict

Al hacer bwa mem le ponemos una cabecera al .bam resultado, porque luego lo pide gatk. Lo unico con un valor serio es lo de "illumina". 
Para lo demás en este caso ponemos cualquier cosa, pero con otros usos de gatk habría que mirarlo con más cuidado por si acaso

Al genoma de referencia se le pone extension .fasta (en vez de .fas) pq si no Gatk se queja
