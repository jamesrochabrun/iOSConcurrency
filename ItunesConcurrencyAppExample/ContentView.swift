//
//  ContentView.swift
//  ItunesConcurrencyAppExample
//
//  Created by James Rochabrun on 6/15/21.
//

import SwiftUI

@available(iOS 15, *)
struct ContentView: View {

    @StateObject private var itunesRemote = ItunesRemote()
    let columns =
        [GridItem(.flexible()), GridItem(.flexible())]


    var body: some View {

        ScrollView {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(itunesRemote.groups, id: \.self) { group in
                    Section(header: Text("\(group.sectionIdentifier.rawValue)").font(.title).bold().padding(15)) {
                        ForEach(group.cellIdentifiers) {
                            FeedItemView(artwork: $0)
                        }
                    }
                }
            }
        }
        .task {
            itunesRemote.genericGetGroups(ItunesGroup.allCases)
      //      itunesRemote.useDispatchGroup()
        }
    }
}

@available(iOS 15, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@available(iOS 15, *)
struct FeedItemView: View {

    let artwork: Artwork

    var body: some View {
        AsyncImage(
            url: URL(string: artwork.imageURL),
            transaction: .init(animation: .spring())
        ) { phase in
            switch phase {
            case .empty:
                Color.clear
            case .success(let image):
                image
                    .transition(.opacity.combined(with: .scale))
            case .failure(let error):
                Text("There is an error \(error.localizedDescription)")
            @unknown default:
                Text("There is an error")
            }
        }
    }
}

