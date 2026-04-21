//
//  MoEngagePluginPersonalizeConstantsTests.swift
//  MoEngagePluginPersonalizeTests
//
//  Created by MoEngage on 08/04/26.
//

import Testing
import Foundation
@testable import MoEngagePluginPersonalize

@Suite("Constants Verification")
struct ConstantsVerificationTests {

    @Test("DataSource values are uppercase")
    func dataSourceUppercase() {
        #expect(MoEngagePluginPersonalizeConstants.DataSourceValues.cache == "CACHE")
        #expect(MoEngagePluginPersonalizeConstants.DataSourceValues.network == "NETWORK")
    }

    @Test("Experience status values are lowercase")
    func statusLowercase() {
        #expect(MoEngagePluginPersonalizeConstants.ExperienceStatusValues.active == "active")
        #expect(MoEngagePluginPersonalizeConstants.ExperienceStatusValues.paused == "paused")
        #expect(MoEngagePluginPersonalizeConstants.ExperienceStatusValues.scheduled == "scheduled")
    }

    @Test("All failure reason strings are non-empty and unique")
    func failureReasonsUniqueAndNonEmpty() {
        let allReasons = [
            MoEngagePluginPersonalizeConstants.FailureReasons.userInCampaignControlGroup,
            MoEngagePluginPersonalizeConstants.FailureReasons.userInGlobalControlGroup,
            MoEngagePluginPersonalizeConstants.FailureReasons.userNotInSegment,
            MoEngagePluginPersonalizeConstants.FailureReasons.invalidExperienceKey,
            MoEngagePluginPersonalizeConstants.FailureReasons.maxLimitBreached,
            MoEngagePluginPersonalizeConstants.FailureReasons.experienceNotActive,
            MoEngagePluginPersonalizeConstants.FailureReasons.experienceExpired,
            MoEngagePluginPersonalizeConstants.FailureReasons.personalizationFailed,
            MoEngagePluginPersonalizeConstants.FailureReasons.sdkNotInitialized,
            MoEngagePluginPersonalizeConstants.FailureReasons.sdkDisabled,
            MoEngagePluginPersonalizeConstants.FailureReasons.featureDisabled,
            MoEngagePluginPersonalizeConstants.FailureReasons.networkError,
            MoEngagePluginPersonalizeConstants.FailureReasons.httpError,
            MoEngagePluginPersonalizeConstants.FailureReasons.parseError,
            MoEngagePluginPersonalizeConstants.FailureReasons.unknownServerError,
            MoEngagePluginPersonalizeConstants.FailureReasons.unknown
        ]

        for reason in allReasons {
            #expect(!reason.isEmpty, "\(reason) should not be empty")
        }

        let uniqueReasons = Set(allReasons)
        #expect(uniqueReasons.count == allReasons.count, "All failure reasons should be unique")
    }

    @Test("Request key constants match contract JSON keys")
    func requestKeysMatchContract() {
        #expect(MoEngagePluginPersonalizeConstants.Personalize.status == "status")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experienceKeys == "experienceKeys")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.attributes == "attributes")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experiences == "experiences")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experienceKey == "experienceKey")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experienceContext == "experienceContext")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experience == "experience")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.offeringPayloads == "offeringPayloads")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.offeringPayload == "offeringPayload")
    }

    @Test("Response key constants match contract JSON keys")
    func responseKeysMatchContract() {
        #expect(MoEngagePluginPersonalizeConstants.Personalize.experienceName == "experienceName")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.source == "source")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.failures == "failures")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.reason == "reason")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.message == "message")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.code == "code")
        #expect(MoEngagePluginPersonalizeConstants.Personalize.error == "error")
    }
}
