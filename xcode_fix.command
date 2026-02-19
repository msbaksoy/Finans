#!/bin/bash
# Developer Disk Image hatasını düzeltmek için script
# Bu scripti çift tıklayarak çalıştırın - şifre isteyecektir

echo "=========================================="
echo "Xcode Developer Disk Image Düzeltmesi"
echo "=========================================="
echo ""

echo "1. Developer disk images önbelleği temizleniyor..."
rm -rf ~/Library/Developer/DeveloperDiskImages/
echo "   Tamamlandı."
echo ""

echo "2. Xcode sistem kaynakları yeniden yükleniyor..."
echo "   (Mac şifreniz istenecek)"
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "İşlem tamamlandı!"
    echo "=========================================="
    echo ""
    echo "Şimdi:"
    echo "1. iPhone'u USB'den çıkarıp tekrar takın"
    echo "2. Xcode'u kapatıp yeniden açın"
    echo "3. Projeyi iPhone'a tekrar yüklemeyi deneyin"
    echo ""
else
    echo ""
    echo "Hata oluştu. Xcode'u App Store üzerinden güncellemeyi deneyin."
    echo ""
fi

echo "Bu pencereyi kapatmak için bir tuşa basın..."
read -n 1
