//
//  TaskExtractionService.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import Foundation

struct TaskExtractionResponse: Codable {
    let isTask: Bool
    let confidence: Double
    let title: String?
    let deadline: String? // ISO 8601 date string
    let content: String?
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
    let response_format: ResponseFormat?

    struct ResponseFormat: Codable {
        let type: String // "json_object"
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: OpenAIMessage
    }
}

@MainActor
class TaskExtractionService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String?

    // Cache to avoid re-processing identical text
    private var responseCache: [String: TaskExtractionResponse] = [:]
    private let maxCacheSize = 50

    func setAPIKey(_ key: String) {
        self.apiKey = key
        print("TaskExtractionService: API key configured")
    }

    func extractTask(from text: String, outputLanguage: String = "auto", useRichContent: Bool = true) async throws -> TaskExtractionResponse {
        // Check cache first
        let cacheKey = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cachedResponse = responseCache[cacheKey] {
            print("TaskExtractionService: Using cached response")
            return cachedResponse
        }

        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TaskExtractionError.noAPIKey
        }

        let prompt = createPrompt(for: text, outputLanguage: outputLanguage, useRichContent: useRichContent)

        // Log the actual prompt being sent to OpenAI
        print("TaskExtractionService: === PROMPT DEBUG ===")
        print("TaskExtractionService: Output Language Setting: \(outputLanguage)")
        print("TaskExtractionService: Use Rich Content: \(useRichContent)")
        print("TaskExtractionService: Input Text: \(text)")
        print("TaskExtractionService: System Prompt:")
        print("---")
        print(prompt.system)
        print("---")
        print("TaskExtractionService: User Prompt:")
        print("---")
        print(prompt.user)
        print("---")
        print("TaskExtractionService: === END PROMPT DEBUG ===")

        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIMessage(role: "system", content: prompt.system),
                OpenAIMessage(role: "user", content: prompt.user)
            ],
            temperature: 0.3,
            max_tokens: 300,
            response_format: OpenAIRequest.ResponseFormat(type: "json_object")
        )

        let response = try await performAPICall(request: request, apiKey: apiKey)

        // Cache the response
        if responseCache.count >= maxCacheSize {
            // Remove oldest entry
            if let firstKey = responseCache.keys.first {
                responseCache.removeValue(forKey: firstKey)
            }
        }
        responseCache[cacheKey] = response

        return response
    }

    private func createPrompt(for text: String, outputLanguage: String, useRichContent: Bool) -> (system: String, user: String) {
        let languageInstructions = outputLanguage == "auto"
            ? "IMPORTANT: Detect the language of the input text and respond in the EXACT SAME LANGUAGE. If the input is in English, respond in English. If the input is in Chinese, respond in Chinese, etc."
            : "IMPORTANT: Output everything in \(getLanguageName(for: outputLanguage)) regardless of the input language"

        let contentFormatting = useRichContent
            ? "Use markdown formatting for better readability (headers, lists, emphasis, etc.)"
            : "Use plain text without special formatting"

        let systemPrompt = """
        You are an actionable task extraction assistant. Your job is to identify what the user needs to DO based on the given text.

        CRITICAL: You MUST respond with VALID JSON ONLY. No explanations, no extra text, just pure JSON.

        Respond with JSON in this exact format:
        {
            "isTask": boolean,
            "confidence": number (0.0 to 1.0),
            "title": "actionable task title starting with verb" or null,
            "deadline": "ISO 8601 date/time" or null,
            "content": "comprehensive description with background and context" or null
        }

        CRITICAL LANGUAGE REQUIREMENT:
        \(languageInstructions)
        - The title and content fields in your JSON response MUST follow this language requirement
        - Maintain absolute consistency in language throughout title and content
        - Do NOT mix languages - use only ONE language for the entire response

        Focus on extracting:
        1. Direct actions: "call", "email", "prepare", "review", "schedule"
        2. Pre-work for upcoming events: meetings, deadlines, releases, appointments
        3. Preparation tasks: research, documents, materials needed
        4. Follow-up actions implied by the content

        Content Guidelines:
        - Provide full background information and context
        - Include WHY the task is needed
        - Add relevant details from the original text
        - Include any mentioned people, dates, locations, or requirements
        - \(contentFormatting)
        - Make the content comprehensive but organized

        Task Extraction Guidelines:
        - Extract actionable tasks, not just information
        - For meetings/events: identify prep work needed beforehand
        - Create titles that start with action verbs (Call, Prepare, Review, etc.)
        - Set realistic deadlines based on when action is needed
        - High confidence for clear action items, lower for implied tasks
        - Set isTask to false for pure information with no clear action required

        Deadline Guidelines:
        - For preparation tasks: set deadline 10 minutes before the actual event
        - For direct actions: use the time mentioned or a reasonable default
        - For meetings/appointments: deadline should be before the meeting starts
        - Consider prep time needed: important meetings may need earlier deadlines
        - Calculate the exact deadline time and return it in ISO 8601 format

        Examples:
        - "Team meeting tomorrow at 2pm to discuss Q4 budget" →
          Title: "Prepare for Q4 budget meeting"
          Deadline: "2025-10-20T13:50:00Z" (10 minutes before meeting)
          Content: "## Meeting Preparation\n- Review current Q4 budget status\n- Prepare questions about resource allocation\n- Gather relevant financial documents\n\n**Meeting Details:**\n- Date: Tomorrow at 2pm\n- Topic: Q4 budget discussion"

        - "Call dentist to schedule appointment" →
          Title: "Call dentist to schedule appointment"
          Deadline: "2025-10-19T17:00:00Z" (reasonable time for action)
          Content: "Contact the dentist office to book an appointment for cleaning or checkup."
        """

        let userPrompt = """
        Extract actionable tasks from this text:

        "\(text)"

        Current date: \(ISO8601DateFormatter().string(from: Date()))
        Focus on what I need to DO, especially preparation work for upcoming events.
        """

        return (system: systemPrompt, user: userPrompt)
    }

    private func getLanguageName(for code: String) -> String {
        let languages = [
            "en": "English",
            "zh": "Chinese (Simplified)",
            "zh-TW": "Chinese (Traditional)",
            "ja": "Japanese",
            "ko": "Korean",
            "fr": "French",
            "de": "German",
            "es": "Spanish",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "ar": "Arabic",
            "hi": "Hindi"
        ]
        return languages[code] ?? code
    }

    private func performAPICall(request: OpenAIRequest, apiKey: String) async throws -> TaskExtractionResponse {
        guard let url = URL(string: baseURL) else {
            throw TaskExtractionError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw TaskExtractionError.encodingError(error)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskExtractionError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TaskExtractionError.apiError(httpResponse.statusCode, errorMessage)
        }

        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let messageContent = openAIResponse.choices.first?.message.content else {
                throw TaskExtractionError.noContent
            }

            // Log the raw response for debugging
            print("TaskExtractionService: Raw OpenAI response: \(messageContent)")

            guard let responseData = messageContent.data(using: .utf8) else {
                throw TaskExtractionError.decodingError(NSError(domain: "UTF8Encoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to UTF8 data"]))
            }

            let taskResponse = try JSONDecoder().decode(TaskExtractionResponse.self, from: responseData)
            return taskResponse
        } catch {
            throw TaskExtractionError.decodingError(error)
        }
    }
}

enum TaskExtractionError: LocalizedError {
    case noAPIKey
    case invalidURL
    case encodingError(Error)
    case invalidResponse
    case apiError(Int, String)
    case noContent
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noContent:
            return "No content in API response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
