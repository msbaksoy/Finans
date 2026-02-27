import SwiftUI

@main
struct FinansApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var appTheme = AppTheme()
    @StateObject private var krediConfig = KrediConfigService.shared
    @StateObject private var mevduatConfig = MevduatConfigService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(appTheme)
                .environmentObject(krediConfig)
                .environmentObject(mevduatConfig)
                .preferredColorScheme(appTheme.colorScheme)
        }
    }
}
