//
//  MoEngagePluginPersonalizeParserTests.swift
//  MoEngagePluginPersonalizeTests
//
//  Created by MoEngage on 08/04/26.
//

import Testing
import Foundation
@testable import MoEngagePluginPersonalize
import MoEngagePersonalization
import MoEngagePluginBase

// MARK: - Parse Statuses

@Suite("Parse Statuses")
struct ParseStatusesTests {

    @Test("Valid statuses returns matching enums")
    func validStatuses() {
        let payload = makePayload(data: ["status": ["active", "paused", "scheduled"]])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result == [.active, .paused, .scheduled])
    }

    @Test("Mixed case statuses are parsed via lowercased matching")
    func mixedCaseStatuses() {
        let payload = makePayload(data: ["status": ["ACTIVE", "Paused", "SCHEDULED"]])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result == [.active, .paused, .scheduled])
    }

    @Test("Unknown status strings are filtered out")
    func unknownStatuses() {
        let payload = makePayload(data: ["status": ["invalid", "bogus"]])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result.isEmpty)
    }

    @Test("Mix of valid and invalid statuses keeps only valid")
    func mixedValidInvalid() {
        let payload = makePayload(data: ["status": ["active", "bogus", "paused"]])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result == [.active, .paused])
    }

    @Test("Empty status array returns empty")
    func emptyStatusArray() {
        let payload = makePayload(data: ["status": [String]()])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result.isEmpty)
    }

    @Test("Missing data key returns empty")
    func missingDataKey() {
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: [:])
        #expect(result.isEmpty)
    }

    @Test("Missing status key returns empty")
    func missingStatusKey() {
        let payload = makePayload(data: ["other": "value"])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result.isEmpty)
    }

    @Test("Status value is not an array returns empty")
    func statusNotArray() {
        let payload = makePayload(data: ["status": "active"])
        let result = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)
        #expect(result.isEmpty)
    }
}

// MARK: - Parse Single Campaign

@Suite("Parse Single Campaign")
struct ParseSingleCampaignTests {

    @Test("Complete dictionary returns valid campaign")
    func validCampaign() {
        let dict = makeCampaignDict(key: "exp_1", payload: ["k": "v"], context: ["c": "val"])
        let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict)
        #expect(campaign != nil)
        #expect(campaign?.experienceKey == "exp_1")
        #expect(campaign?.payload["k"] as? String == "v")
        #expect(campaign?.experienceContext["c"] as? String == "val")
    }

    @Test("Missing experienceKey returns nil")
    func missingKey() {
        let dict: [String: Any] = [
            "payload": ["k": "v"],
            "experienceContext": ["c": "val"]
        ]
        #expect(MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict) == nil)
    }

    @Test("Missing payload returns nil")
    func missingPayload() {
        let dict: [String: Any] = [
            "experienceKey": "exp_1",
            "experienceContext": ["c": "val"]
        ]
        #expect(MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict) == nil)
    }

    @Test("Missing experienceContext returns nil")
    func missingContext() {
        let dict: [String: Any] = [
            "experienceKey": "exp_1",
            "payload": ["k": "v"]
        ]
        #expect(MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict) == nil)
    }

    @Test("Wrong type for experienceKey returns nil")
    func wrongTypeKey() {
        let dict: [String: Any] = [
            "experienceKey": 123,
            "payload": ["k": "v"],
            "experienceContext": ["c": "val"]
        ]
        #expect(MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict) == nil)
    }

    @Test("Source CACHE is parsed correctly")
    func sourceCacheParsed() {
        var dict = makeCampaignDict()
        dict["source"] = "CACHE"
        let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict)
        #expect(campaign?.source == .cache)
    }

    @Test("Source NETWORK is parsed correctly")
    func sourceNetworkParsed() {
        var dict = makeCampaignDict()
        dict["source"] = "NETWORK"
        let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict)
        #expect(campaign?.source == .network)
    }

    @Test("Missing source defaults to network")
    func missingSourceDefaultsNetwork() {
        let dict = makeCampaignDict()
        let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict)
        #expect(campaign?.source == .network)
    }

    @Test("Empty payload and context dicts are valid")
    func emptyDicts() {
        let dict = makeCampaignDict(key: "exp_1", payload: [:], context: [:])
        let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: dict)
        #expect(campaign != nil)
        #expect(campaign?.experienceKey == "exp_1")
    }
}

// MARK: - Parse Campaigns

@Suite("Parse Campaigns")
struct ParseCampaignsTests {

    @Test("Valid payload with multiple experiences")
    func multipleExperiences() {
        let payload = makePayload(data: [
            "experiences": [
                makeCampaignDict(key: "exp_1"),
                makeCampaignDict(key: "exp_2")
            ]
        ])
        let result = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        #expect(result?.count == 2)
        #expect(result?[0].experienceKey == "exp_1")
        #expect(result?[1].experienceKey == "exp_2")
    }

    @Test("Empty experiences array returns empty array not nil")
    func emptyExperiencesArray() {
        let payload = makePayload(data: ["experiences": [[String: Any]]()])
        let result = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        #expect(result != nil)
        #expect(result?.isEmpty == true)
    }

    @Test("Missing data key returns nil")
    func missingDataKey() {
        let result = MoEngagePluginPersonalizeParser.parseCampaigns(from: [:])
        #expect(result == nil)
    }

    @Test("Missing experiences key returns nil")
    func missingExperiencesKey() {
        let payload = makePayload(data: ["other": "value"])
        let result = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        #expect(result == nil)
    }

    @Test("Mix of valid and invalid experiences filters correctly")
    func mixedValidInvalid() {
        let invalid: [String: Any] = ["experienceKey": "bad"]  // missing payload & context
        let payload = makePayload(data: [
            "experiences": [
                makeCampaignDict(key: "good"),
                invalid
            ]
        ])
        let result = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        #expect(result?.count == 1)
        #expect(result?.first?.experienceKey == "good")
    }
}

// MARK: - Test Helpers

private func makePayload(data: [String: Any]) -> [String: Any] {
    return ["accountMeta": ["appId": "test_app"], "data": data]
}

private func makeCampaignDict(
    key: String = "exp_default",
    payload: [String: Any] = ["key": "value"],
    context: [String: Any] = ["contextKey": "contextValue"]
) -> [String: Any] {
    return [
        "experienceKey": key,
        "payload": payload,
        "experienceContext": context
    ]
}
