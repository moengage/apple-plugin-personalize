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
        #expect(failures?[0]["reason"] as? String == "INVALID_EXPERIENCE_KEY")
        #expect((failures?[0]["experienceKeys"] as? [String])?.first == "bad_key")
        #expect(failures?[0]["message"] == nil)
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

    @Test("Offerings envelope is unwrapped to a stringified JSON array")
    func offeringsEnvelopeUnwrapped() {
        // Real-world MOEN-44566 reproduction shape: server wraps offerings as
        // { value: "[stringified JSON array]", data_type: "string" }.
        let offeringsJsonString = "[{\"dp_offering_id\":\"offer_1\",\"offering_content\":{\"type\":\"json\"},\"offering_context\":{\"moe_offering_id\":\"offer_1\"}}]"
        let envelopedPayload: [String: Any] = [
            "offerings": [
                "value": offeringsJsonString,
                "data_type": "string"
            ]
        ]
        let result = MoEngageExperienceCampaignsResult(
            experiences: [
                MoEngageExperienceCampaign(
                    experienceKey: "offr321",
                    payload: envelopedPayload,
                    experienceContext: ["cid": "abc"],
                    source: .network
                )
            ],
            failures: []
        )

        let json = MoEngagePluginPersonalizeUtils.experienceResultToJSON(result: result, identifier: "app")
        let data = json["data"] as? [String: Any]
        let experiences = data?["experiences"] as? [[String: Any]]
        let payload = experiences?[0]["payload"] as? [String: Any]

        // After unwrap, payload[offerings] is the inner stringified JSON array — not the envelope.
        #expect(payload?["offerings"] as? String == offeringsJsonString)
        // Envelope keys must be gone.
        #expect((payload?["offerings"] as? [String: Any]) == nil)
    }
}

// MARK: - Unwrap Payload

@Suite("Unwrap Payload")
struct UnwrapPayloadTests {

    @Test("Envelope with String value lifts the inner string")
    func stringEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": "hello", "data_type": "string"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["k"] as? String == "hello")
    }

    @Test("Envelope with Int value lifts the inner number")
    func numberEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": 42, "data_type": "number"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["k"] as? Int == 42)
    }

    @Test("Envelope with Double value lifts the inner double")
    func floatEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": 3.14, "data_type": "float"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["k"] as? Double == 3.14)
    }

    @Test("Envelope with Bool value lifts the inner bool")
    func booleanEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": true, "data_type": "boolean"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["k"] as? Bool == true)
    }

    @Test("Envelope with Dict value lifts the inner dict")
    func jsonDictEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": ["nested": "obj"], "data_type": "json"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        let lifted = out["k"] as? [String: Any]
        #expect(lifted?["nested"] as? String == "obj")
    }

    @Test("Envelope with Array value lifts the inner array")
    func jsonArrayEnvelope() {
        let raw: [String: Any] = [
            "k": ["value": [1, 2, 3], "data_type": "json"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect((out["k"] as? [Int]) == [1, 2, 3])
    }

    @Test("Entry without `value` key passes through unchanged")
    func nonEnvelopeDictPassthrough() {
        // Dict with no `value` key — not an envelope. Pass-through.
        let raw: [String: Any] = [
            "k": ["unrelated": "data", "data_type": "string"]
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        let entry = out["k"] as? [String: Any]
        #expect(entry?["unrelated"] as? String == "data")
        #expect(entry?["data_type"] as? String == "string")
    }

    @Test("Primitive entry (not a dict) passes through unchanged")
    func primitivePassthrough() {
        let raw: [String: Any] = [
            "s": "raw string",
            "n": 7,
            "b": false
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["s"] as? String == "raw string")
        #expect(out["n"] as? Int == 7)
        #expect(out["b"] as? Bool == false)
    }

    @Test("Empty payload returns empty payload")
    func emptyPayload() {
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload([:])
        #expect(out.isEmpty)
    }

    @Test("Multiple entries with mixed shapes are each handled")
    func mixedEntries() {
        let raw: [String: Any] = [
            "wrapped": ["value": "lifted", "data_type": "string"],
            "raw": "passthrough",
            "halfwrapped": ["data_type": "string"]   // missing value → pass-through
        ]
        let out = MoEngagePluginPersonalizeUtils.unwrapPayload(raw)
        #expect(out["wrapped"] as? String == "lifted")
        #expect(out["raw"] as? String == "passthrough")
        #expect((out["halfwrapped"] as? [String: Any])?["data_type"] as? String == "string")
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
            (.invalidExperienceKey, "INVALID_EXPERIENCE_KEY"),
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
