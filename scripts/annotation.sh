#!/usr/bin/env bash
set -euo pipefail
#Esta parte fue modificada por Tomás

#hay que meter esto al script pero tengo que tener otro computador para comprobar que todas las modificaciones sirven. se metería algo tal que
 # ==== Verificar que Prokka esté disponible ====
		if ! command -v prokka &> /dev/null; then
		  echo "[INFO] Prokka no encontrado. Instalando..."
		  micromamba install -n qc-reads -c conda-forge -c bioconda prokka=1.14.6 --channel-priority flexible -y
		fi




# Requiere:
#   - Referencia: assembly/raw/contigs.fasta
#   - Prokka disponible en PATH
# ============================================================

# ==== Directorios y archivos ====
REF="assembly/raw/contigs.fasta"   # Ensamblaje RAW seleccionado
ANND="annotation"                  # Carpeta base de anotación
LOGD="logs"
mkdir -p "${ANND}" "${LOGD}"

# ==== Parche para el chequeo de blastp ====
export PROKKA_SKIP_BLAST_VERSION_CHECK=1


# ==== Prokka (anotación del ancestro) ====
echo "--- Ejecutando Prokka ---"
prokka "${REF}" \
  --outdir "${ANND}/anc" \
  --prefix "anc" \
  --locustag "ANC" \
  --genus "Escherichia" \
  --species "coli" \
  --strain "ANC" \
  --cpus 4 \
  --force \
  2> "${LOGD}/prokka_anc.log"

echo "[OK] Anotación completada. Revisa ${ANND}/anc (GFF, GBK, FAA, FNA, etc.)"
