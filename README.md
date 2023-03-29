# Cestina20Swift

This package is a Swift API library for getting data from the [Cestina2.0](https://cestina20.cz) website.
It is primarily intended for use in the Cestina20 iOS app.

## Usage

The API is rather simple wrapper around the [SwiftSoup](...) library, since the official website does not provide any
kind of web API.

For example usage please see the Cestina20Cli app that is executable product of this package.

### The word type

The basic building block of the library is the Word type. Because the way in which the API works, only the `word` property is available immediately.
Other properties are fetched from the page of the particular word and they might require another network request.

```swift
public struct Cestina20Word {
    public let id : String
    public let word : String;
    public let author : String;
    public let description : String;
    public let example : String;
    public let dateAdded : Date;
    public let likes : Int;
    public let dislikes : Int;
    public let similarWords : [Cestina20Word]
}
```

There is also a Cestina20WordWrapper type for async fetching of the word details. The wrapper can either be used
to get the populated `Cestina20Word` or to access properties one by one. If the word page was not yet downloaded,
the first fetch involves fetching the word page from the web.

### Async Word sequence

The library defines `Cestina20AsyncWordSequence` class, which implements the `AsyncSequence` protocol.
This class has no public constructor, and its instances can be fetched by calling static methods for different sequences of words.
There is a method `Cestina20AsyncWordSequence.ofRecent()` that allows iterating recent words, the method `ofMostPopular()` for most
popular words and the method `bySearch(query: String)` which returns sequence for iterating words that are result of a search on the
website.

## Author

This library is written and maintained by [Vit Kabele](https://www.kabele.me) in a free time.
