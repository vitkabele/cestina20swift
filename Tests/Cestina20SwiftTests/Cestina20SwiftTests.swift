import XCTest
@testable import Cestina20Swift

final class Cestina20SwiftTests: XCTestCase {
    
    struct TestWordDescription {
        let word: String
        let date: Date
    }
    
    static func ymdDate(year: Int, month: Int, day: Int) -> Date {
        var comonents = DateComponents()
        comonents.year = year
        comonents.month = month
        comonents.day = day
        return Calendar.current.date(from: comonents)!
    }
    
    private let mostPopularWords = [
        TestWordDescription(word: "powerpoint karaoke", date: ymdDate(year: 2016, month: 9, day: 14)),
        TestWordDescription(word: "čvančary", date: ymdDate(year: 2017, month: 7, day: 20)),
        TestWordDescription(word: "kurvítko", date: ymdDate(year: 2009, month: 10, day: 17)),
        TestWordDescription(word: "nadsrat", date: ymdDate(year: 2018, month: 8, day: 30)),
        TestWordDescription(word: "milošekunda", date: ymdDate(year: 2014, month: 11, day: 18))
    ]
    
    /// Test that the API properly returns most popular words
    ///
    /// The test expects that the leaderboard is mostly stable
    ///
    func testMostPopularWords() async throws {
        
        let mostPopular = Cestina20AsyncWordSequence.ofMostPopular()
        
        var iterator = mostPopular.makeAsyncIterator()
        
        for mpword in mostPopularWords {
            let fetched = try await iterator.next()?.resolve()
            XCTAssertNotNil(fetched)
            XCTAssertEqual(fetched?.word, mpword.word)
            XCTAssertEqual(fetched!.dateAdded, mpword.date)
        }
    
    }
    
    /// Test that search result for some obscure query only returns limited amount of words
    ///
    /// This tests that the Async sequence terminates properly when end of the list is reached
    /// 
    func testSearchResults() async throws {
        
        let searchResult = Cestina20AsyncWordSequence.bySearch(query: "testovka")
        
        var iterator = searchResult.makeAsyncIterator()
        
        let testovka = try await iterator.next()?.resolve()
        
        XCTAssertEqual(testovka?.word, "testovka")
        
        let test = try await iterator.next()?.resolve()
        XCTAssertEqual(test?.word, "test")
        
        let nothingLeft = try await iterator.next()
        XCTAssertNil(nothingLeft)
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
        
        // Single example can be spanned across multiple <em> tags???
        XCTAssertEqual(word.examples.count, 3)
    }
}
