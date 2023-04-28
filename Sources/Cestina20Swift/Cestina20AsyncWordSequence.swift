//
//  Cestina20.swift
//
//
//  Created by Vít Kabele on 19.03.2023.
//

import SwiftSoup
import Foundation

/// Iterate over the words defined by the url and css selector
/// Also respect paging
public struct Cestina20AsyncWordSequence : AsyncSequence, AsyncIteratorProtocol {
    
    public typealias Element = C20WordHandle
    
    /// This is one-based offset of the current page
    /// The website aliases pages zero and one, so it is cleaner to also start at 1
    private var currentPage : Int
    
    private var currentPageFirstWord : Int {
        assert(currentPage >= 1)
        return (currentPage - 1) * pageSize
    }
    
    /// Global index of the word.
    /// Start index at zero
    private var currentWord : Int
    
    private var currentPageList : [C20WordHandle] = []
    
    private let pageSize : Int
    
    private let baseURLString = "https://www.cestina20.cz"
    
    /// Location of the requested resource on the web
    private let URI : String
    
    /// CSS selector to retrieve the word from website
    private let selector : String
    
    /// Possible URL query. Used for search requests
    private let queryItems : [URLQueryItem]
    
    private init(fromPage: String = "", queryItems: [URLQueryItem] = [], selector: String, pageSize: Int, wordOffset: Int) {
        self.URI = fromPage
        self.selector = selector
        self.queryItems = queryItems
        // Internal representation references the pages 1 based (same as the website)
        self.currentPage = wordOffset/pageSize + 1
        self.pageSize = pageSize
        self.currentWord = wordOffset
    }
    
    public static func ofRecent(startingFromIndex wordOffset: Int = 0) -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            fromPage: "/zebricek/nove-pridana/",
            selector: ".word__title a",
            pageSize: 10,
            wordOffset: wordOffset)
    }
    
    public static func ofMostPopular(startingFromIndex wordOffset: Int = 0) -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            fromPage: "/zebricek/nejoblibenejsi/",
            selector: ".best__list li a",
            pageSize: 50,
            wordOffset: wordOffset)
    }
    
    public static func bySearch(query: String, startingFromIndex wordOffset: Int = 0) -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            queryItems: [URLQueryItem(name: "s", value: query)],
            selector: ".search__list li a",
            pageSize: 30,
            wordOffset: wordOffset)
    }
    
    private func fetchList(page: Int = 0) async throws -> [C20WordHandle] {
        
        do {
            var urlComponents = URLComponents(string: baseURLString)
            urlComponents!.path = "\(URI)/strana/\(page)"
            urlComponents!.queryItems = queryItems
            let (data, response) = try await URLSession.shared.data(from: urlComponents!.url!)
            
            guard let httpr = response as? HTTPURLResponse,
                  (200...299).contains(httpr.statusCode),
                  httpr.mimeType == "text/html" else {
                // The error code was not 200 or the response was not http at all.
                // We can't handle this so we return an empty array
                return []
            }
            
            // TODO: Use proper encoding as reported by the response object
            let html = String(data: data, encoding: .utf8)!
            
            let doc: Document = try SwiftSoup.parse(html)
            
            let words = try doc.select(selector)
            
            return words.map{element in
                C20WordHandle(word: try! element.text(), wordURL: try! URL(string: element.attr("href"))!)
            }
        } catch SwiftSoup.Exception.Error(let type, let message) {
            // Parse errors from SwiftSoup
            fatalError("SwiftSoup exception: \(type) \(message)")
        } catch {
            // Remaining errors
            print("Unknown exception \(error)")
            throw error
        }
    }
    
    public mutating func next() async throws -> Element? {
        defer { currentWord += 1 }

        let nextPageFirstWord = currentPageFirstWord + pageSize
        
        if currentPageFirstWord + currentPageList.count <= currentWord  {
            /// Current word is located on the next page
            if currentWord >= nextPageFirstWord {
                currentPage += 1
            }
            currentPageList = try await fetchList(page: currentPage)
        }
        
        /// Current word is located in the actual page
        assert(currentWord >= currentPageFirstWord)
        let wordIndex = currentWord - currentPageFirstWord
        return currentPageList.count > wordIndex ? currentPageList[wordIndex] : nil
    }
    
    public func makeAsyncIterator() -> Cestina20AsyncWordSequence {
            self
    }
}
