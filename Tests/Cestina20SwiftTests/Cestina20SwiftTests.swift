import XCTest
@testable import Cestina20Swift

final class Cestina20SwiftTests: XCTestCase {
    
    struct TestWordDescription {
        let word: String
        let date: Date
        let author: String
    }
    
    static func ymdDate(year: Int, month: Int, day: Int) -> Date {
        var comonents = DateComponents()
        comonents.year = year
        comonents.month = month
        comonents.day = day
        return Calendar.current.date(from: comonents)!
    }
    
    private let mostPopularWords = [
        0: [ // Start index 0
            TestWordDescription(word: "powerpoint karaoke", date: ymdDate(year: 2016, month: 9, day: 14), author: "@KTweetuje/jkremser"),
            TestWordDescription(word: "čvančary", date: ymdDate(year: 2017, month: 7, day: 20), author: "Ian Schlendri"),
            TestWordDescription(word: "kurvítko", date: ymdDate(year: 2009, month: 10, day: 17), author: "med / Vykupitel Pytel"),
            TestWordDescription(word: "nadsrat", date: ymdDate(year: 2018, month: 8, day: 30), author: "Lukáš Král z Opavy"),
            TestWordDescription(word: "milošekunda", date: ymdDate(year: 2014, month: 11, day: 18), author: "@chovatel")
           ],
        50: [ // Start index 51 (Start of page)
            TestWordDescription(word: "lesana", date: ymdDate(year: 2017, month: 4, day: 9), author: "José"),
            TestWordDescription(word: "korporátní porno", date: ymdDate(year: 2017, month: 9, day: 15), author: "José"),],
        59: [ // Start index 60 (Middle of page)
            TestWordDescription(word: "alzaheimer", date: ymdDate(year: 2017, month: 11, day: 19), author: "Jenda Šilhavý"),
            TestWordDescription(word: "memopauza", date: ymdDate(year: 2013, month: 5, day: 2), author: "Děda Louda"),
            ],
        49: [ // Start index 50 (End of page)
            TestWordDescription(word: "chčaj", date: ymdDate(year: 2017, month: 9, day: 12), author: "Šotouškovi / Jiří Wilson Němec / mezernick"),
            TestWordDescription(word: "lesana", date: ymdDate(year: 2017, month: 4, day: 9), author: "José"),
            ]]
    
    private let wordsByLetters : [String:[TestWordDescription]] = [
        "A": [
            TestWordDescription(word: "a celá tramvaj tleskala", date: ymdDate(year: 2022, month: 2, day: 14), author: "Tankista"),
            TestWordDescription(word: "aáčko", date: ymdDate(year: 2020, month: 1, day: 22), author: "OVO"),
        ],
        "CH": [
            TestWordDescription(word: "chabaští", date: ymdDate(year: 2018, month: 12, day: 29), author: "Radek Simkanič"),
        ],
        "ostatni": [
            TestWordDescription(word: "!!!", date: ymdDate(year: 2017, month: 7, day: 3), author: "amur"),
        ],
    ]
    
    /// Test that the API properly returns most popular words
    ///
    /// The test expects that the leaderboard is mostly stable
    ///
    func testMostPopularWords() async throws {
        
        for key in mostPopularWords.keys {
            let mostPopular = Cestina20AsyncWordSequence.ofMostPopular(startingFromIndex: key)
            
            var iterator = mostPopular.makeAsyncIterator()
            
            for mpword in mostPopularWords[key]! {
                let fetched = try await iterator.next()?.resolve()
                XCTAssertNotNil(fetched)
                XCTAssertEqual(fetched?.word, mpword.word)
                XCTAssertEqual(fetched?.dateAdded, mpword.date)
                XCTAssertEqual(fetched?.author, mpword.author)
            }
        }
    
    }
    
    /// Test case of iteration that crosses the page boundary
    func testWordsByLetter() async throws {
        
        for key in wordsByLetters.keys {
            let letterSequence = Cestina20AsyncWordSequence.byStartingLetter(letter: key)
            
            var iterator = letterSequence.makeAsyncIterator()
            
            for mpword in wordsByLetters[key]! {
                let fetched = try await iterator.next()?.resolve()
                XCTAssertNotNil(fetched)
                XCTAssertEqual(fetched?.word, mpword.word)
                XCTAssertEqual(fetched?.dateAdded, mpword.date)
                XCTAssertEqual(fetched?.author, mpword.author)
            }
        }
    
    }
    
    /// Test that search result for some obscure query only returns limited amount of words
    ///
    /// This tests that the Async sequence terminates properly when end of the list is reached
    /// 
    func testSearchResults() async throws {
        
        let searchResult = Cestina20AsyncWordSequence.bySearch(query: "střihoun")
        
        var iterator = searchResult.makeAsyncIterator()
        
        let strihoun = try await iterator.next()?.resolve()
        
        XCTAssertNotNil(strihoun)
        XCTAssertEqual(strihoun!.word, "střihoun")
        XCTAssertEqual(strihoun!.dateAdded, Cestina20SwiftTests.ymdDate(year: 2023, month: 3, day: 10))
        XCTAssertEqual(strihoun!.definitions.count, 1)
        XCTAssertEqual(strihoun!.examples.count, 0)
        XCTAssertGreaterThan(strihoun!.likes, 6)
        XCTAssertGreaterThan(strihoun!.dislikes, 3)
        // This word was chosen because it has no author.
        XCTAssertNil(strihoun!.author)
        
        // The query should have only one result
        let nextItem = try await iterator.next()
        XCTAssertNil(nextItem)
    }
    
    /// Test that fetched data match the expected data
    func testFetchWordDetails() async throws {
        
        let mp = Cestina20AsyncWordSequence.ofMostPopular()
        
        var iterator = mp.makeAsyncIterator()
        
        let w1 = try await iterator.next()?.resolve()
        
        XCTAssertNotNil(w1)
        XCTAssertEqual(w1?.word, "powerpoint karaoke")
        XCTAssertEqual(w1?.id, "powerpoint-karaoke")
        
        /// Data when writing the tests
        /// Could change over time, but should not decrease
        XCTAssertGreaterThan(w1!.likes, 2300)
        XCTAssertGreaterThan(w1!.dislikes, 230)
        
        XCTAssertEqual(w1?.examples.count, 0)
        XCTAssertEqual(w1?.definitions.count, 2)
    }
    
    func testCreateWordManually() async throws {
        let w = C20WordHandle(word: "vstupař", wordURL: URL(string: "https://cestina20.cz/slovnik/vstupar/")!)
        
        let word = try await w.resolve()
        
        XCTAssertEqual(word.definitions.count, 2)
        XCTAssertEqual(word.dateAdded, Cestina20SwiftTests.ymdDate(year: 2023, month: 1, day: 15))
        XCTAssertNil(word.author)
        
        // Single example can be spanned across multiple <em> tags???
        XCTAssertEqual(word.examples.count, 3)
    }
}
