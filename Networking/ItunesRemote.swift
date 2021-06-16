//
//  ItunesRemote.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Combine
import UIKit

enum ItunesGroup: String, CaseIterable {

    case apps = "Apps From the Appstore"
    case podcats = "Podcasts"
    case tvShows = "TV Shows"

    static let limit = 4
    var mediaType: MediaType {
        switch self {
        case .apps: return .apps(feedType: .topFree(genre: .all), limit: Self.limit)
        case .podcats: return .podcast(feedType: .top(genre: .all), limit: Self.limit)
        case .tvShows: return .tvShows(feedType: .topTVEpisodes(genre: .all), limit: Self.limit)
        }
    }
}

@MainActor
final class ItunesRemote: ObservableObject {

    private let service = ItunesClient()
    private var cancellables: Set<AnyCancellable> = []
    @Published var groups: [GenericSectionIdentifierViewModel<ItunesGroup, FeedItemViewModel>] = []

    // MARK:- Dispatch Group
    func useDispatchGroup() {
        var finalGroups: [Feed<ItunesResources<FeedItem>>] = []
        let dispatchGroup = DispatchGroup()

        var apps: Feed<ItunesResources<FeedItem>>?
        var podcats: Feed<ItunesResources<FeedItem>>?
        var tvShows: Feed<ItunesResources<FeedItem>>?

        dispatchGroup.enter()
        service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: ItunesGroup.apps.mediaType)).sink { value in
            dispatchGroup.leave()
        } receiveValue: { feed in
            apps = feed
        }.store(in: &cancellables)

        dispatchGroup.enter()
        service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: ItunesGroup.podcats.mediaType)).sink { _ in
            dispatchGroup.leave()
        } receiveValue: { feed in
            podcats = feed
        }.store(in: &cancellables)

        dispatchGroup.enter()
        service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: ItunesGroup.tvShows.mediaType)).sink { _ in
            dispatchGroup.leave()
        } receiveValue: { feed in
            tvShows = feed
        }.store(in: &cancellables)

        dispatchGroup.notify(queue: .main) {
            if let apps = apps { finalGroups.append(apps) }
            if let podcats = podcats { finalGroups.append(podcats) }
            if let tvShows = tvShows { finalGroups.append(tvShows) }
            self.groups = self.genericSectionIdentifierViewModels(from: finalGroups)
        }
    }

    /// Async/await Group task
    @available(iOS 15, *)
    func genericGetGroups(_ kinds: [ItunesGroup]) {
        async {
            var finalGroups: [Feed<ItunesResources<FeedItem>>] = []
            try await withThrowingTaskGroup(of: Feed<ItunesResources<FeedItem>>.self, body: { group in
                for kind in kinds {
                    group.async {
                        return try await self.service.clientFetchAsync(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: kind.mediaType))
                    }
                }
                for try await kindGroup in group {
                    finalGroups.append(kindGroup)
                }
            })
            self.groups = genericSectionIdentifierViewModels(from: finalGroups)
        }
    }

    /// Combine
    @available(iOS 14, *)
    func getAppGroups(
        _ kinds: [ItunesGroup]) {
        kinds.map { service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: $0.mediaType)).eraseToAnyPublisher() }
        .publisher
        .flatMap { $0 }
        .collect()
        .sink {
            dump($0)
        } receiveValue: { groups in
            self.groups = self.genericSectionIdentifierViewModels(from: groups)
        }.store(in: &cancellables)
    }

    // MARK:- Helper
    private func genericSectionIdentifierViewModels(
        from groups: [Feed<ItunesResources<FeedItem>>])
    -> [GenericSectionIdentifierViewModel<ItunesGroup, FeedItemViewModel>] {

        var finalGroups: [GenericSectionIdentifierViewModel<ItunesGroup, FeedItemViewModel>] = []
        for i in 0..<groups.count {
            let sectionIdentifier = ItunesGroup.allCases[i]
            // TODO: optimize this nested loop currently O notation is (groups * results)
            let cellIdentifiers = groups[i].feed?.results.compactMap { FeedItemViewModel(model: $0) } ?? []
            let section = GenericSectionIdentifierViewModel(sectionIdentifier: sectionIdentifier, cellIdentifiers: cellIdentifiers)
            finalGroups.append(section)
        }
        return finalGroups
    }


}
