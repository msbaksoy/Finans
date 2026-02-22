#!/bin/bash
# Finans projesini GitHub/GitLab'a gönderme scripti
# Kullanım: ./uzaga_gonder.sh https://github.com/KULLANICI/REPO_ADI.git

set -e
cd "$(dirname "$0")"

if [ -z "$1" ]; then
  echo "Hata: Repo URL'si gerekli."
  echo ""
  echo "Kullanım: ./uzaga_gonder.sh <REPO_URL>"
  echo ""
  echo "Örnek: ./uzaga_gonder.sh https://github.com/musabaksoy/Finans.git"
  echo ""
  echo "Önce GitHub'da yeni repo oluşturun: https://github.com/new"
  exit 1
fi

REPO_URL="$1"

echo "→ Remote ekleniyor..."
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

echo "→ Main branch push ediliyor..."
git push -u origin main

echo "→ Tag'ler push ediliyor..."
git push --tags 2>/dev/null || true

echo ""
echo "✅ Tamamlandı! Projeniz uzak depoda."
