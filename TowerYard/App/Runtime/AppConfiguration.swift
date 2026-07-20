import Foundation

enum AppConfiguration {
    static let appsFlyerDevKey = "dY5uTarmkUoNiD74LgaZCU"
    static let appleAppID = "6786178366"
    static let storeID = "id6786178366"
    static let expectedBundleID = "com.TowerYardbyburgess"
    static let firebaseProjectID = "tower-yard"
    static let firebaseProjectNumber = "689468608473"

    static let siteURL = URL(string: "https://toweryardskylinebuilder.com")!
    static let privacyPolicyURL = URL(string: "https://toweryardskylinebuilder.com/privacy-policy.html")!
    static let supportURL = URL(string: "https://toweryardskylinebuilder.com/support.html")!
    static let configURL = URL(string: "https://toweryardskylinebuilder.com/config.php")!

    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? expectedBundleID
    }
}
