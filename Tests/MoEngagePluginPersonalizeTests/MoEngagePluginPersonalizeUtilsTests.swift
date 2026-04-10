//
//  MoEngagePluginPersonalizeUtilsTests.swift
//  MoEngagePluginPersonalizeTests
//
//  Created by MoEngage on 08/04/26.
//

import Testing
import Foundation
@testable import MoEngagePluginPersonalize
import MoEngagePersonalization
import MoEngagePluginBase

// MARK: - Metadata to JSON

@Suite("Metadata to JSON")
struct MetadataToJSONTests {

    @Test("Single experience metadata serializes correctly")
    func singleExperience() {
        let meta = MoEngageExperienceCampaignMetaData(
            source: .network,
            experienceCampaignMeta: [
                MoEngageExperienceCampaignMetaDetail(
                    experienceKey: "exp_1",
                    experienceName: "Welcome Banner",
                    status: .active
                )
            ]
        )

        let json = MoEngagePluginPersonalizeUtils.metadataToJSON(metadata: meta, identifier: "test_app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]

        #expect(data?["source"] as? String == "NETWORK")
        #expect(experiences?.count == 1)
        #expect(experiences?[0]["experienceKey"] as? String == "exp_1")
        #expect(experiences?[0]["experienceName"] as? String == "Welcome Banner")
        #expect(experiences?[0]["status"] as? String == "active")
    }

    @Test("Multiple experiences all serialized")
    func multipleExperiences() {
        let meta = MoEngageExperienceCampaignMetaData(
            source: .cache,
            experienceCampaignMeta: [
                MoEngageExperienceCampaignMetaDetail(experienceKey: "exp_1", experienceName: "A", status: .active),
                MoEngageExperienceCampaignMetaDetail(experienceKey: "exp_2", experienceName: "B", status: .paused),
                MoEngageExperienceCampaignMetaDetail(experienceKey: "exp_3", experienceName: "C", status: .scheduled)
            ]
        )

        let json = MoEngagePluginPersonalizeUtils.metadataToJSON(metadata: meta, identifier: "test_app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]

        #expect(data?["source"] as? String == "CACHE")
        #expect(experiences?.count == 3)
    }

    @Test("Empty experiences array serializes as empty")
    func emptyExperiences() {
        let meta = MoEngageExperienceCampaignMetaData(source: .network, experienceCampaignMeta: [])
        let json = MoEngagePluginPersonalizeUtils.metadataToJSON(metadata: meta, identifier: "test_app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]

        #expect(experiences?.isEmpty == true)
    }

    @Test("All status types serialize to correct strings")
    func statusSerialization() {
        let statuses: [(MoEngageExperienceStatus, String)] = [
            (.active, "active"),
            (.paused, "paused"),
            (.scheduled, "scheduled")
        ]

        for (status, expected) in statuses {
            let meta = MoEngageExperienceCampaignMetaData(
                source: .network,
                experienceCampaignMeta: [
                    MoEngageExperienceCampaignMetaDetail(experienceKey: "k", experienceName: "n", status: status)
                ]
            )
            let json = MoEngagePluginPersonalizeUtils.metadataToJSON(metadata: meta, identifier: "app")
            let data = json["data"] as? [String: Any]
            let experiences = data?["experiences"] as? [[String: Any]]
            #expect(experiences?[0]["status"] as? String == expected)
        }
    }

    @Test("accountMeta contains identifier")
    func accountMetaPresent() {
        let meta = MoEngageExperienceCampaignMetaData(source: .network, experienceCampaignMeta: [])
        let json = MoEngagePluginPersonalizeUtils.metadataToJSON(metadata: meta, identifier: "my_app")
        let accountMeta = json["accountMeta"] as? [String: Any]

        #expect(accountMeta != nil)
    }
}

// MARK: - Experience Result to JSON

@Suite("Experience Result to JSON")
struct ExperienceResultToJSONTests {

    @Test("Result with experiences only")
    func experiencesOnly() {
        let result = MoEngageExperienceCampaignsResult(
            experiences: [
                MoEngageExperienceCampaign(
                    experienceKey: "exp_1",
                    payload: ["offer": "50%"],
                    experienceContext: ["cid": "123"],
                    source: .cache
                )
            ],
            failures: []
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]
        let failures = data?["failures"] as? [[String: Any]]

        #expect(experiences?.count == 1)
        #expect(experiences?[0]["experienceKey"] as? String == "exp_1")
        #expect(experiences?[0]["source"] as? String == "CACHE")
        #expect((experiences?[0]["payload"] as? [String: Any])?["offer"] as? String == "50%")
        #expect((experiences?[0]["experienceContext"] as? [String: Any])?["cid"] as? String == "123")
        #expect(failures?.isEmpty == true)
    }

    @Test("Result with failures only")
    func failuresOnly() {
        let result = MoEngageExperienceCampaignsResult(
            experiences: [],
            failures: [
                MoEngageExperienceFailureReason(
                    code: .invalidExperienceKey,
                    message: "Key not found",
                    experienceKeys: ["bad_key"]
                )
            ]
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]
        let failures = data?["failures"] as? [[String: Any]]

        #expect(experiences?.isEmpty == true)
        #expect(failures?.count == 1)
        #expect(failures?[0]["reason"] as? String == "IN_VALID_EXPERIENCE_KEY")
        #expect(failures?[0]["message"] as? String == "Key not found")
        #expect((failures?[0]["experienceKeys"] as? [String])?.first == "bad_key")
    }

    @Test("Result with both experiences and failures")
    func bothExperiencesAndFailures() {
        let result = MoEngageExperienceCampaignsResult(
            experiences: [
                MoEngageExperienceCampaign(experienceKey: "ok", payload: [:], experienceContext: [:], source: .network)
            ],
            failures: [
                MoEngageExperienceFailureReason(code: .userNotInSegment, message: "Not in segment", experienceKeys: ["bad"])
            ]
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]
        let failures = data?["failures"] as? [[String: Any]]

        #expect(experiences?.count == 1)
        #expect(failures?.count == 1)
    }

    @Test("Failure with nil experienceKeys serializes as empty array")
    func nilExperienceKeys() {
        let result = MoEngageExperienceCampaignsResult(
            experiences: [],
            failures: [
                MoEngageExperienceFailureReason(code: .networkError, message: "Timeout")
            ]
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let failures = data?["failures"] as? [[String: Any]]
        let keys = failures?[0]["experienceKeys"] as? [String]

        #expect(keys?.isEmpty == true)
    }

    @Test("Experience payload and context pass through as-is")
    func payloadPassthrough() {
        let nestedPayload: [String: Any] = ["level1": ["level2": "deep"], "number": 42]
        let result = MoEngageExperienceCampaignsResult(
            experiences: [
                MoEngageExperienceCampaign(
                    experienceKey: "exp",
                    payload: nestedPayload,
                    experienceContext: ["ctx": "val"],
                    source: .network
                )
            ],
            failures: []
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]
        let payload = experiences?[0]["payload"] as? [String: Any]

        #expect(payload?["number"] as? Int == 42)
        #expect((payload?["level1"] as? [String: Any])?["level2"] as? String == "deep")
    }
}

// MARK: - Error to JSON

@Suite("Error to JSON")
struct ErrorToJSONTests {

    @Test("Error serializes with code and message")
    func basicError() {
        let error = MoEngageExperienceFailureReason(
            code: .sdkNotInitialized,
            message: "SDK not initialized"
        )

        let json = MoEngagePluginPersonalizeUtils.errorToJSON(error: error, identifier: "app")
        let errorData = json["error"] as? [String: Any]

        #expect(errorData?["code"] as? String == "SDK_NOT_INITIALIZED")
        #expect(errorData?["message"] as? String == "SDK not initialized")
    }

    @Test("Error response has error key not data key")
    func errorKeyStructure() {
        let error = MoEngageExperienceFailureReason(code: .featureDisabled, message: "Disabled")
        let json = MoEngagePluginPersonalizeUtils.errorToJSON(error: error, identifier: "app")

        #expect(json["error"] != nil)
        #expect(json["data"] == nil)
    }

    @Test("Error response includes accountMeta")
    func accountMetaPresent() {
        let error = MoEngageExperienceFailureReason(code: .networkError, message: "Timeout")
        let json = MoEngagePluginPersonalizeUtils.errorToJSON(error: error, identifier: "my_app")

        #expect(json["accountMeta"] != nil)
    }
}

// MARK: - Failure Reason Mapping

@Suite("Failure Reason Mapping")
struct FailureReasonMappingTests {

    @Test("All failure reason codes map to correct strings")
    func allCodesMapCorrectly() {
        let expectedMappings: [(MoEngageExperienceFailureReasonCode, String)] = [
            (.userInCampaignControlGroup, "USER_IN_CAMPAIGN_CONTROL_GROUP"),
            (.userInGlobalControlGroup, "USER_IN_GLOBAL_CONTROL_GROUP"),
            (.userNotInSegment, "USER_NOT_IN_SEGMENT"),
            (.invalidExperienceKey, "IN_VALID_EXPERIENCE_KEY"),
            (.maxLimitBreached, "MAX_LIMIT_BREACHED"),
            (.campaignNotActive, "EXPERIENCE_NOT_ACTIVE"),
            (.campaignExpired, "EXPERIENCE_EXPIRED"),
            (.personalizationFailed, "PERSONALIZATION_FAILED"),
            (.sdkNotInitialized, "SDK_NOT_INITIALIZED"),
            (.sdkDisabled, "SDK_DISABLED"),
            (.featureDisabled, "FEATURE_DISABLED"),
            (.networkError, "NETWORK_ERROR"),
            (.httpError, "HTTP_ERROR"),
            (.parseError, "PARSE_ERROR"),
            (.unknownServerError, "UNKNOWN_SERVER_ERROR"),
            (.unknownError, "UNKNOWN")
        ]

        for (code, expectedString) in expectedMappings {
            let error = MoEngageExperienceFailureReason(code: code, message: "test")
            let json = MoEngagePluginPersonalizeUtils.errorToJSON(error: error, identifier: "app")
            let errorData = json["error"] as? [String: Any]
            let codeString = errorData?["code"] as? String

            #expect(codeString == expectedString, "Expected \(code) to map to \(expectedString), got \(codeString ?? "nil")")
        }
    }
}
