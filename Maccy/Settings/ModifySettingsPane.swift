import Defaults
import SwiftUI

struct ModifySettingsPane: View {
  @Default(.modifyRules) private var rules

  @State private var selection = Set<ModifyRule.ID>()
  @State private var sample = ""

  var body: some View {
    VStack(alignment: .leading) {
      Table(rules, selection: $selection) {
        TableColumn(Text("SearchHeading", tableName: "ModifySettings")) { rule in
          PatternField(
            text: binding(rule.id, \.search),
            prompt: Text("SearchPrompt", tableName: "ModifySettings")
          )
        }
        TableColumn(Text("ModifyHeading", tableName: "ModifySettings")) { rule in
          PatternField(text: binding(rule.id, \.modify))
        }
        TableColumn(Text("ReplacementHeading", tableName: "ModifySettings")) { rule in
          TextField(text: binding(rule.id, \.replacement)) {}
        }
      }
      .onDeleteCommand {
        removeSelected()
      }

      ControlGroup {
        Button("", systemImage: "plus") {
          let rule = ModifyRule()
          rules.append(rule)
          selection = [rule.id]
        }
        Button("", systemImage: "minus") {
          removeSelected()
        }.disabled(selection.isEmpty)
      }.frame(width: 50)

      Text("ModifyRulesDescription", tableName: "ModifySettings")
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)

      Divider()
        .padding(.vertical, 4)

      Text("TestHeading", tableName: "ModifySettings")
        .font(.headline)
      TextField(text: $sample, prompt: Text("TestPrompt", tableName: "ModifySettings")) {}
      Text(ModifyRule.apply(rules, to: sample))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: 500, minHeight: 400)
    .padding()
  }

  private func binding(_ id: ModifyRule.ID, _ keyPath: WritableKeyPath<ModifyRule, String>) -> Binding<String> {
    Binding(
      get: { rules.first(where: { $0.id == id })?[keyPath: keyPath] ?? "" },
      set: { value in
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index][keyPath: keyPath] = value
      }
    )
  }

  private func removeSelected() {
    rules.removeAll { selection.contains($0.id) }
    selection.removeAll()
  }
}

private struct PatternField: View {
  @Binding var text: String
  var prompt: Text?

  var body: some View {
    let isValid = ModifyRule.isValid(text)

    TextField(text: $text, prompt: prompt) {}
      .foregroundStyle(isValid ? Color.primary : Color.red)
      .help(isValid ? Text(verbatim: "") : Text("InvalidPattern", tableName: "ModifySettings"))
  }
}

#Preview {
  ModifySettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
