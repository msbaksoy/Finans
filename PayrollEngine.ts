/**
 * PayrollEngine - Türkiye 2026 Bordro Mevzuatı
 *
 * Kümülatif vergi, devreden SGK matrahı ve asgari ücret vergi istisnası
 * mantığını destekleyen profesyonel bordro hesaplama motoru.
 */

// MARK: - Types

export interface SGKCarryOver {
  amount: number;
  remainingMonths: number; // Her ay 1 azalacak, 0 olunca silinecek
}

export interface PayrollResult {
  net: number;
  gelirVergisi: number;
  damgaVergisi: number;
  sgkKesintisi: number; // SGK İşçi + İşsizlik İşçi
  kalanDevredenMatrah: SGKCarryOver[];
  yeniKumulatifMatrah: number;
  sgkIsci: number;
  issizlikIsci: number;
  asgariUcretGVIstisnasi: number;
  asgariUcretDVIstisnasi: number;
  toplamNetEleGecen: number;
}

export interface MonthlyInput {
  brut: number;
  prim: number;
}

// MARK: - Constants (2026)

const SGK_TAVANI = 297_270;
const ASGARI_UCRET_BRUT = 33_030;
const DAMGA_VERGISI_ORANI = 0.00759;
const SGK_ISCI_ORANI = 0.14;
const ISSIZLIK_ISCI_ORANI = 0.01;
const SGK_ISVEREN_ORANI = 0.155;
const ISSIZLIK_ISVEREN_ORANI = 0.02;

// Asgari ücret matrahı: 33030 × 0.85
const ASGARI_UCRET_MATRAH = 28_075.5;

// Gelir vergisi dilimleri 2026 [üst sınır, oran]
const GELIR_VERGISI_DILIMLERI: [number, number][] = [
  [190_000, 0.15],
  [400_000, 0.2],
  [1_500_000, 0.27],
  [5_300_000, 0.35],
  [Infinity, 0.4],
];

// MARK: - Helpers

function yuvarla(x: number): number {
  return Math.round(x * 100) / 100;
}

function kumulatifVergiHesapla(matrah: number): number {
  if (matrah <= 0) return 0;
  let vergi = 0;
  let kalanMatrah = matrah;
  let oncekiSinir = 0;

  for (const [ustSinir, oran] of GELIR_VERGISI_DILIMLERI) {
    const dilimGenisligi = ustSinir - oncekiSinir;
    const dilimTutari = Math.min(kalanMatrah, dilimGenisligi);
    if (dilimTutari <= 0) break;

    vergi += dilimTutari * oran;
    kalanMatrah -= dilimTutari;
    oncekiSinir = ustSinir;
    if (kalanMatrah <= 0) break;
  }
  return vergi;
}

// MARK: - PayrollEngine

export class PayrollEngine {
  private carryOverList: SGKCarryOver[] = [];
  private kumulatifVergiMatrahi = 0;

  /**
   * Tek ay hesaplama
   */
  calculateMonth(
    brut: number,
    prim: number,
    ayIndex: number
  ): PayrollResult {
    const brutArtıPrim = brut + prim;

    if (brutArtıPrim <= 0) {
      return {
        net: 0,
        gelirVergisi: 0,
        damgaVergisi: 0,
        sgkKesintisi: 0,
        kalanDevredenMatrah: [],
        yeniKumulatifMatrah: this.kumulatifVergiMatrahi,
        sgkIsci: 0,
        issizlikIsci: 0,
        asgariUcretGVIstisnasi: 0,
        asgariUcretDVIstisnasi: 0,
        toplamNetEleGecen: 0,
      };
    }

    // 1. Devreden SGK matrahı
    let totalPotentialMatrah = brutArtıPrim;
    this.carryOverList.forEach((item) => (totalPotentialMatrah += item.amount));

    const appliedMatrah = Math.min(totalPotentialMatrah, SGK_TAVANI);
    const currentMonthExcess = Math.max(0, brutArtıPrim - SGK_TAVANI);

    // Yeni devreden listesi
    const yeniListe: SGKCarryOver[] = [];
    if (currentMonthExcess > 0) {
      yeniListe.push({ amount: currentMonthExcess, remainingMonths: 2 });
    }
    for (const item of this.carryOverList) {
      const yeniAy = item.remainingMonths - 1;
      if (yeniAy > 0) {
        yeniListe.push({ amount: item.amount, remainingMonths: yeniAy });
      }
    }
    this.carryOverList = yeniListe;

    // 2. SGK kesintileri
    const sgkIsci = yuvarla(appliedMatrah * SGK_ISCI_ORANI);
    const issizlikIsci = yuvarla(appliedMatrah * ISSIZLIK_ISCI_ORANI);
    const sgkKesintisi = sgkIsci + issizlikIsci;

    // 3. Gelir vergisi matrahı
    const aylikMatrah = yuvarla(brutArtıPrim - sgkIsci - issizlikIsci);
    const kumulatifMatrahOnceki = this.kumulatifVergiMatrahi;
    this.kumulatifVergiMatrahi += aylikMatrah;
    const kumulatifMatrahBuAy = this.kumulatifVergiMatrahi;

    // 4. Kümülatif vergi
    const kumulatifVergiOnceki = kumulatifVergiHesapla(kumulatifMatrahOnceki);
    const kumulatifVergiBuAy = kumulatifVergiHesapla(
      this.kumulatifVergiMatrahi
    );
    const brutGelirVergisi = yuvarla(kumulatifVergiBuAy - kumulatifVergiOnceki);

    // 5. Asgari ücret vergi istisnası (GV)
    const oncekiAySayisi = ayIndex;
    const kumulatifAsgariMatrahOnceki =
      oncekiAySayisi * ASGARI_UCRET_MATRAH;
    const kumulatifAsgariMatrahBuAy =
      (oncekiAySayisi + 1) * ASGARI_UCRET_MATRAH;
    const asgariVergiOnceki = kumulatifVergiHesapla(
      kumulatifAsgariMatrahOnceki
    );
    const asgariVergiBuAy = kumulatifVergiHesapla(kumulatifAsgariMatrahBuAy);
    const asgariUcretGVIstisnasi = yuvarla(
      asgariVergiBuAy - asgariVergiOnceki
    );
    const netGelirVergisi = Math.max(
      0,
      yuvarla(brutGelirVergisi - asgariUcretGVIstisnasi)
    );

    // 6. Damga vergisi (asgari ücret üzeri kısımdan)
    const damgaMatrah = Math.max(0, brutArtıPrim - ASGARI_UCRET_BRUT);
    const damgaVergisi = yuvarla(damgaMatrah * DAMGA_VERGISI_ORANI);
    const asgariUcretDVIstisnasi = yuvarla(
      ASGARI_UCRET_BRUT * DAMGA_VERGISI_ORANI
    );

    // 7. Net
    const netVergiOncesi = yuvarla(
      brutArtıPrim - sgkIsci - issizlikIsci - brutGelirVergisi - damgaVergisi
    );
    const toplamNetEleGecen = yuvarla(netVergiOncesi + asgariUcretGVIstisnasi);

    return {
      net: toplamNetEleGecen,
      gelirVergisi: netGelirVergisi,
      damgaVergisi,
      sgkKesintisi,
      kalanDevredenMatrah: [...this.carryOverList],
      yeniKumulatifMatrah: kumulatifMatrahBuAy,
      sgkIsci,
      issizlikIsci,
      asgariUcretGVIstisnasi,
      asgariUcretDVIstisnasi,
      toplamNetEleGecen,
    };
  }

  /**
   * Yıllık hesaplama
   */
  calculateYear(inputs: MonthlyInput[]): PayrollResult[] {
    this.reset();
    const results: PayrollResult[] = [];
    const padded = [
      ...inputs,
      ...Array(12 - inputs.length).fill({ brut: 0, prim: 0 }),
    ].slice(0, 12) as MonthlyInput[];

    for (let i = 0; i < 12; i++) {
      const { brut, prim } = padded[i];
      results.push(this.calculateMonth(brut, prim, i));
    }
    return results;
  }

  reset(): void {
    this.carryOverList = [];
    this.kumulatifVergiMatrahi = 0;
  }
}
