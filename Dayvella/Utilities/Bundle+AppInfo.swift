import Foundation

extension Bundle {
    var appDisplayName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !name.isEmpty {
            return name
        }
        if let name = object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
            return name
        }
        return "Dayvella"
    }

    var marketingVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var formattedVersion: String {
        let version = marketingVersion
        let build = buildNumber
        return build == version ? version : "\(version) (\(build))"
    }
}
