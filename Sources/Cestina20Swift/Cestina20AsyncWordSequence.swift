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
    
    public typealias Element = Cestina20Word
    
    /// The current downloaded page.
    /// The indexing on the website starts at 1 so we use zero to indicate that the
    /// iteration did not start yet
    private var currentPage : Int = 0
    
    /// Global index of the word.
    /// Start index at zero
    private var currentWord : Int = 0
    
    private var currentPageList : [Cestina20WordWrapper] = []
    
    /// The global index of the first word on current page.
    private var currentPageFirstWord = 0
    
    private let baseURLString = "https://www.cestina20.cz"
    
    /// Location of the requested resource on the web
    private let URI : String
    
    /// CSS selector to retrieve the word from website
    private let selector : String
    
    /// Possible URL query. Used for search requests
    private let queryItems : [URLQueryItem]
    
    init(fromPage: String = "", queryItems: [URLQueryItem] = [], selector: String) {
        self.URI = fromPage
        self.selector = selector
        self.queryItems = queryItems
    }
    
    public static func ofRecent() -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            fromPage: "/zebricek/nove-pridana/",
            selector: ".word__title a")
    }
    
    public static func ofMostPopular() -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            fromPage: "/zebricek/nejoblibenejsi/",
            selector: ".best__list li a")
    }
    
    public static func bySearch(query: String) -> Cestina20AsyncWordSequence {
        return Cestina20AsyncWordSequence(
            queryItems: [URLQueryItem(name: "s", value: query)],
            selector: ".search__list li a")
    }
    
    private func fetchList(page: Int = 0) async -> [Cestina20WordWrapper] {
        
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
                Cestina20WordWrapper(word: try! element.text(), wordURL: try! URL(string: element.attr("href"))!)
            }
        } catch SwiftSoup.Exception.Error(let type, let message) {
            // Parse errors from SwiftSoup
            fatalError("SwiftSoup exception: \(type) \(message)")
        } catch {
            // Remaining errors
            fatalError("Unknown exception")
        }
    }
    
    public mutating func next() async throws -> Element? {
        defer { currentWord += 1 }
        
        if currentPageFirstWord + currentPageList.count <= currentWord  {
            /// Current word is located on the next page
            currentPage += 1
            currentPageFirstWord = currentWord
            currentPageList = await fetchList(page: currentPage)
        }
        
        /// Current word is located in the actual page
        let wordIndex = currentWord - currentPageFirstWord
        return currentPageList.count > wordIndex ? await currentPageList[currentWord - currentPageFirstWord].resolve() : nil
    }
    
    public func makeAsyncIterator() -> Cestina20AsyncWordSequence {
            self
    }
}
