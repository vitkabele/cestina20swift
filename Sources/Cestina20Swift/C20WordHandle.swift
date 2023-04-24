//
//  Cestina20WordWrapper.swift
//  
//
//  Created by Vít Kabele on 20.03.2023.
//

import Foundation
import SwiftSoup

public class C20WordHandle : Identifiable, Encodable {
    
    public typealias ID = String
    
    public let id : ID
    
    public var word : String
    
    private var url : URL
    
    public init(word: String, wordURL: URL) {
        self.url = wordURL
        self.word = word
        self.id = self.url.lastPathComponent
    }
    
    private func getHtml() async throws -> SwiftSoup.Document {
        let (data, _) = try await URLSession.shared.data(from: url)
            
        let html = String(data: data, encoding: .utf8)!
        let htmlCache = try SwiftSoup.parse(html)
        
        return htmlCache
    }
    
    /// Resolve the async wrapper and return the final word.
    public func resolve() async throws -> Cestina20Word {
        
        let html = try await getHtml()
        
        return Cestina20Word(
            id:  self.id,
            word: word,
            /// TODO: We can't fetch real author yet
            author: "",
            definitions: try getDefinitions(from: html),
            examples: getExamples(from: html),
            /// TODO: We can't fetch real date yet
            dateAdded: Date(),
            likes: try getLikes(from: html),
            dislikes: try getDislikes(from: html),
            similarWords: [])

    }
    
    private func getDefinitions(from html: SwiftSoup.Document) throws -> [String] {
        var definitions : [String] = []
        let defs = try html.select(".word p")
        
        for d in defs {
            if try d.select("strong, em").count != 0 {
                // strong is in the author paragraph
                // em is in the examples paragraph
                // Definitions and examples can be interleaved
                continue
            }
            definitions.append(try! d.text())
        }
        return definitions
    }
    
    private func getLikes(from html: SwiftSoup.Document) throws -> Int {
        let strval = try html.select(".word .word__rating--up").first()!.text()
        return Int(strval) ?? 0
    }
    
    private func getDislikes(from html: SwiftSoup.Document) throws -> Int {
        let strval = try html.select(".word .word__rating--down").first()!.text()
        return Int(strval) ?? 0
    }
    
    /// TODO: Should we hide the error or propagate it to the user?
    private func getExamples(from html: SwiftSoup.Document) -> [String] {
        var examples : [String] = []
        
        do {
            let example = try html.select(".word em")

            for e in example {
                var raw_text = try e.text()
                let prefix = "Příklad: "
                // The prefix is not present when word has more than one example
                if raw_text.hasPrefix(prefix) {
                    raw_text = String(raw_text.dropFirst(prefix.count))
                }
                examples.append(raw_text)
            }
        } catch SwiftSoup.Exception.Error(let type, let message) {
            print("Error while parsing examples: msg: \(message) type: \(type)")
        } catch {
            fatalError("Unknown error happened \(error)")
        }
        
        return examples
    }
}
