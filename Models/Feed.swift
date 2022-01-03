//
//  Feed.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import Foundation

/**
 {
 "feed": {
 "title": "Top Albums",
 "id": "https://rss.applemarketingtools.com/api/v2/us/music/most-played/4/albums.json",
 "author": {
 "name": "Apple",
 "url": "https://www.apple.com/"
 },
 "links": [
 {
 "self": "https://rss.applemarketingtools.com/api/v2/us/music/most-played/4/albums.json"
 }
 ],
 "copyright": "Copyright © 2022 Apple Inc. All rights reserved.",
 "country": "us",
 "icon": "https://www.apple.com/favicon.ico",
 "updated": "Mon, 3 Jan 2022 22:57:56 +0000",
 "results": [
 {
 "artistName": "Lin-Manuel Miranda, Germaine Franco & Encanto - Cast",
 "id": "1594677532",
 "name": "Encanto (Original Motion Picture Soundtrack)",
 "releaseDate": "2021-11-19",
 "kind": "albums",
 "artistId": "329027198",
 "artistUrl": "https://music.apple.com/us/artist/lin-manuel-miranda/329027198",
 "artworkUrl100": "https://is2-ssl.mzstatic.com/image/thumb/Music126/v4/94/4d/9a/944d9a8d-0549-f537-5706-5b083bd84a7d/21UM1IM38949.rgb.jpg/100x100bb.jpg",
 "genres": [
 {
 "genreId": "16",
 "name": "Soundtrack",
 "url": "https://itunes.apple.com/us/genre/id16"
 },
 {
 "genreId": "34",
 "name": "Music",
 "url": "https://itunes.apple.com/us/genre/id34"
 }
 ],
 "url": "https://music.apple.com/us/album/encanto-original-motion-picture-soundtrack/1594677532"
 },
 {
 "artistName": "Birdman & YoungBoy Never Broke Again",
 "id": "1599656830",
 "name": "From The Bayou",
 "releaseDate": "2021-12-10",
 "kind": "albums",
 "artistId": "72812522",
 "artistUrl": "https://music.apple.com/us/artist/birdman/72812522",
 "contentAdvisoryRating": "Explict",
 "artworkUrl100": "https://is4-ssl.mzstatic.com/image/thumb/Music126/v4/83/b2/2c/83b22c5a-e2ad-3ce6-66ae-4cc77fa041ca/190296329036.jpg/100x100bb.jpg",
 "genres": [
 {
 "genreId": "18",
 "name": "Hip-Hop/Rap",
 "url": "https://itunes.apple.com/us/genre/id18"
 },
 {
 "genreId": "34",
 "name": "Music",
 "url": "https://itunes.apple.com/us/genre/id34"
 }
 ],
 "url": "https://music.apple.com/us/album/from-the-bayou/1599656830"
 },
 {
 "artistName": "Summer Walker",
 "id": "1590029262",
 "name": "Still Over It",
 "releaseDate": "2021-11-05",
 "kind": "albums",
 "artistId": "990402287",
 "artistUrl": "https://music.apple.com/us/artist/summer-walker/990402287",
 "contentAdvisoryRating": "Explict",
 "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/Music126/v4/f0/8c/bf/f08cbffc-1101-f974-a2d3-38381d8ed506/21UM1IM23130.rgb.jpg/100x100bb.jpg",
 "genres": [
 {
 "genreId": "15",
 "name": "R&B/Soul",
 "url": "https://itunes.apple.com/us/genre/id15"
 },
 {
 "genreId": "34",
 "name": "Music",
 "url": "https://itunes.apple.com/us/genre/id34"
 }
 ],
 "url": "https://music.apple.com/us/album/still-over-it/1590029262"
 },
 {
 "artistName": "Juice WRLD",
 "id": "1600580338",
 "name": "Fighting Demons (Lyric Video Version)",
 "releaseDate": "2021-12-10",
 "kind": "albums",
 "artistId": "1368733420",
 "artistUrl": "https://music.apple.com/us/artist/juice-wrld/1368733420",
 "contentAdvisoryRating": "Explict",
 "artworkUrl100": "https://is3-ssl.mzstatic.com/image/thumb/Music116/v4/f1/64/f3/f164f3d0-2835-afc2-e2bc-e13cde8fd76b/21UM1IM54282.rgb.jpg/100x100bb.jpg",
 "genres": [
 {
 "genreId": "18",
 "name": "Hip-Hop/Rap",
 "url": "https://itunes.apple.com/us/genre/id18"
 },
 {
 "genreId": "34",
 "name": "Music",
 "url": "https://itunes.apple.com/us/genre/id34"
 }
 ],
 "url": "https://music.apple.com/us/album/fighting-demons-lyric-video-version/1600580338"
 }
 ]
 }
 }

 Leaving this paylod so dev can understand the below structures.
 - Every feed from the https://rss.itunes.apple.com/en-us/?country=ca will have the same root structure.
 */

/// Idea from personal blog https://blog.usejournal.com/advanced-generics-and-protocols-in-swift-c30020fd5ded

struct Author: Decodable {
    let name: String
    let url: String
}

protocol ItunesResource: Decodable {
    associatedtype Model
    var title: String { get }
    var id: String { get }
    var author: Author { get }
    var copyright: String { get }
    var country: String { get }
    var icon: String { get }
    var updated: String { get }
    var results: [Model] { get }
}

struct ItunesResources<Model: Decodable>: ItunesResource {

    public let title: String
    public let id: String
    public let author: Author
    public let copyright: String
    public let country: String
    public let icon: String
    public let updated: String
    public let results: [Model]
}

protocol FeedProtocol: Decodable {
    associatedtype FeedResource: ItunesResource
    var feed: FeedResource? { get }
}

struct Feed<FeedResource: ItunesResource>: FeedProtocol {
    let feed: FeedResource?
}
