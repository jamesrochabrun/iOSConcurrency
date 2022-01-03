//
//  ItunesRemote.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Combine
import UIKit

enum ItunesCategoryIdentifier: Int, CaseIterable {

    case apps
    case podcasts
    case music

    var title: String {
        switch self {
        case .apps: return "Apps From the Appstore"
        case .podcasts: return "Podcasts"
        case .music: return "Music"
        }
    }

    private static let limit = 4 // the number of results that we want from each category.
    
    var mediaType: MediaType {
        switch self {
        case .apps: return .apps(contentType: .apps, chart: .topFree, limit: Self.limit, format: .json)
        case .podcasts: return .podcasts(contentType: .episodes, chart: .top, limit: Self.limit, format: .json)
        case .music: return .music(contentType: .albums, chart: .mostPlayed, limit: Self.limit, format: .json)
        }
    }
}

@MainActor
final class ItunesRemote: ObservableObject {

    struct ItunesCategorySection: IdentifiableHashable {
        let sectionID: ItunesCategoryIdentifier
        let cellIDs: [FeedItemViewModel]
        var id: ItunesCategoryIdentifier { sectionID }
    }

    private let service = ItunesClient()
    private var cancellables: Set<AnyCancellable> = []
    @Published var itunesSections: [ItunesCategorySection] = []

    // MARK:- Dispatch Group + Combine Example
    func executeDispatchGroupsFor(identifiers: [ItunesCategoryIdentifier]) {

        let dispatchGroup = DispatchGroup()
        var sections: [ItunesCategorySection] = []
        for categoryIdentifier in identifiers {
            dispatchGroup.enter()
            service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: categoryIdentifier.mediaType)).sink { value in
                print("THE VALUE \(value)")
                dispatchGroup.leave()
            } receiveValue: { feed in
                let feedItemViewModels = feed.feed?.results.compactMap { FeedItemViewModel(model: $0) } ?? []
                sections.append(ItunesCategorySection(sectionID: categoryIdentifier, cellIDs: feedItemViewModels))
            }.store(in: &cancellables)
        }
        dispatchGroup.notify(queue: .main) {
            self.itunesSections = sections.sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
        }
    }

    // MARK:- Async/await Group task Example
    @available(iOS 15, *)
    func executeGroupTasksFor(identifiers: [ItunesCategoryIdentifier]) {
        Task.init {
            var sections: [ItunesCategorySection] = []
            do {
                try await withThrowingTaskGroup(of: ItunesCategorySection.self) { categorySection in
                    for categoryIdentifier in identifiers {
                        categorySection.addTask {
                            let itunesMediaTypePath = Itunes(mediaTypePath: categoryIdentifier.mediaType)
                            let feedItems = try await self.service.clientFetchAsync(Feed<ItunesResources<FeedItem>>.self, itunes: itunesMediaTypePath).feed?.results
                            let feedItemViewModels = feedItems?.map { FeedItemViewModel(model: $0) } ?? []
                            return ItunesCategorySection(sectionID: categoryIdentifier, cellIDs: feedItemViewModels)
                        }
                    }
                    for try await itunesCategorySection in categorySection {
                        sections.append(itunesCategorySection)
                    }
                }
            } catch {
                print("The error is \(error)")
            }
            self.itunesSections = sections.sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
        }
    }
}
