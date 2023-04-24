//
//  Cestina20Word.swift
//  
//
//  Created by Vít Kabele on 24.03.2023.
//

import Foundation

public struct Cestina20Word : Identifiable, Encodable {
    
    public typealias ID = String
    
    /// This is the "slug" used to identify the word on the website
    public var id: ID
    
    /// The word itself
    public let word : String
    
    /// The word author. Can be null as not every word has an author defined
    public let author : String?
    
    /// Word definitions
    public let definitions : [String]
    
    /// Examples of the word usage
    public let examples : [String]
    
    /// Date when the word was added to the website
    public let dateAdded : Date
    
    /// How many likes. This property can change over time
    public let likes : Int
    
    /// How many dislikes. This property can change over time
    public let dislikes : Int
    
    /// List of similar words listed on the word page
    public let similarWords : [C20WordHandle]

    public init(id: Cestina20Word.ID, word: String, author: String? = nil, definitions: [String], examples: [String], dateAdded: Date, likes: Int, dislikes: Int, similarWords: [C20WordHandle]) {
        self.id = id
        self.word = word
        self.author = author
        self.definitions = definitions
        self.examples = examples
        self.dateAdded = dateAdded
        self.likes = likes
        self.dislikes = dislikes
        self.similarWords = similarWords
    }
}
