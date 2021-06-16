//
//  GenericAPI.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Combine
import UIKit

protocol CombineAPI {
    var session: URLSession { get }
    func execute<T>(
        _ request: URLRequest,
        decodingType: T.Type,
        queue: DispatchQueue,
        retries: Int)
    -> AnyPublisher<T, Error> where T: Decodable

    @available(iOS 15, *)
    func fetchAsync<T: Decodable>(
          type: T.Type,
          with request: URLRequest)
    async throws -> T
}

// 2
extension CombineAPI {

    func execute<T>(_ request: URLRequest,
                    decodingType: T.Type,
                    queue: DispatchQueue = .main,
                    retries: Int = 0) -> AnyPublisher<T, Error> where T: Decodable {
        /// 3
        return session.dataTaskPublisher(for: request)
            .tryMap {
                guard let response = $0.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw RequestError.responseUnsuccessful(description: "\(String(describing: $0.response.url?.absoluteString))")
                }
                return $0.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: queue)
            .retry(retries)
            .eraseToAnyPublisher()
    }

    @available(iOS 15, *)
    func fetchAsync<T: Decodable>(
        type: T.Type,
        with request: URLRequest) async throws -> T { // 1

        // 2
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.requestFailed(description: "unvalid response")
        }
        guard httpResponse.statusCode == 200 else {
            throw RequestError.responseUnsuccessful(description: "status code \(httpResponse.statusCode)")
        }
        do {
            let decoder = JSONDecoder()
            // 3
            return try decoder.decode(type, from: data)
        } catch {
            // 4
            throw RequestError.jsonConversionFailure(description: error.localizedDescription)
        }
    }
}

