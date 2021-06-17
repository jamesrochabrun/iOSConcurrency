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
    @Published var itunesSections:  [ItunesSection<FeedItemViewModel>] = []

    // MARK:- Dispatch Group
    func dispatchGroups(
        from groupIdentifiers: [ItunesGroupIdentifier]) {
        let dispatchGroup = DispatchGroup()
        var sections: [ItunesSection<FeedItemViewModel>] = []
        for groupIdentifier in groupIdentifiers {
            dispatchGroup.enter()
            service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: groupIdentifier.mediaType)).sink { _ in
                dispatchGroup.leave()
            } receiveValue: { feed in
                let feedItemViewModels = feed.feed?.results.compactMap { FeedItemViewModel(model: $0) } ?? []
                sections.append(ItunesSection(sectionID: groupIdentifier, cellIDs: feedItemViewModels))
            }.store(in: &cancellables)
        }
        dispatchGroup.notify(queue: .main) {
            self.itunesSections = sections.sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
        }
    }

    // MARK:- Async/await Group task
    @available(iOS 15, *)
    func asyncGroups(
        from groupIdentifiers: [ItunesGroupIdentifier]) {
        async {
            var sections: [ItunesSection<FeedItemViewModel>] = []
            try await withThrowingTaskGroup(of: ItunesSection<FeedItemViewModel>.self) { section in
                for groupIdentifier in groupIdentifiers {
                    section.async {
                        let feedItemViewModels = try await self.service.clientFetchAsync(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: groupIdentifier.mediaType)).feed?.results.map { FeedItemViewModel(model: $0) } ?? []
                        return ItunesSection(sectionID: groupIdentifier, cellIDs: feedItemViewModels)
                    }
                }
                for try await itunesGroup in section {
                    sections.append(itunesGroup)
                }
            }
            self.itunesSections = sections.sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
        }
    }

    // MARK:- Combine
    @available(iOS 14, *)
    func getAppGroups(
        _ groupIdentifiers: [ItunesGroupIdentifier]) {
        groupIdentifiers.map { service.fetch(Feed<ItunesResources<FeedItem>>.self, itunes: Itunes(mediaTypePath: $0.mediaType)).eraseToAnyPublisher() }
        .publisher
        .flatMap { $0 }
        .collect()
        .sink {
            dump($0)
        } receiveValue: { groups in
         //   self.groups = self.sections(from: groups)
        }.store(in: &cancellables)
    }

    // MARK:- Helper
//    private func sections(
//        from feeds: [Feed<ItunesResources<FeedItem>>])
//    -> [ItunesSection<FeedItemViewModel>] {
//
//        var sections: [ItunesSection<FeedItemViewModel>] = []
//        for feed in feeds {
//            let kind = feed.feed?.results.first?.kind ?? ""
//            let itunesGroup = try! ItunesGroupIdentifier(kind: kind)
//            let cellIdentifiers = feed.feed?.results.compactMap { FeedItemViewModel(model: $0) } ?? []
//            switch itunesGroup {
//            case .apps:
//                sections.append(ItunesSection(sectionID: .apps, cellIDs: cellIdentifiers))
//            case .podcasts:
//                sections.append(ItunesSection(sectionID: .podcasts, cellIDs: cellIdentifiers))
//            case .tvShows:
//                sections.append(ItunesSection(sectionID: .tvShows, cellIDs: cellIdentifiers))
//            }
//        }
//        return sections
//    }
}


struct ItunesSection<Model: IdentifiableHashable>: IdentifiableHashable {
    let sectionID: ItunesGroupIdentifier
    let cellIDs: [Model]
    var id: ItunesGroupIdentifier { sectionID }
}
