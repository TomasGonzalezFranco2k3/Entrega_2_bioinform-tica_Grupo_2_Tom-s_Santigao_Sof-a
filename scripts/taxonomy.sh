#!/usr/bin/env bash
set -euo pipefail

# Requiere:
#   - Base de datos MiniKraken instalada previamente.
#     (Ver: setup_kraken_krona.sh)
#   - Kraken2 y Krona disponibles en PATH o entorno conda activo.
# ============================================================

# ==== Directorios ====
UNMAPPED="data/unmapped"
TAXD="taxonomy"
LOGD="logs"
mkdir -p "${TAXD}" "${LOGD}"

# ==== Base de datos Kraken2 ====
# Ajusta esta ruta segun donde queda instalada (desde setup/)
KRAKEN2_DB="/home/tomacyto_reloaded/kraken2_db/minikraken2_v1_8GB"

# ==== Funcion de clasificacion ====
run_kraken2 () {
  local sample="$1"
  local r1="${UNMAPPED}/${sample}_unmapped_R1.fastq.gz"
  local r2="${UNMAPPED}/${sample}_unmapped_R2.fastq.gz"

  echo "--- Ejecutando Kraken2 para ${sample} ---"
  kraken2 \
    --db "${KRAKEN2_DB}" \
    --paired --gzip-compressed \
    --report "${TAXD}/${sample}.kraken2.report.txt" \
    --output "${TAXD}/${sample}.kraken2.classifications.txt" \
    "${r1}" "${r2}" \
    2> "${LOGD}/${sample}_kraken2.log"

  echo "--- Generando visualización Krona para ${sample} ---"
  cut -f2,3 "${TAXD}/${sample}.kraken2.classifications.txt" | \
    ktImportTaxonomy - \
    -o "${TAXD}/${sample}.krona.html" \
    2> "${LOGD}/${sample}_krona.log"

  echo "[OK] ${sample}: clasificación y visualización completadas."
}

# ==== Ejecutar para EVOL1 y EVOL2 ====
run_kraken2 "evol1"
run_kraken2 "evol2"

echo "[OK] Clasificación taxonómica finalizada. Resultados en ${TAXD}/"
