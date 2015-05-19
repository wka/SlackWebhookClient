//
//  SlackWebhookClientTests.swift
//

import UIKit
import XCTest
import OHHTTPStubs

class SlackWebhookClientTests: XCTestCase {

  override func tearDown() {
    super.tearDown()
    
    OHHTTPStubs.removeAllStubs()
  }

  func testInit()
  {
    let fullInitClient = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!, channel: nil, username: nil, iconEmoji: nil, iconURL: nil)

    XCTAssertNotNil(fullInitClient, "Standard init works")
    
    let simpleInitClient = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!)
    XCTAssertNotNil(simpleInitClient, "Convenience init works")
  }
  
  func testIconEmojiProcessing()
  {
    
    let expectedEmojiString     = ":thumbsup:"
    
    let correctEmojiClient      = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!, channel: nil, username: nil, iconEmoji: ":thumbsup:", iconURL: nil)
    let missingFirstColonClient = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!, channel: nil, username: nil, iconEmoji:  "thumbsup:", iconURL: nil)
    let missingLastColonClient  = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!, channel: nil, username: nil, iconEmoji: ":thumbsup",  iconURL: nil)
    let noColonsClient          = SlackWebhookClient(webhookURL: NSURL(string: "http://example.com")!, channel: nil, username: nil, iconEmoji:  "thumbsup",  iconURL: nil)

    XCTAssertEqual(correctEmojiClient.iconEmoji!,      expectedEmojiString, "Correct emoji not mangled")
    XCTAssertEqual(missingFirstColonClient.iconEmoji!, expectedEmojiString, "Missing first : emoji fixed correctly")
    XCTAssertEqual(missingLastColonClient.iconEmoji!,  expectedEmojiString, "Missing last : emoji fixed correctly")
    XCTAssertEqual(noColonsClient.iconEmoji!,          expectedEmojiString, "No colons emoji fixed correctly")
  }
  
  func testMessageParametersToDictionary()
  {
    let webhookURL  = NSURL(string: "http://example.com")!
    let channelName = "#puppies"
    let username    = "bob"
    let iconEmoji   = ":thumbsup:"
    let iconURL     = NSURL(string: "http://example.com/example.png")!
    
    let client      = SlackWebhookClient(webhookURL: webhookURL, channel: channelName, username: username, iconEmoji: iconEmoji, iconURL: iconURL)
    
    let outputDict  = client.messageParametersToDictionary()
    
    XCTAssertTrue(outputDict["channel"]!   == channelName,             "Correct channel")
    XCTAssertTrue(outputDict["username"]!  == username,                "Correct username")
    XCTAssertTrue(outputDict["iconEmoji"]! == iconEmoji,               "Correct icon emoji")
    XCTAssertTrue(outputDict["iconURL"]!   == iconURL.absoluteString!, "Correct icon URL")
  }
  
  func testEmptyMessageParametersToDictionary()
  {
    let webhookURL  = NSURL(string: "http://example.com")!
    let client      = SlackWebhookClient(webhookURL: webhookURL)
    
    let outputDict  = client.messageParametersToDictionary()
    
    XCTAssertTrue(outputDict.count == 0, "Empty output dictionary when all webhook client params are nil")
  }
  
  func testAttachmentFieldToDict()
  {

    SlackAttachmentField.maxLengthForShortField = 50
    
    let field = SlackAttachmentField(title: "Headline", value: "Description")
    let fieldDict = field.toDict()

    XCTAssertTrue(fieldDict["title"] as! String == "Headline",    "Title matches")
    XCTAssertTrue(fieldDict["value"] as! String == "Description", "Value matches")
    XCTAssertTrue(fieldDict["short"] as! Bool, "Short fields are short")
  }
  
  func testAttachmentFieldIsShort()
  {

    SlackAttachmentField.maxLengthForShortField = 50
    let field = SlackAttachmentField(title: "Headline", value: "Description")
    XCTAssertTrue(field.isShort(), "Field title and value under maxLengthForShortField chars are marked short")
    
    SlackAttachmentField.maxLengthForShortField = 5
    let otherField = SlackAttachmentField(title: "Headline", value: "Description")
    XCTAssertFalse(otherField.isShort(), "Field title and value over maxLengthForShortField chars are not marked short")

  }
  
  func testAttachmentToDict()
  {
    let fallbackValue     = "Fallback message text"
    let titleValue        = "Welcome!"
    let textValue         = "Text of the attachment"
    let titleLinkValue    = NSURL(string: "http://example.com")!
    let colorValue        = UIColor(red: 0.215, green: 0.222, blue: 0.830, alpha: 1.0)
    let pretextValue      = "Borring a cup of sugar"
    let authorNameValue   = "Edward Bulwer-Lytton"
    let authorLinkValue   = NSURL(string: "http://www.bulwer-lytton.com")!
    let authorIconValue   = NSURL(string: "http://www.bulwer-lytton.com/images/snoopydark.png")!
    let imageURLValue     = NSURL(string: "http://example.com/example.png")!
    
    let attachment        = SlackAttachment(fallback: fallbackValue, title: titleValue, text: textValue)
    attachment.titleLink  = titleLinkValue
    attachment.color      = colorValue
    attachment.pretext    = pretextValue
    attachment.authorName = authorNameValue
    attachment.authorLink = authorLinkValue
    attachment.authorIcon = authorIconValue
    attachment.imageURL   = imageURLValue

    let firstFieldTitle   = "Head1"
    let firstFieldValue   = "Desc1"
    let secondFieldTitle  = "Head2"
    let secondFieldValue  = "Desc2"
    
    attachment.fields     = [
      SlackAttachmentField(title: firstFieldTitle, value: firstFieldValue),
      SlackAttachmentField(title: secondFieldTitle, value: secondFieldValue)
    ]
    
    let attachmentDict = attachment.toDict()
    
    XCTAssertEqual(attachmentDict["fallback"]    as! String, fallbackValue,   "Correct value for fallback in dictionary")
    XCTAssertEqual(attachmentDict["title"]       as! String, titleValue,      "Correct value for title in dictionary")
    XCTAssertEqual(attachmentDict["color"]       as! String, "#3638d3",       "Correct value for color in dictionary")
    XCTAssertEqual(attachmentDict["pretext"]     as! String, pretextValue,    "Correct value for pretext in dictionary")
    XCTAssertEqual(attachmentDict["author_name"] as! String, authorNameValue, "Correct value for author name in dictionary")
    
    XCTAssertEqual(attachmentDict["author_link"] as! String, authorLinkValue.absoluteString!, "Correct value for author name in dictionary")
    XCTAssertEqual(attachmentDict["author_icon"] as! String, authorIconValue.absoluteString!, "Correct value for author icon in dictionary")
    XCTAssertEqual(attachmentDict["title_link"]  as! String, titleLinkValue.absoluteString!,  "Correct value for title link in dictionary")
    XCTAssertEqual(attachmentDict["image_url"]   as! String, imageURLValue.absoluteString!,   "Correct value for image url in dictionary")
    
    var fieldsFromDict = attachmentDict["fields"]! as! [[String:AnyObject]]
    var first = fieldsFromDict[0]
    
    XCTAssertTrue(fieldsFromDict.count == 2, "Correct number of fields")
    XCTAssertTrue(fieldsFromDict[0]["title"] as! String == firstFieldTitle,  "Correct value for 1st field title")
    XCTAssertTrue(fieldsFromDict[0]["value"] as! String == firstFieldValue,  "Correct value for 1st field value")
    XCTAssertTrue(fieldsFromDict[1]["title"] as! String == secondFieldTitle, "Correct value for 2nd field title")
    XCTAssertTrue(fieldsFromDict[1]["value"] as! String == secondFieldValue, "Correct value for 2nd field value")

  }
  
  func testSuccessfulSendMessageCall()
  {
    let givenURL = NSURL(string: "http://webhook.exmaple.com")!
    
    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
        return OHHTTPStubsResponse(data: NSData(), statusCode: 200, headers: nil)
    }

    var expectation = self.expectationWithDescription("sendMessage success")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    client.sendMessage("testing", completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertTrue(success, "success is true after successful sendMessage call")
      XCTAssertNil(error, "error object is nil after successful sendMessage call")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
  func testFailedSendMessageCallWithServerError()
  {
    let givenURL = NSURL(string: "http://webhook.exmaple.com")!
    
    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
      return OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: nil)
    }
    
    var expectation = self.expectationWithDescription("sendMessage failure: server error")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    client.sendMessage("testing", completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertFalse(success, "success is false after failed sendMessage call")
      XCTAssertNil(error, "error object is nil after sendMessage call with 404 status")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
  func testFailedSendMessageCallWithNetworkError()
  {
    let givenURL    = NSURL(string: "http://webhook.exmaple.com")!
    let errorCode   = -123
    let errorDomain = "com.test.domain"
    
    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
      var response = OHHTTPStubsResponse(data: NSData(), statusCode: 1, headers: nil)
      response.error = NSError(domain: errorDomain, code: errorCode, userInfo: nil)
      return response
    }
    
    var expectation = self.expectationWithDescription("sendMessage failure: network error")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    client.sendMessage("testing", completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertFalse(success, "success is false after failed sendMessage call")
      XCTAssertEqual(error!.code, errorCode, "Correct error code received")
      XCTAssertEqual(error!.domain, errorDomain, "Correct error domain received")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
  func testSuccessfulSendAttachmentCall()
  {
    let givenURL = NSURL(string: "http://webhook.exmaple.com")!
    
    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
      return OHHTTPStubsResponse(data: NSData(), statusCode: 200, headers: nil)
    }
    
    var expectation = self.expectationWithDescription("sendAttachment success")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    let attachment = SlackAttachment(fallback: "hi", title: "Hello!", text: "Hi there!")
    
    client.sendAttachment(attachment, completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertTrue(success, "success is true after successful sendAttachment call")
      XCTAssertNil(error, "error object is nil after successful sendAttachment call")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFailedSendAttachmentCallWithServerError()
  {
    let givenURL = NSURL(string: "http://webhook.exmaple.com")!
    
    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
      return OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: nil)
    }
    
    var expectation = self.expectationWithDescription("sendAttachment failed: server error")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    let attachment = SlackAttachment(fallback: "hi", title: "Hello!", text: "Hi there!")
    
    client.sendAttachment(attachment, completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertFalse(success, "success is false after failed sendAttachment call")
      XCTAssertNil(error, "error object is nil after sendAttachment call with 404 status")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testFailedSendAttachmentCallWithNetworkError()
  {
    let givenURL    = NSURL(string: "http://webhook.exmaple.com")!
    let errorCode   = -123
    let errorDomain = "com.test.domain"

    OHHTTPStubs.stubRequestsPassingTest({ $0.URL!.host == givenURL.host! }) { _ in
      var response = OHHTTPStubsResponse(data: NSData(), statusCode: 1, headers: nil)
      response.error = NSError(domain: errorDomain, code: errorCode, userInfo: nil)
      return response
    }
    
    var expectation = self.expectationWithDescription("sendAttachment failed: network error")
    
    let client = SlackWebhookClient(webhookURL: givenURL)
    let attachment = SlackAttachment(fallback: "hi", title: "Hello!", text: "Hi there!")
    
    client.sendAttachment(attachment, completionHandler: { (success, response, error) -> (Void) in
      expectation.fulfill()
      XCTAssertFalse(success, "success is false after failed sendAttachment call")
      XCTAssertEqual(error!.code, errorCode, "Correct error code received")
      XCTAssertEqual(error!.domain, errorDomain, "Correct error domain received")
    })
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }

}



























