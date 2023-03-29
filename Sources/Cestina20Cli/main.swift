//
//  main.swift
//
//  CLI wrapper for the Cestina 2.0 swift library
//
//  Created by Vít Kabele on 20.03.2023.
//

import Foundation
import Cestina20Swift
import ArgumentParser

enum QueryType: String, EnumerableFlag {
    case popular, recent
}

struct SelectOptions: ParsableArguments {
    @Option var count: Int = 10
    @Option var query : String?
    @Option var minLikes : Int = 0
    @Option var maxDislikes : Int = Int.max
    @Flag var json : Bool = false
    @Flag var list : QueryType = .popular
}

let options = SelectOptions.parseOrExit()
var words = Cestina20AsyncWordSequence.ofRecent()

/// If query is specified, we no longer care whether the user wanted most popular or most recent words
if options.query != nil {
    words = Cestina20AsyncWordSequence.bySearch(query: options.query!)
} else {
    switch options.list {
    case .popular:
        words = Cestina20AsyncWordSequence.ofMostPopular()
        break
    default:
        words = Cestina20AsyncWordSequence.ofRecent()
    }
}

let iterable = words.map{ await $0.resolve() }.filter{ $0.likes > options.minLikes && $0.dislikes < options.maxDislikes }.prefix(options.count)

if options.json {
    var arr : [Cestina20Word] = []
    for try await word in iterable {
        arr.append(word)
    }
    
    // Convert to a string and print
    if let JSONString = String(data: try JSONEncoder().encode(arr), encoding: String.Encoding.utf8) {
       print(JSONString)
    }
    
} else {
    for try await word in iterable {
        print("\nWord: \(word.word)")
        print(word.description)
        print("\(word.likes) 👍 👎 \(word.dislikes)" )
        
        for example in word.examples {
            print("📝 \(example)")
        }
    }
}

