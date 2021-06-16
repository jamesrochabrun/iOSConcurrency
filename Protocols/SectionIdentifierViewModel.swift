//
//  SectionIdentifierViewModel.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Foundation

protocol SectionIdentifierViewModel: AnyObject, IdentifiableHashable {

    associatedtype SectionIdentifier: Hashable
    associatedtype CellIdentifier: Hashable

    var sectionIdentifier: SectionIdentifier { get }
    var cellIdentifiers: [CellIdentifier] { get }
}

extension SectionIdentifierViewModel {
    var id: SectionIdentifier { sectionIdentifier }
}
