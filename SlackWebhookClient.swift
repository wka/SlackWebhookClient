//
//  SlackWebhookClient.swift
//  SlackTest
//
//  Created by Kris Arnold on 2/15/15.
//  Copyright (c) 2015 World Airmail Links. All rights reserved.
//

import Foundation
import CoreFoundation
import UIKit

typealias slackClientCompletionHandler = ((Bool, NSHTTPURLResponse?, NSError?) -> (Void))?

class SlackWebhookClient
{
  let webhookURL: NSURL
  let channel:    String?
  let username:   String?
  let iconEmoji:  String?
  let iconURL:    NSURL?
  var maxLengthForShortField = 40
  
  private let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
  
  init(webhookURL: NSURL, channel: String?, username: String?, iconEmoji: String?, iconURL: NSURL?)
  {
    self.webhookURL = webhookURL
    self.channel    = channel
    self.username   = username
    self.iconURL    = iconURL
    
    if var givenIconEmoji = iconEmoji {
      // add ":" character at start and end of iconEmoji if not present
      
      if givenIconEmoji.first() != ":" {
        givenIconEmoji = ":" + givenIconEmoji
      }
      
      if givenIconEmoji.last() != ":" {
        givenIconEmoji = givenIconEmoji + ":"
      }
      
      self.iconEmoji = givenIconEmoji
    }
    else {
      self.iconEmoji = iconEmoji
    }
  }
  
  convenience init(webhookURL givenURL: NSURL)
  {
    self.init(webhookURL: givenURL, channel: nil, username: nil, iconEmoji: nil, iconURL: nil)
  }
  
  func sendMessage(messageText: String, completionHandler: slackClientCompletionHandler)
  {
    var messageDict     = self.messageParametersToDictionary()
    messageDict["text"] = messageText

    var err: NSError?
    var messageData     = NSJSONSerialization.dataWithJSONObject(messageDict, options: nil, error: &err)
    if let err = err, completionHandler = completionHandler {
        completionHandler(false, nil, err)
    }
    
    var request         = NSMutableURLRequest(URL: self.webhookURL)
    request.HTTPBody    = messageData
    request.HTTPMethod  = "POST"
    
    self.sendRequest(request, completionHandler: completionHandler)
  }
  
  func sendAttachment(attachment: SlackAttachment, completionHandler: slackClientCompletionHandler)
  {
    var request         = NSMutableURLRequest(URL: self.webhookURL)
    var attachmentDict  = attachment.toDict()
    
    var messageDict     = ["attachments": [attachmentDict]]
 
    var err: NSError?
    var messageData     = NSJSONSerialization.dataWithJSONObject(messageDict, options: nil, error: &err)
    if let err = err, completionHandler = completionHandler {
      completionHandler(false, nil, err)
    }
    
    request.HTTPBody    = messageData
    request.HTTPMethod  = "POST"
    
    self.sendRequest(request, completionHandler: completionHandler);
  }
  
  private func sendRequest(request: NSURLRequest, completionHandler givenCompletionHandler: slackClientCompletionHandler)
  {
    var task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
      if let completion = givenCompletionHandler {
        let success = error == nil && (response as! NSHTTPURLResponse).statusCode == 200
        completion(success, response as? NSHTTPURLResponse, error)
      }
    })
    
    task.resume()
  }
  
  func messageParametersToDictionary () -> [String:String]
  {
    var paramsDict = [String:String]()
    
    if let channel = self.channel {
      paramsDict["channel"] = channel
    }
    if let username = self.username {
      paramsDict["username"] = username
    }
    if let iconEmoji = self.iconEmoji {
      paramsDict["iconEmoji"] = iconEmoji
    }
    if let iconURL = self.iconURL {
      paramsDict["iconURL"] = iconURL.absoluteString
    }
    
    return paramsDict
  }
}

class SlackAttachment
{
  var fallback:   String
  var text:       String
  var title:      String
  var titleLink:  NSURL?
  var color:      UIColor?
  var pretext:    String?
  var authorName: String?
  var authorLink: NSURL?
  var authorIcon: NSURL?
  var fields:     [SlackAttachmentField]?
  var imageURL:   NSURL?
  
  init(fallback: String, title: String, text: String)
  {
    self.fallback = fallback
    self.title    = title
    self.text     = text
  }
  
  func toDict() -> ([String: AnyObject])
  {
    var messageDict: [String: AnyObject] = [
      "fallback": self.fallback,
      "title":    self.title,
      "text":     self.text
    ]
    
    if let pretext = self.pretext {
      messageDict["pretext"] = self.pretext
    }
    
    if let authorName = self.authorName {
      messageDict["author_name"] = self.authorName
    }
    
    if let authorLink = self.authorLink {
      messageDict["author_link"] = authorLink.absoluteString
    }
    
    if let authorIcon = self.authorIcon {
      messageDict["author_icon"] = authorIcon.absoluteString
    }
    
    if let titleLink = self.titleLink {
      messageDict["title_link"] = titleLink.absoluteString
    }
    
    if let imageURL = self.imageURL {
      messageDict["image_url"] = imageURL.absoluteString
    }
    
    if let color = self.color {
      messageDict["color"] = color.hexRGB
    }
    
    if let fields = self.fields {
      
      var fieldList: [[String:AnyObject]] = []
      
      for f in fields {
        fieldList.append( f.toDict() )
      }
      
      messageDict["fields"] = fieldList
    }
    
    return messageDict
  }
}

struct SlackAttachmentField
{
  static var maxLengthForShortField = 40
  
  var title: String
  var value: String

  func isShort () -> (Bool) {
    return title.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= SlackAttachmentField.maxLengthForShortField
        && value.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= SlackAttachmentField.maxLengthForShortField
  }
  
  func toDict() -> ([String: AnyObject]) {
    return [
      "title": self.title,
      "value": self.value,
      "short": self.isShort()
    ]
  }
}

private extension String {
  func first() -> String
  {
    return self.substringWithRange(Range(start: self.startIndex, end: advance(self.startIndex, 1)))
  }
  
  func last() -> String
  {
    return self.substringWithRange(Range(start: advance(self.endIndex, -1), end:self.endIndex))
  }
}

// via http://stackoverflow.com/q/28696862
private extension UIColor
{
  typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
  
  var rgbComponents: RGBComponents {
    var c: RGBComponents = (0,0,0,0)
    
    if getRed(&c.red, green: &c.green, blue: &c.blue, alpha: &c.alpha) {
      return c
    }
    
    return (0,0,0,0)
  }
  
  var hexRGB: String {
    return String(format: "#%02x%02x%02x", Int(rgbComponents.red * 255), Int(rgbComponents.green * 255), Int(rgbComponents.blue * 255))
  }
}



/* TODO
  x change paramDictType to String:String
  no prepend # to channel if missing (channel can be an id, which does not start with #)
  x pre- and post-pend : to iconEmoji if missing
  x connection is lost error
  x toDictionary private method
  x completionHandler for sending message
  - message class
    - convenience sendMessage method
  - attachment class
    x logic for serializing UIColor
    x logic for serializing NSURLs
    x logic for serializing fields
      x logic for determining "short"-ness for fields
    x convenience sendAttachment method
  x typedef for completionHandler
  x factor out NSURLSession-sending code
  - tests!
    x test that iconURL converts to string successfully
    x test SlackAttachmentField.toDict
    x test SlackAttachment.toDict
    x test messageParamtersToDictionary
    x test that correct URL is called
    x test that callback is called correctly for success of sendMessage
    x test that callback is called correctly for server failure of sendMessage
    x test that callback is called correctly for network failure of sendMessage
    x test that callback is called correctly for successful sendAttachment
    x test that callback is called correctly for failed sendAttachment

*/