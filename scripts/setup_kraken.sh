#!/usr/bin/env bash
set -euo pipefail

# --- VARIABLES ---
# Directorio donde se guardar la base de datos de Kraken2
DB_DIR="$HOME/kraken2_db"
# URL de la base de datos minikraken2
DB_URL="https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v1_8GB_201904.tgz"
DB_FILE="minikraken2_v1_8GB_201904.tgz"

echo "--- Iniciando configuracion de Kraken2 y Krona ---"

# 1. Crear el directorio y moverse a el
echo "1. Creando directorio: ${DB_DIR}"
mkdir -p "${DB_DIR}"
cd "${DB_DIR}"
echo "   Ubicacion actual: $(pwd)"

# 2. Descargar la base de datos minikraken2 (8GB)
echo "2. Descargando la base de datos minikraken2 (esto puede tardar)..."
wget "${DB_URL}"

# 3. Descomprimir la base de datos y eliminar el archivo tar
echo "3. Descomprimiendo la base de datos..."
tar -xzf "${DB_FILE}"
rm "${DB_FILE}"

# 4. Instalar Krona (requiere que Conda esta� instalado y Bioconda configurado)
echo "4. Instalando Krona y Kraken2 usando micromamba..."
# Usamos "-y" para aceptar la instalacion automaticamente
micromamba install -c bioconda kraken2 krona -y

echo "------------------------------------------------"
echo "[OK] Configuración completada."
echo "La base de datos de minikraken2 está lista en: ${DB_DIR}"
echo "Krona ha sido instalado."
# Preparar base de taxonomía para Krona (necesario para ktImportTaxonomy)
echo "5. Preparando taxonomía de Krona (esto descargará datos del NCBI)..."

# Intentar ejecutar updateTaxonomy.sh desde el entorno 'qc-reads'.
# Usamos micromamba run para no depender de activar el env en scripts. Fijarse donde se ecnuentra este script, normalmente está en
#una ruta de instalación similar a la que se está usando acá, nótese que el comando está hecho para que corra en mis rutas

  micromamba run -n qc-reads -- $HOME/micromamba/envs/qc-reads/opt/krona/updateTaxonomy.sh


echo "   -> taxonomy preparada en:  $HOME/micromamba/envs/qc-reads/opt/krona/updateTaxonomy.sh"
