//
//  Cestina20WordWrapper.swift
//  
//
//  Created by Vít Kabele on 20.03.2023.
//

import Foundation
import SwiftSoup

///
/// Using actor type should protect us from parallel accesses on our html cache.
/// TODO: Is it the best way to do it?
///
public actor Cestina20WordWrapper : Identifiable {
    
    public typealias ID = String
    
    public let id : ID
    
    public var word : String
    
    ///
    /// Cache for the description getter
    ///
    private var _definitions : [String]?
    public var definitions : [String] {
        get async {
            if _definitions == nil {
                _definitions = []
                let defs = try! await getHtml().select(".word p")
                
                for d in defs {
                    if try! d.select("strong, em").count != 0 {
                        // strong is in the author paragraph
                        // em is in the examples paragraph
                        // Definitions and examples can be interleaved
                        continue
                    }
                    _definitions?.append(try! d.text())
                }
            }

            return _definitions!
        }
    }
    
    ///
    /// Cache for the likes getter
    ///
    private var _likes : Int?
    public var likes : Int {
        get async {
            if _likes == nil {
                let strval = try! await getHtml().select(".word .word__rating--up").first()!.text()
                _likes = Int(strval)
            }

            return _likes!
        }
    }
    
    ///
    /// Cache for the dislikes getter
    ///
    private var _dislikes : Int?
    public var dislikes : Int {
        get async {
            if _dislikes == nil {
                let strval = try! await getHtml().select(".word .word__rating--down").first()!.text()
                _dislikes = Int(strval)
            }

            return _dislikes!
        }
    }
    
    private var _examples : [String]?
    public var examples : [String] {
        get async {
            if _examples == nil {
                _examples = []
                let example = try! await getHtml().select(".word em")

                for e in example {
                    var raw_text = try! e.text()
                    let prefix = "Příklad: "
                    // The prefix is not present when word has more than one example
                    if raw_text.hasPrefix(prefix) {
                        raw_text = String(raw_text.dropFirst(prefix.count))
                    }
                    _examples!.append(raw_text)
                }
            }
            return _examples!
        }
    }
    
    private var url : URL
    
    private var htmlCache : SwiftSoup.Document?
    
    init(word: String, wordURL: URL) {
        self.url = wordURL
        self.word = word
        self.id = self.url.lastPathComponent
    }
    
    private func getHtml() async -> SwiftSoup.Document {
        if htmlCache == nil {
            let (data, _) = try! await URLSession.shared.data(from: url)
            
            let html = String(data: data, encoding: .utf8)!
            
            /// Should be synced because we are actor?
            /// TODO: Catch error
            htmlCache = try! SwiftSoup.parse(html)
        }
        
        return htmlCache!
    }
    
    /// Resolve the async wrapper and return the final word.
    public func resolve() async -> Cestina20Word {
        return await Cestina20Word(
            id:  self.id,
            word: word,
            author: "",
            definitions: self.definitions,
            examples: await examples,
            dateAdded: Date(),
            likes: await likes,
            dislikes: await dislikes,
            similarWords: [])

    }
}
