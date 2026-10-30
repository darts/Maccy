import Foundation
import Defaults

// Rewrites copied text: when `search` matches, every match of `modify`
// is replaced with `replacement`, which may reference groups as $1, $2, etc.
nonisolated struct ModifyRule: Codable, Equatable, Identifiable, Defaults.Serializable {
  var id = UUID()
  var search = ""
  var modify = ""
  var replacement = ""

  // Rules run in order, each one receiving the output of the previous one.
  static func apply(_ rules: [ModifyRule], to string: String) -> String {
    rules.reduce(string) { result, rule in rule.apply(to: result) }
  }

  static func isValid(_ pattern: String) -> Bool {
    pattern.isEmpty || (try? NSRegularExpression(pattern: pattern)) != nil
  }

  func apply(to string: String) -> String {
    // An empty pattern matches between every character, so it would
    // insert the replacement everywhere instead of doing nothing.
    guard !modify.isEmpty, let modifyRegex = try? NSRegularExpression(pattern: modify) else {
      return string
    }

    let range = NSRange(string.startIndex..., in: string)

    // An empty search applies the rule to every copy.
    if !search.isEmpty {
      guard let searchRegex = try? NSRegularExpression(pattern: search),
            searchRegex.firstMatch(in: string, range: range) != nil else {
        return string
      }
    }

    return modifyRegex.stringByReplacingMatches(in: string, range: range, withTemplate: replacement)
  }
}

nonisolated extension ModifyRule {
  // Before rules were stored as a single list, their parts were kept
  // in three parallel arrays that could get out of sync.
  static let legacySearchKey = "modifyMatchRegexp"
  static let legacyModifyKey = "modifyChangeRegexp"
  static let legacyReplacementKey = "modifyReplacementString"

  static func legacyRules(in defaults: UserDefaults) -> [ModifyRule] {
    let searches = defaults.stringArray(forKey: legacySearchKey) ?? []
    let modifies = defaults.stringArray(forKey: legacyModifyKey) ?? []
    let replacements = defaults.stringArray(forKey: legacyReplacementKey) ?? []

    // Entries without a search pattern were never applied, so they're skipped.
    return searches.indices.map { index in
      ModifyRule(
        search: searches[index],
        modify: modifies.indices.contains(index) ? modifies[index] : "",
        replacement: replacements.indices.contains(index) ? replacements[index] : ""
      )
    }
  }
}
