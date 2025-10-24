#!/usr/bin/env bash
set -euo pipefail

#	Requiere:
#   - BAMs ordenados: maps/{evol1,evol2}.sorted.bam
#   - Referencia: assembly/raw/contigs.fasta
#   - samtools y bcftools disponibles en PATH
# ============================================================

# === Activar entorno micromamba ===
eval "$(micromamba shell hook --shell bash)"
micromamba activate qc-reads


# === Verificar e instalar bcftools y samtools si faltan ===
if ! command -v bcftools &> /dev/null || ! command -v samtools &> /dev/null; then
  echo "--- Instalando bcftools y samtools en el entorno qc-reads ---"
  micromamba install -n qc-reads -c bioconda bcftools samtools -y
else
  echo "--- bcftools y samtools ya están disponibles ---"
fi


# ==== Directorios y archivos ====
REF="assembly/raw/contigs.fasta"
MAPD="maps"
VARD="variants"
LOGD="logs"
mkdir -p "${VARD}" "${LOGD}"

# ==== Indexar referencia si hace falta ====
if [ ! -f "${REF}.fai" ]; then
  echo "--- Indexando referencia (faidx) ---"
  samtools faidx "${REF}"
fi

# ==== Función: llamar y filtrar variantes por muestra ====
call_and_filter () {
  local sample="$1"
  local bam="${MAPD}/${sample}.sorted.bam"

  echo "--- mpileup + call para ${sample} ---"
  # mpileup -> call -> normalización -> compresión
  bcftools mpileup -f "${REF}" -Ou "${bam}" \
    2> "${LOGD}/${sample}_mpileup.log" | \
  bcftools call -mv -Ou \
    2> "${LOGD}/${sample}_bcf_call.log" | \
  bcftools norm -f "${REF}" -m -any -Oz \
    -o "${VARD}/${sample}.raw.norm.vcf.gz" \
    2> "${LOGD}/${sample}_norm.log"

  tabix -f "${VARD}/${sample}.raw.norm.vcf.gz"

  echo "--- Filtrado básico para ${sample} ---"
  # Umbrales sugeridos: QUAL >= 30, DP >= 10, MQ >= 30
  bcftools filter \
    -i 'QUAL>=30 && DP>=10 && MQ>=30' \
    -Oz -o "${VARD}/${sample}.filtered.vcf.gz" \
    "${VARD}/${sample}.raw.norm.vcf.gz" \
    2> "${LOGD}/${sample}_filter.log"

  tabix -f "${VARD}/${sample}.filtered.vcf.gz"

  echo "[OK] ${sample}: VCF filtrado → ${VARD}/${sample}.filtered.vcf.gz"
}

# ==== Ejecutar para EVOL1 y EVOL2 ====
call_and_filter "evol1"
call_and_filter "evol2"

echo "[OK] Llamado de variantes finalizado. Resultados en ${VARD}/"
