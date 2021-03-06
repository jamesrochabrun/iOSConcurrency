//
//  FeedItem.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Foundation

struct FeedItem: Codable {

    let artistName: String?
    let id: String
    let releaseDate: String?
    let name: String
    let kind: String
    let copyright: String?
    let artistId: String?
    let artistUrl: String?
    let artworkUrl100: String
    let genres: [Genre]
    let url: String
    
}

struct Genre: Codable {
    let genreId: String?
    let name: String?
    let url: String?
}
