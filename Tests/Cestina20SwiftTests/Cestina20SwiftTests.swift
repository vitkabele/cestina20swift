import XCTest
@testable import Cestina20Swift

final class Cestina20SwiftTests: XCTestCase {
    
    private let mostPopularWords = [
        "powerpoint karaoke",
        "čvančary",
        "kurvítko",
        "nadsrat",
        "milošekunda"
    ]
    
    /// Test that the API properly returns most popular words
    ///
    /// The test expects that the leaderboard is mostly stable
    ///
    func testMostPopularWords() async throws {
        
        let mostPopular = Cestina20AsyncWordSequence.ofMostPopular()
        
        var iterator = mostPopular.makeAsyncIterator()
        
        for mpword in mostPopularWords {
            let fetched = try await iterator.next()
            XCTAssertNotNil(fetched)
            XCTAssertEqual(fetched?.word, mpword)
        }
    
    }
    
    /// Test that search result for some obscure query only returns limited amount of words
    ///
    /// This tests that the Async sequence terminates properly when end of the list is reached
    /// 
    func testSearchResults() async throws {
        
        let searchResult = Cestina20AsyncWordSequence.bySearch(query: "testovka")
        
        var iterator = searchResult.makeAsyncIterator()
        
        let testovka = try await iterator.next()
        
        XCTAssertEqual(testovka?.word, "testovka")
        
        let test = try await iterator.next()
        XCTAssertEqual(test?.word, "test")
        
        let nothingLeft = try await iterator.next()
        XCTAssertNil(nothingLeft)
    }
    
    /// Test that fetched data match the expected data
    func testFetchWordDetails() async throws {
        
        let mp = Cestina20AsyncWordSequence.ofMostPopular()
        
        var iterator = mp.makeAsyncIterator()
        
        let w1 = try await iterator.next()
        
        XCTAssertNotNil(w1)
        XCTAssertEqual(w1?.word, "powerpoint karaoke")
        
        /// Data when writing the tests
        /// Could change over time, but should not decrease
        XCTAssertGreaterThan(w1!.likes, 2300)
        XCTAssertGreaterThan(w1!.dislikes, 230)
    }
}
