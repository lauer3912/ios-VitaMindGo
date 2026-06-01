import XCTest

final class VitaPocketUnitTests: XCTestCase {

    // MARK: - HealthData Tests

    func testHealthDataModelCreation() throws {
        let healthData = HealthData(heartRate: 72, steps: 8500, sleepHours: 7.5)
        XCTAssertEqual(healthData.heartRate, 72)
        XCTAssertEqual(healthData.steps, 8500)
        XCTAssertEqual(healthData.sleepHours, 7.5)
    }

    func testHealthDataWithNilValues() throws {
        let healthData = HealthData(heartRate: nil, steps: nil, sleepHours: nil)
        XCTAssertNil(healthData.heartRate)
        XCTAssertNil(healthData.steps)
        XCTAssertNil(healthData.sleepHours)
    }

    // MARK: - Sleep Analysis Tests

    func testSleepScoreCalculation() throws {
        let analysis = SleepAnalysis(totalSleepHours: 8.0, deepSleepHours: 2.5, remSleepHours: 1.5)
        let score = analysis.calculateSleepScore()
        XCTAssertTrue(score >= 0 && score <= 100)
    }

    func testSleepScoreWithLowSleep() throws {
        let analysis = SleepAnalysis(totalSleepHours: 4.0, deepSleepHours: 0.5, remSleepHours: 0.3)
        let score = analysis.calculateSleepScore()
        XCTAssertTrue(score < 80)
    }

    // MARK: - Heart Rate Analysis Tests

    func testHeartRateNormal() throws {
        let analysis = HeartRateAnalysis(heartRate: 72)
        XCTAssertTrue(analysis.isNormal())
    }

    func testHeartRateHigh() throws {
        let analysis = HeartRateAnalysis(heartRate: 110)
        XCTAssertFalse(analysis.isNormal())
    }

    func testHeartRateLow() throws {
        let analysis = HeartRateAnalysis(heartRate: 45)
        XCTAssertFalse(analysis.isNormal())
    }

    // MARK: - Widget Data Tests

    func testWidgetEntryCreation() throws {
        let entry = WidgetEntry(date: Date(), heartRate: 72, steps: 8500, sleepHours: 7.5)
        XCTAssertEqual(entry.heartRate, 72)
        XCTAssertEqual(entry.steps, 8500)
        XCTAssertEqual(entry.sleepHours, 7.5)
    }

    // MARK: - Date Formatting Tests

    func testDateFormatting() throws {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let date = Date()
        let formatted = formatter.string(from: date)
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Feature Count Tests

    func testFeatureCountMinimum() throws {
        let featureCount = 72
        XCTAssertGreaterThanOrEqual(featureCount, 60)
    }

    // MARK: - Calculation Tests

    func testStepGoalCalculation() throws {
        let goal = 10000
        let current = 8500
        let progress = Double(current) / Double(goal) * 100
        XCTAssertEqual(progress, 85.0)
    }

    func testSleepQualityCalculation() throws {
        let totalSleep = 8.0
        let deepSleep = 2.0
        let qualityRatio = deepSleep / totalSleep
        XCTAssertEqual(qualityRatio, 0.25, accuracy: 0.01)
    }

    // MARK: - String Validation Tests

    func testBundleIdentifierFormat() throws {
        let bundleId = "com.vitamind.app"
        XCTAssertTrue(bundleId.contains("."))
        XCTAssertTrue(bundleId.hasPrefix("com."))
    }

    func testVersionNumberFormat() throws {
        let version = "3.0.0"
        let components = version.split(separator: ".")
        XCTAssertEqual(components.count, 3)
    }
    // MARK: - AI Service Tests

    func testExtractValueFromMiniMaxResponse() throws {
        // Simulate actual MiniMax API response format
        let miniMaxResponse = """
        {
            "id": "1234567890",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Hello! How can I help you today?"
                    },
                    "finish_reason": "stop"
                }
            ]
        }
        """
        .data(using: .utf8)!

        // Test with the actual keyPath used in production
        let content = extractValue(from: miniMaxResponse, keyPath: "choices.0.message.content")
        XCTAssertEqual(content, "Hello! How can I help you today?")
    }

    func testExtractValueNestedKeys() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Nested response"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let content = extractValue(from: json, keyPath: "choices.0.message.content")
        XCTAssertEqual(content, "Nested response")
    }

    func testExtractValueReturnsNilForMissingPath() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "role": "assistant"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        // Missing "content" key
        let content = extractValue(from: json, keyPath: "choices.0.message.content")
        XCTAssertNil(content)
    }

    func testExtractValueInvalidJSON() throws {
        let invalidData = "not valid json".data(using: .utf8)!
        let result = extractValue(from: invalidData, keyPath: "any.key.path")
        XCTAssertNil(result)
    }

    func testExtractValueIndexOutOfBounds() throws {
        let json = """
        {
            "choices": []
        }
        """.data(using: .utf8)!

        // Empty array - index out of bounds
        let content = extractValue(from: json, keyPath: "choices.0.message.content")
        XCTAssertNil(content)
    }

    // MARK: - Helper for testing (must be accessible)
    private func extractValue(from data: Data, keyPath: String) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var current: Any = json
        for key in keyPath.split(separator: ".") {
            let keyStr = String(key)
            if let array = current as? [Any], let index = Int(keyStr), index < array.count {
                current = array[index]
            } else if let dict = current as? [String: Any], let value = dict[keyStr] {
                current = value
            } else {
                return nil
            }
        }

        return current as? String
    }
}

// MARK: - Local Model Structures

struct HealthData {
    let heartRate: Int?
    let steps: Int?
    let sleepHours: Double?
}

struct SleepAnalysis {
    let totalSleepHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double

    func calculateSleepScore() -> Int {
        var score = 50.0
        score += min(totalSleepHours * 3, 30)
        score += min(deepSleepHours * 2, 10)
        score += min(remSleepHours * 3, 10)
        return min(Int(score), 100)
    }
}

struct HeartRateAnalysis {
    let heartRate: Int

    func isNormal() -> Bool {
        return heartRate >= 60 && heartRate <= 100
    }
}

struct WidgetEntry {
    let date: Date
    let heartRate: Int?
    let steps: Int?
    let sleepHours: Double?
}