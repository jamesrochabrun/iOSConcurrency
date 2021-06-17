//
//  ItunesRemote.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Combine
import UIKit

enum ItunesGroupIdentifier: Int, CaseIterable {

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

    static let limit = 4
    var mediaType: MediaType {
        switch self {
        case .apps: return .apps(feedType: .topFree(genre: .all), limit: Self.limit)
        case .podcasts: return .podcast(feedType: .top(genre: .all), limit: Self.limit)
        case .tvShows: return .tvShows(feedType: .topTVEpisodes(genre: .all), limit: Self.limit)
        }
    }
}

extension ItunesGroupIdentifier {

    init(kind: String) throws {
        switch kind {
        case "iosSoftware": self = .apps
        case "podcast": self = .podcasts
        case "tvEpisode": self = .tvShows
        default: throw RequestError.invalidData
        }
    }
}

@MainActor
final class ItunesRemote: ObservableObject {

    private let service = ItunesClient()
    private var cancellables: Set<AnyCancellable> = []
    @Published var groups:  [ItunesSection<FeedItemViewModel>] = []

    // MARK:- Dispatch Group
    func dispatchGroups(from groupIdentifiers: [ItunesGroupIdentifier]) {
        let dispatchGroup = DispatchGroup()
        var apps, podcasts, tvShows: Feed<ItunesResources<FeedItem>>?

        for kind in groupIdentifiers {
            dispatchGroup.enter()
            service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: kind.mediaType)).sink { _ in
                dispatchGroup.leave()
            } receiveValue: { feed in
                let kind = feed.feed?.results.first?.kind ?? ""
                let itunesGroup = try! ItunesGroupIdentifier(kind: kind)
                switch itunesGroup {
                case .apps: apps = feed
                case .podcasts: podcasts = feed
                case .tvShows: tvShows = feed
                }
            }.store(in: &cancellables)
        }

        dispatchGroup.notify(queue: .main) {
            self.groups = self.identifiersFor(apps: apps, podcasts: podcasts, tvShows: tvShows)
        }
    }

    // MARK:- Async/await Group task
    @available(iOS 15, *)
    func asyncGroups(from groupIdentifiers: [ItunesGroupIdentifier]) {

        async {
            var apps, podcasts, tvShows: Feed<ItunesResources<FeedItem>>?
            try await withThrowingTaskGroup(of: Feed<ItunesResources<FeedItem>>.self, body: { group in
                for kind in groupIdentifiers {
                    group.async {
                        return try await self.service.clientFetchAsync(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: kind.mediaType))
                    }
                }
                for try await kindGroup in group {
                    let kind = kindGroup.feed?.results.first?.kind ?? ""
                    let itunesGroup = try ItunesGroupIdentifier(kind: kind)
                    switch itunesGroup {
                    case .apps: apps = kindGroup
                    case .podcasts: podcasts = kindGroup
                    case .tvShows: tvShows = kindGroup
                    }
                }
            })
            self.groups = self.identifiersFor(apps: apps, podcasts: podcasts, tvShows: tvShows)
        }
    }

    func identifiersFor(
        apps: Feed<ItunesResources<FeedItem>>?,
        podcasts: Feed<ItunesResources<FeedItem>>?,
        tvShows: Feed<ItunesResources<FeedItem>>?)
    ->  [ItunesSection<FeedItemViewModel>] {

        var finalGroups: [Feed<ItunesResources<FeedItem>>] = []
        if let apps = apps { finalGroups.append(apps) }
        if let podcats = podcasts { finalGroups.append(podcats) }
        if let tvShows = tvShows { finalGroups.append(tvShows) }
        return sections(from: finalGroups)
    }

    // MARK:- Combine
    @available(iOS 14, *)
    func getAppGroups(
        _ kinds: [ItunesGroupIdentifier]) {
        kinds.map { service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: $0.mediaType)).eraseToAnyPublisher() }
        .publisher
        .flatMap { $0 }
        .collect()
        .sink {
            dump($0)
        } receiveValue: { groups in
            self.groups = self.sections(from: groups)
        }.store(in: &cancellables)
    }

    // MARK:- Helper
    private func sections(
        from feeds: [Feed<ItunesResources<FeedItem>>])
    -> [ItunesSection<FeedItemViewModel>] {

        var sections: [ItunesSection<FeedItemViewModel>] = []
        for feed in feeds {
            let kind = feed.feed?.results.first?.kind ?? ""
            let itunesGroup = try! ItunesGroupIdentifier(kind: kind)
            let cellIdentifiers = feed.feed?.results.compactMap { FeedItemViewModel(model: $0) } ?? []
            switch itunesGroup {
            case .apps:
                sections.append(ItunesSection(sectionID: .apps, cellIDs: cellIdentifiers))
            case .podcasts:
                sections.append(ItunesSection(sectionID: .podcasts, cellIDs: cellIdentifiers))
            case .tvShows:
                sections.append(ItunesSection(sectionID: .tvShows, cellIDs: cellIdentifiers))
            }
        }
        return sections
    }
}


struct ItunesSection<Model: IdentifiableHashable>: IdentifiableHashable {
    let sectionID: ItunesGroupIdentifier
    let cellIDs: [Model]
    var id: ItunesGroupIdentifier { sectionID }
}
