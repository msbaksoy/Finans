# Git Kullanım Kılavuzu — Finans Projesi

## Versiyon alma (commit)

Büyük değişiklikten **önce** çalıştır:

```bash
git add .
git commit -m "Önce: [ne yapacağını kısaca yaz]"
```

## Önceki versiyona dönme

**Son commit'i geri al (değişiklikleri sil):**
```bash
git reset --hard HEAD~1
```

**Belirli bir versiyona dön (örn. v1.0):**
```bash
git checkout v1.0
# veya
git reset --hard v1.0
```

**Geçmişe bak:**
```bash
git log --oneline
```

## Mevcut tag

- `v1.0` — Stabil sürüm (CV çok sayfa, dinamik özet bölme)
