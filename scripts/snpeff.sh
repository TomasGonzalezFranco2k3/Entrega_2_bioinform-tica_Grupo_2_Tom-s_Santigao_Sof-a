#!/usr/bin/env bash
set -euo pipefail

# Requiere:
#   - Archivos de Prokka: annotation/anc/anc.gff y anc.fna
#   - VCFs filtrados: variants/{evol1,evol2}.filtered.vcf.gz
#   - SnpEff y bcftools disponibles en PATH
# ============================================================


# ==== Verificar instalación de SnpEff ====
if ! command -v snpEff &> /dev/null; then
  echo "[INFO] SnpEff no encontrado. Instalando en entorno 'qc-reads'..."
  micromamba install -n qc-reads -c bioconda snpeff -y
else
  echo "[OK] SnpEff encontrado en el entorno."
fi


# ==== Directorios y archivos ====
ANND="annotation/anc"
VARD="variants"
SNPD="snpeff"
LOGD="logs"
mkdir -p "${SNPD}/db" "${SNPD}/reports" "${LOGD}"

# ==== Config local de SnpEff ====
CONF="${SNPD}/snpEff.config"
DATA_DIR="$(pwd)/${SNPD}/db" # DATA_DIR="${SNPD}/db" se cambió porque la ruta aparecería duplicada
GENOME="ANC"  # etiqueta del genoma dentro de snpEff

# ==== Crear config y preparar archivos ====
echo "--- Preparando base local de SnpEff ---"
cat > "${CONF}" <<EOF
# Config local para SnpEff
data.dir = ${DATA_DIR}
${GENOME}.genome : ${GENOME}
EOF

mkdir -p "${DATA_DIR}/${GENOME}"
cp "${ANND}/anc.gff" "${DATA_DIR}/${GENOME}/genes.gff"
cp "${ANND}/anc.fna" "${DATA_DIR}/${GENOME}/sequences.fa"

# ==== Construir base con GFF3 ====
echo "--- Construyendo base de datos SnpEff (ignorando validaciones de CDS/proteína) ---"
snpEff build -gff3 -noCheckCds -noCheckProtein -v "${GENOME}" -c "${CONF}" \
  2> "${LOGD}/snpeff_build.log"
  
# ==== Función: anotar y extraer candidatas por muestra ====
annotate_sample () {
  local sample="$1"
  local in_vcf="${VARD}/${sample}.filtered.vcf.gz"

  echo "--- Anotando ${sample} con SnpEff ---"
  snpEff -v -c "${CONF}" "${GENOME}" "${in_vcf}" \
    > "${SNPD}/${sample}.snpeff.ann.vcf" \
    2> "${LOGD}/${sample}_snpeff.log"

  # Reporte HTML resumido (estadísticas de efectos)
  snpEff -v -c "${CONF}" -s "${SNPD}/reports/${sample}.html" "${GENOME}" "${in_vcf}" \
    > /dev/null 2>> "${LOGD}/${sample}_snpeff.log"

  echo "--- Extrayendo variantes candidatas (alto/moderado impacto) para ${sample} ---"
  # Parseo de ANN para efectos relevantes (missense, frameshift, stop_gained, etc.)
  bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t[%DP]\t[%MQ]\t%ANN\n' \
    "${SNPD}/${sample}.snpeff.ann.vcf" \
    | awk -F'\t' '
      function hasImpact(ann,   ok) {
        ok = (ann ~ /missense_variant|frameshift_variant|stop_gained|start_lost|stop_lost|splice_acceptor_variant|splice_donor_variant|inframe_insertion|inframe_deletion/)
        return ok
      }
      {
        split($8, anns, ",")
        for (i in anns) {
          if (hasImpact(anns[i])) {
            print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"anns[i]
            break
          }
        }
      }' \
    > "${SNPD}/${sample}.candidates.tsv"

  echo "[OK] ${sample}: snpEff listo → reporte HTML y ${SNPD}/${sample}.candidates.tsv"
}

# ==== Ejecutar para EVOL1 y EVOL2 ====
annotate_sample "evol1"
annotate_sample "evol2"

echo "[OK] SnpEff finalizado. Revisa ${SNPD}/reports/*.html y ${SNPD}/*.candidates.tsv"
