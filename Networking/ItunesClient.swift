//
//  ItunesClient.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Combine
import Foundation


final class ItunesClient: CombineAPI {

    let session: URLSession

    var cancellables: Set<AnyCancellable> = []
    init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }

    convenience init() {
        self.init(configuration: .default)
    }

    public func fetch<Feed: FeedProtocol>(_ feed: Feed.Type,
                                          itunes: Itunes) -> AnyPublisher<Feed, Error> {
        print("PATH: \(String(describing: itunes.request.url?.absoluteString))")
        return execute(itunes.request, decodingType: feed)
    }

    @available(iOS 15, *)
    public func clientFetchAsync<Feed: FeedProtocol>(_ feed: Feed.Type,
                                                     itunes: Itunes) async throws -> Feed  {
        print("PATH: \(String(describing: itunes.request.url?.absoluteString))")
        return try await fetchAsync(type: feed, with: itunes.request)
    }
}
