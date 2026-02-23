import SwiftUI

/// Reusable compact year calendar (2026-2028) — single-page, dark-friendly.
struct YearCalendarCompact: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var year: Int = 2026
    private let years = [2026, 2027, 2028]
    private let calendar = Calendar.current

    private func nationalHolidays(year: Int) -> [DateComponents] {
        return [
            DateComponents(year: year, month: 1, day: 1),
            DateComponents(year: year, month: 4, day: 23),
            DateComponents(year: year, month: 5, day: 1),
            DateComponents(year: year, month: 5, day: 19),
            DateComponents(year: year, month: 7, day: 15),
            DateComponents(year: year, month: 8, day: 30),
            DateComponents(year: year, month: 10, day: 29)
        ]
    }

    private func religiousRanges(year: Int) -> [ClosedRange<Date>] {
        func r(_ y: Int, _ m1: Int, _ d1: Int, _ m2: Int, _ d2: Int) -> ClosedRange<Date>? {
            if let s = calendar.date(from: DateComponents(year: y, month: m1, day: d1)),
               let e = calendar.date(from: DateComponents(year: y, month: m2, day: d2)) {
                return s...e
            }
            return nil
        }
        switch year {
        case 2026:
            return [r(2026,3,20,3,22), r(2026,5,27,5,30)].compactMap { $0 }
        case 2027:
            return [r(2027,3,9,3,11), r(2027,5,16,5,19)].compactMap { $0 }
        case 2028:
            return [r(2028,2,27,2,29), r(2028,5,5,5,8)].compactMap { $0 }
        default:
            return []
        }
    }

    private func isHoliday(_ date: Date) -> Bool {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        for nh in nationalHolidays(year: year) {
            if nh.year == comps.year && nh.month == comps.month && nh.day == comps.day { return true }
        }
        for range in religiousRanges(year: year) {
            if range.contains(date) { return true }
        }
        return false
    }

    private func isWeekend(_ date: Date) -> Bool {
        let wd = calendar.component(.weekday, from: date)
        return wd == 1 || wd == 7
    }
    @State private var selectedHolidayText: String? = nil
    @State private var showHolidayAlert = false

    private func holidayName(for date: Date) -> String? {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        // National fixed
        let fixed = nationalHolidays(year: year)
        for nh in fixed {
            if nh.year == comps.year && nh.month == comps.month && nh.day == comps.day {
                switch (nh.month, nh.day) {
                case (1,1): return "Yeni Yıl"
                case (4,23): return "Ulusal Egemenlik ve Çocuk Bayramı"
                case (5,1): return "Emek ve Dayanışma Günü"
                case (5,19): return "Atatürk'ü Anma, Gençlik ve Spor Bayramı"
                case (7,15): return "Demokrasi ve Millî Birlik Günü"
                case (8,30): return "Zafer Bayramı"
                case (10,29): return "Cumhuriyet Bayramı"
                default: return "Resmî Tatil"
                }
            }
        }
        // Religious ranges: determine which and which day index
        for range in religiousRanges(year: year) {
            if range.contains(date) {
                let dayIndex = calendar.dateComponents([.day], from: range.lowerBound, to: date).day ?? 0
                // Determine whether this range is Ramazan or Kurban by checking months
                let startComps = calendar.dateComponents([.month], from: range.lowerBound)
                if startComps.month == 3 || startComps.month == 2 {
                    return "Ramazan Bayramı \(dayIndex + 1). günü"
                } else {
                    return "Kurban Bayramı \(dayIndex + 1). günü"
                }
            }
        }
        return nil
    }
    var body: some View {
        ZStack {
            (appTheme.isLight ? appTheme.background : Color.black).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(year))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.red)
                        Spacer()
                        Picker("", selection: $year) {
                            ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(1...12, id: \.self) { month in
                            MonthCompact(year: year, month: month, isHoliday: isHoliday(_:), isWeekend: isWeekend(_:))
                                .environmentObject(appTheme)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
            }
        }
        .alert(isPresented: $showHolidayAlert) {
            Alert(title: Text("Tatil Bilgisi"), message: Text(selectedHolidayText ?? ""), dismissButton: .default(Text("Kapat")))
        }
    }
    }
}

private struct MonthCompact: View {
    @EnvironmentObject var appTheme: AppTheme
    let year: Int
    let month: Int
    let isHoliday: (Date) -> Bool
    let isWeekend: (Date) -> Bool
    private let cal = Calendar.current

    private var monthName: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        return df.shortMonthSymbols[month - 1]
    }
    
    private func monthNameFor(month: Int) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        return df.monthSymbols[month - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
                Text(monthName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textPrimary)
            CompactDays(year: year, month: month, isHoliday: isHoliday, isWeekend: isWeekend)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

private struct CompactDays: View {
    let year: Int
    let month: Int
    let isHoliday: (Date) -> Bool
    let isWeekend: (Date) -> Bool
    @EnvironmentObject var appTheme: AppTheme
    private let cal = Calendar.current

    var body: some View {
        let first = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let range = cal.range(of: .day, in: .month, for: first)!
        let weekdayOffset = (cal.component(.weekday, from: first) + 6) % 7

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
            ForEach(0..<weekdayOffset, id: \.self) { _ in
                Text(" ").font(.system(size: 9)).frame(minHeight: 10)
            }
            ForEach(range, id: \.self) { day in
                let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
                let holiday = isHoliday(date)
                let weekend = isWeekend(date)
                Text("\(day)")
                    .font(.system(size: 13, weight: weekend ? .bold : .regular))
                    .foregroundColor(holiday ? Color.blue : appTheme.textPrimary)
                    .padding(.vertical, 6)
                    .frame(minWidth: 28, minHeight: 28)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let name = holidayName(for: date) {
                            selectedHolidayText = "\(day) \(monthNameFor(month: month)) \(year) — \(name)"
                            showHolidayAlert = true
                        }
                    }
            }
        }
    }
}

