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
    case tvShows

    var title: String {
        switch self {
        case .apps: return "Apps From the Appstore"
        case .podcasts: return "Podcasts"
        case .tvShows: return "TV Shows"
        }
    }

    private static let limit = 4 // the number of results that we want from each category.
    var mediaType: MediaType {
        switch self {
        case .apps: return .apps(feedType: .topFree(genre: .all), limit: Self.limit)
        case .podcasts: return .podcast(feedType: .top(genre: .all), limit: Self.limit)
        case .tvShows: return .tvShows(feedType: .topTVEpisodes(genre: .all), limit: Self.limit)
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

    // MARK:- Dispatch Group
    func dispatchGroups(
        from categoryIdentifiers: [ItunesCategoryIdentifier]) {

        let dispatchGroup = DispatchGroup()
        var sections: [ItunesCategorySection] = []
        for categoryIdentifier in categoryIdentifiers {
            dispatchGroup.enter()
            service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: categoryIdentifier.mediaType)).sink { _ in
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

    // MARK:- Async/await Group task
    @available(iOS 15, *)
    func asyncGroups(
        from categoryIdentifiers: [ItunesCategoryIdentifier]) {
        async {
            var sections: [ItunesCategorySection] = []
            try await withThrowingTaskGroup(of: ItunesCategorySection.self) { categorySection in
                for categoryIdentifier in categoryIdentifiers {
                    categorySection.async {
                        let feedItemViewModels = try await self.service.clientFetchAsync(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: categoryIdentifier.mediaType)).feed?.results.map { FeedItemViewModel(model: $0) } ?? []
                        return ItunesCategorySection(sectionID: categoryIdentifier, cellIDs: feedItemViewModels)
                    }
                }
                for try await itunesCategorySection in categorySection {
                    sections.append(itunesCategorySection)
                }
            }
            self.itunesSections = sections.sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
        }
    }
}
