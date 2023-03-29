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
    public let similarWords : [Cestina20Word]

}
