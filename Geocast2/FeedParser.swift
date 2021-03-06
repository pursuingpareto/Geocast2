//
//  FeedParser.swift
//  Geocast2
//
//  Created by Andrew Brown on 11/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation

@objc protocol FeedParserDelegate {
    optional func didParseFeedIntoEpisodes(episodes: [Episode])
    optional func didParsePodcastSummaryData(data: [String: String])
    optional func errorParsingPodcast(podcast: Podcast, error: NSError?)
}

class FeedParser: NSXMLParser, NSXMLParserDelegate {
    private var feedParserDelegate: FeedParserDelegate!
    private var episodes = [Episode]()
    private var podcast: Podcast!
    
    private var entryTitle: String!
    private var entryDescription: String!
    private var entryLink: String!
    private var insideItem: Bool = false
    private var currentParsedElement:String! = String()
    private var shouldParseCurrentElement = true
    private var podcastDictionary: [String:String]! = Dictionary()
    private var entryDictionary: [String:String]! = Dictionary()
    private var entryValue: String = ""
    private var entriesArray:[Dictionary <String, String> ]! = Array()
    private let interestingElementNames = [
        "item",
        "title",
        "description",
        "image",
        "subtitle",
        "summary",
        "pubDate",
        "content",
        "thumbnail",
        "duration",
        "subtitle",
        "enclosure",
        "itunes:duration"
    ]
    
    
    override init(data: NSData) {
        super.init(data: data)
        delegate = self
    }
    
    convenience init(data: NSData, podcast: Podcast) {
        self.init(data: data)
        delegate = self
        self.podcast = podcast
    }
    
    class func parsePodcast(podcast: Podcast, withFeedParserDelegate feedParserDelegate: FeedParserDelegate) {

        let feedUrl = podcast.feedUrl
        let session = NSURLSession.sharedSession()
        var parseSuccessful = false
        let task = session.dataTaskWithURL(feedUrl, completionHandler: {data, response, error -> Void in
            if (error != nil) {
                print("oops, error is \(error)")
            } else {
                if let data = data {
                    let parser = FeedParser(data: data, podcast: podcast)
                    parser.feedParserDelegate = feedParserDelegate
                    parser.shouldProcessNamespaces = true
                    parseSuccessful = parser.parse()
                }
            }
            if !parseSuccessful {
                feedParserDelegate.errorParsingPodcast?(podcast , error: error)
            }
        })
        
        task.resume()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentParsedElement = qName
        if currentParsedElement == nil {
            currentParsedElement = elementName
        }
        entryValue = ""
        if elementName == "item" {
            self.insideItem = true
        }
        if elementName == "content" {
            let url = attributeDict["url"]
            if url != nil {
                entryDictionary["mp3Url"] = url
            }
        }
        if elementName == "enclosure" {
            let url = attributeDict["url"]
            if url != nil {
                entryDictionary["mp3Url"] = url
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        let newString: String = "\(entryValue)\(string)"
        entryValue = newString
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if insideItem {
            entryDictionary[currentParsedElement] = entryValue
        } else {
            podcastDictionary[currentParsedElement] = entryValue
        }
        if elementName == "item" {
            self.insideItem = false
            entriesArray.append(entryDictionary)
            entryDictionary.removeAll(keepCapacity: true)
        }
    }

    func parserDidEndDocument(parser: NSXMLParser) {
        guard let feedParser = parser as? FeedParser else {
           return
        }
        episodes.removeAll()
        var newEpisode: Episode?
        for entry in self.entriesArray {
            newEpisode = nil
            
            // try to make an episode
            guard let title:String = entry["title"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) else {
                continue
            }
            guard let mp3UrlString:String = entry["mp3Url"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) else {
                continue
            }
            guard let mp3Url = NSURL(string: mp3UrlString) else {
                continue
            }
            let newEpisode = Episode(podcast: feedParser.podcast, mp3URL: mp3Url, title: title)
            // now try to add other fields
            if let durationString: String = entry["itunes:duration"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
                if let duration = FeedParser.durationFromString(durationString) {
                    newEpisode.duration = duration
                }
            }
            
            var summary = entry["description"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            if summary == nil {
                summary = entry["itunes:summary"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            }
            
            let itunesSummary = entry["itunes:summary"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let subtitle = entry["itunes:subtitle"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let pubDateString = entry["pubDate"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let pubDate = FeedParser.dateFromString(entry["pubDate"]?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
            
            newEpisode.subtitle = subtitle
            newEpisode.iTunesSummary = itunesSummary
            newEpisode.summary = summary
            newEpisode.pubDate = pubDate
            
            episodes.append(newEpisode)
        }
        feedParserDelegate.didParseFeedIntoEpisodes?(episodes)
        feedParserDelegate.didParsePodcastSummaryData?(podcastDictionary)
    }
    
    class func durationFromString(string: String) -> NSTimeInterval? {
        var seconds: Int?
        
        guard string.characters.count > 1 else {
            return nil
        }
        
        var fractionalTime = string.characters.split { $0 == "." }.map { String($0) }
        let wholeTime = fractionalTime[0]
        var splitTime = wholeTime.characters.split { $0 == ":" }.map { String($0) }
        switch splitTime.count {
        case 1:
            seconds = Int(splitTime[0])
        case 2:
            if let mins = Int(splitTime[0]) {
                if let secs = Int(splitTime[1]) {
                    seconds = 60 * mins + secs
                }
            }
        case 3:
            if let hours = Int(splitTime[0]) {
                if let mins = Int(splitTime[1]) {
                    if let secs = Int(splitTime[2]) {
                        seconds = 3600 * hours + 60 * mins + secs
                    }
                }
            }
        default:
            seconds = nil
        }
        if seconds != nil {
            return NSTimeInterval(seconds!)
            
        } else {
            return nil
        }
    }
    
    class func dateFromString(string: String?) -> NSDate? {
        guard let string = string else {
            return nil
        }
        let df = NSDateFormatter()
        df.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
        if let date = df.dateFromString(string) {
            return date
        } else {
            return nil
        }
    }
}