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
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {

        ScrollView {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(itunesRemote.groups, id: \.self) { group in
                    Section(header: Text("\(group.sectionID.title)").font(.title).bold().padding(15)) {
                        ForEach(group.cellIDs) {
                            FeedItemView(artwork: $0)
                        }
                    }
                }
            }
        }
        .task {
           // itunesRemote.asyncGroups(from: ItunesGroupIdentifier.allCases)
          //  itunesRemote.getAppGroups(ItunesGroup.allCases)
            itunesRemote.dispatchGroups(from: ItunesGroupIdentifier.allCases)
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
        asyncImageView
    }

    private var asyncImageView: some View {
        AsyncImage(
            url: URL(string: artwork.imageURL),
            transaction: .init(animation: .spring())
        ) { phase in
            switch phase {
            case .empty, .failure:
                ProgressView()
                    .frame(idealHeight: 250)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity.combined(with: .scale))
            @unknown default:
                Text("There is an error")
            }
        }
    }
}

