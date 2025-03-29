//
//  RemoveContentSettingsPane.swift
//  Maccy
//
//  Created by Senán d'Art on 26.03.25.
//  Copyright © 2025 p0deje. All rights reserved.
//
import SwiftUI
import Defaults

struct RemoveContentSettingsPane: View {
    @Default(.modifyMatchRegexp) private var matchedModifyRegexp
    @Default(.modifyChangeRegexp) private var matchedRemoveRegexp
    @Default(.modifyReplacementString) private var modifyReplacementString

    @FocusState private var focus: Int?
  @State private var editModify = ""
  @State private var editRemove = ""
  @State private var editReplacement = ""
  @State private var selectionIndex = -1

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        // Column for Modify Regex
        VStack(alignment: .leading) {
          Text("Modify Regex")
            .font(.headline)
            List(selection: $selectionIndex) {
              ForEach(matchedModifyRegexp.indices, id: \ .self) { index in
              TextField("", text: Binding(
                get: { matchedModifyRegexp[index] },
                set: {
                  guard !$0.isEmpty, matchedModifyRegexp[index] != $0 else { return }
                  editModify = $0
                })
              ).onSubmit {
                  matchedModifyRegexp[index] = editModify
              }.focused($focus, equals: index)
            }
          }
        }
        
        Divider()
        
        // Column for Remove Regex
        VStack(alignment: .leading) {
          Text("Remove Regex")
            .font(.headline)
            List(selection: $selectionIndex) {
                ForEach(matchedRemoveRegexp.indices, id: \ .self) { index in
              TextField("", text: Binding(
                get: { matchedRemoveRegexp[index] },
                set: {
                  guard !$0.isEmpty, matchedRemoveRegexp[index] != $0 else { return }
                  editRemove = $0
                })
              ).onSubmit {
                matchedRemoveRegexp[index] = editRemove
              }.focused($focus, equals: index)
            }
          }
        }
          
          Divider()
          
          // Column for Remove Regex
          VStack(alignment: .leading) {
            Text("Replacement String")
              .font(.headline)
              List(selection: $selectionIndex) {
                  ForEach(modifyReplacementString.indices, id: \ .self) { index in
                TextField("", text: Binding(
                  get: { modifyReplacementString[index] },
                  set: {
                    guard modifyReplacementString[index] != $0 else { return }
                      editReplacement = $0
                  })
                ).onSubmit {
                    modifyReplacementString[index] = editReplacement
                }.focused($focus, equals: index)
              }
            }
          }
      }
      
      ControlGroup {
        Button("", systemImage: "plus") {
          matchedModifyRegexp.append("^[a-zA-Z0-9]{50}$")
          matchedRemoveRegexp.append("^[a-zA-Z0-9]{50}$")
          modifyReplacementString.append("")
          focus = matchedModifyRegexp.count - 1
        }
        Button("", systemImage: "minus") {
            matchedModifyRegexp.remove(at: selectionIndex)
            matchedRemoveRegexp.remove(at: selectionIndex)
            modifyReplacementString.remove(at: selectionIndex)
        }
      }.frame(width: 50)
      
      Text("IgnoredRegexpsDescription", tableName: "IgnoreSettings")
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)
    }.frame(maxWidth: 500, minHeight: 400).padding()
  }
  
  private func removeModify(_ index: Int?) {
    guard let index else { return }
    matchedModifyRegexp.remove(at: index)
    matchedRemoveRegexp.remove(at: index)
    modifyReplacementString.remove(at: index)
  }
}

#Preview {
  RemoveContentSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
