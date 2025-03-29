import Defaults
import SwiftUI

struct RemoveContentSettingsPane: View {
  @Default(.searchModifyRegexp) private var searchedModifyRegexp
  @Default(.changeModifyRegexp) private var changedModifyRegexp
  @Default(.replaceModifyRegexp) private var replacedModifiedRegexp

  @FocusState private var focus: Int?
  @State private var editModify = ""
  @State private var editRemove = ""
  @State private var editReplacement = ""
  @State private var selectionIndex = -1

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        VStack(alignment: .leading) {
          Text("SearchHeading", tableName: "RemoveContentSettingsPane")
            .font(.headline)
          List(selection: $selectionIndex) {
            ForEach(searchedModifyRegexp.indices, id: \.self) { index in
              TextField(
                "",
                text: Binding(
                  get: { searchedModifyRegexp[index] },
                  set: {
                    guard !$0.isEmpty, searchedModifyRegexp[index] != $0 else {
                      return
                    }
                    editModify = $0
                  })
              ).onSubmit {
                searchedModifyRegexp[index] = editModify
              }.focused($focus, equals: index)
            }
          }
        }

        Divider()

        VStack(alignment: .leading) {
          Text("ModifyHeading", tableName: "RemoveContentSettingsPane")
            .font(.headline)
          List(selection: $selectionIndex) {
            ForEach(changedModifyRegexp.indices, id: \.self) { index in
              TextField(
                "",
                text: Binding(
                  get: { changedModifyRegexp[index] },
                  set: {
                    guard !$0.isEmpty, changedModifyRegexp[index] != $0 else {
                      return
                    }
                    editRemove = $0
                  })
              ).onSubmit {
                changedModifyRegexp[index] = editRemove
              }.focused($focus, equals: index)
            }
          }
        }

        Divider()

        VStack(alignment: .leading) {
          Text("ReplacementHeading", tableName: "RemoveContentSettingsPane")
            .font(.headline)
          List(selection: $selectionIndex) {
            ForEach(replacedModifiedRegexp.indices, id: \.self) { index in
              TextField(
                "",
                text: Binding(
                  get: { replacedModifiedRegexp[index] },
                  set: {
                    guard replacedModifiedRegexp[index] != $0 else { return }
                    editReplacement = $0
                  })
              ).onSubmit {
                replacedModifiedRegexp[index] = editReplacement
              }.focused($focus, equals: index)
            }
          }
        }
      }

      ControlGroup {
        Button("", systemImage: "plus") {
          searchedModifyRegexp.append("^[a-zA-Z0-9]{50}$")
          changedModifyRegexp.append("^[a-zA-Z0-9]{50}$")
          replacedModifiedRegexp.append("")
          focus = searchedModifyRegexp.count - 1
        }
        Button("", systemImage: "minus") {
          searchedModifyRegexp.remove(at: selectionIndex)
          changedModifyRegexp.remove(at: selectionIndex)
          replacedModifiedRegexp.remove(at: selectionIndex)
        }
      }.frame(width: 50)

      Text("ModifyRegexpsDescription", tableName: "RemoveContentSettingsPane")
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)
    }.frame(maxWidth: 500, minHeight: 400).padding()
  }

  private func removeModify(_ index: Int?) {
    guard let index else { return }
    searchedModifyRegexp.remove(at: index)
    changedModifyRegexp.remove(at: index)
    replacedModifiedRegexp.remove(at: index)
  }
}

#Preview {
  RemoveContentSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
