//
//  IdentifiableHashable.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Foundation

/// Protocol composition with an extension to provide `Hashable` conformance to an object.
/// This is mostly for SwiftUI objects, but it can also be used in a DiffableCollection View
protocol IdentifiableHashable: Hashable & Identifiable {}
extension IdentifiableHashable {

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
