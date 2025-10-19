# Pasteboard Todo Extraction Feature

## Overview
Intelligent monitoring of the system pasteboard to detect and extract potential todo tasks from copied text. When a user copies text that could represent a task, the app will analyze it using OpenAI API and offer to create a structured task.

## Feature Description

### Core Functionality
- **On-Demand Clipboard Analysis**: Press the global hotkey (default ⌘⇧T, customizable in preferences) to analyze current clipboard content
- **AI-Powered Analysis**: Use OpenAI API to analyze copied text for task potential
- **Smart Task Extraction**: Extract title, deadline, and detailed content from natural language
- **Non-Intrusive Notification**: Show dialog overlay regardless of app focus state
- **User Confirmation**: Allow user to accept, modify, or decline the suggested task

### User Experience Flow
1. User copies text anywhere in the system (email, webpage, document, etc.)
2. User presses the global hotkey (default ⌘⇧T) when ready to analyze the clipboard
3. If text contains task-like content, AI extracts structured information
4. Dialog appears over the app window asking "Add this task?"
5. User can review, modify, or decline the suggestion
6. If accepted, task is added to the app with proper categorization

## Technical Specifications

### Clipboard Analysis
- **Technology**: NSPasteboard on-demand reading via keyboard shortcut
- **Trigger**: Global keyboard shortcut (default ⌘⇧T, customizable in preferences)
- **Content Types**: Plain text content only (exclude images, files, etc.)
- **Privacy**: Only process text when user explicitly requests analysis

### AI Integration
- **Provider**: OpenAI API (GPT-4 or GPT-3.5-turbo)
- **Prompt Engineering**: Structured prompts for task detection and extraction
- **Response Format**: JSON with title, deadline, content, and confidence score
- **Fallback**: Graceful degradation when API is unavailable

### Expected AI Input/Output
```json
// Input: Raw copied text
"Remember to call the dentist tomorrow at 2pm to schedule cleaning appointment"

// Output: Structured task data
{
  "isTask": true,
  "confidence": 0.85,
  "title": "Call dentist to schedule cleaning",
  "deadline": "2025-10-20T14:00:00Z",
  "content": "Contact the dentist's office to schedule a cleaning appointment. Original reminder was for 2pm tomorrow.",
  "category": "personal"
}
```

### Dialog Interface
- **Design**: Modal overlay with native macOS appearance
- **Position**: Center of main window, stays on top
- **Animations**: Smooth slide-down entrance, fade-out exit
- **Controls**: Accept, Edit, Decline buttons
- **Keyboard Support**: Enter to accept, Escape to decline

## Privacy & Performance Considerations

### Privacy Protection
- **Local Processing**: Initial text analysis for task potential
- **Selective API Calls**: Only send task-like content to OpenAI
- **No Sensitive Data**: Skip personal information, passwords, etc.
- **User Consent**: Clear indication when API analysis occurs
- **Data Retention**: No storage of analyzed text beyond processing

### Performance Optimization
- **On-Demand Processing**: No background monitoring, only processes when requested
- **Caching**: Cache results for identical text within session
- **Rate Limiting**: Respect OpenAI API limits and implement backoff
- **Background Processing**: Non-blocking analysis to maintain app responsiveness

### Error Handling
- **Network Failures**: Graceful fallback without user interruption
- **API Errors**: Retry logic with exponential backoff
- **Malformed Responses**: Validation and safe parsing
- **Resource Management**: Proper cleanup of monitoring resources

## Implementation Roadmap

### Phase 1: Core Infrastructure
- [ ] Implement NSPasteboard monitoring system
- [ ] Create pasteboard change detection with filtering
- [ ] Set up basic text analysis pipeline
- [ ] Design dialog UI components
- [ ] Implement dialog positioning and animations

### Phase 2: AI Integration
- [ ] Set up OpenAI API client configuration
- [ ] Design and test prompt engineering for task detection
- [ ] Implement structured response parsing
- [ ] Add confidence scoring and thresholds
- [ ] Create fallback mechanisms for API failures

### Phase 3: Dialog System
- [ ] Build modal dialog overlay component
- [ ] Implement task preview with editable fields
- [ ] Add accept/decline/edit functionality
- [ ] Integrate with existing task creation system
- [ ] Add keyboard shortcuts and accessibility

### Phase 4: Privacy & Performance
- [ ] Implement content filtering for sensitive data
- [ ] Add debouncing and rate limiting
- [ ] Create user preferences for feature toggle
- [ ] Add caching system for duplicate content
- [ ] Implement comprehensive error handling

### Phase 5: Polish & Testing
- [ ] Add user preferences for sensitivity settings
- [ ] Implement usage analytics (privacy-compliant)
- [ ] Comprehensive testing across different text types
- [ ] Performance optimization and memory management
- [ ] Documentation and user onboarding

## Configuration Options

### User Preferences
- **Enable/Disable**: Master toggle for the feature
- **Sensitivity**: AI confidence threshold (conservative/balanced/aggressive)
- **API Key**: User-provided OpenAI API key
- **Exclusions**: Text patterns to ignore (regex support)
- **Timing**: Debounce delay for pasteboard changes

### Developer Settings
- **API Endpoint**: Configurable OpenAI endpoint
- **Model Selection**: Choice between GPT models
- **Timeout Values**: Request timeout configurations
- **Debug Mode**: Logging for development and troubleshooting

## Security Considerations

### Data Protection
- **API Key Storage**: Secure keychain storage for OpenAI API key
- **HTTPS Only**: All API communications over secure connections
- **Input Validation**: Sanitize and validate all user inputs
- **Memory Safety**: Clear sensitive data from memory after processing

### Permissions
- **Accessibility**: May require accessibility permissions for some monitoring
- **Network Access**: Clear user communication about internet usage
- **Background Activity**: Transparent about background processing

## Success Metrics

### Functionality Metrics
- **Detection Accuracy**: Percentage of actual tasks correctly identified
- **False Positive Rate**: Non-tasks incorrectly flagged as tasks
- **User Acceptance Rate**: Percentage of suggestions accepted by users
- **Processing Speed**: Time from copy to suggestion display

### User Experience Metrics
- **Feature Adoption**: Percentage of users who enable the feature
- **Daily Usage**: Average suggestions per active user per day
- **User Satisfaction**: Feedback on suggestion quality and usefulness
- **Performance Impact**: App responsiveness during monitoring

## Future Enhancements

### Advanced Features
- **Multi-language Support**: Task detection in various languages
- **Context Awareness**: Learn from user patterns and preferences
- **Smart Scheduling**: Suggest optimal timing based on calendar
- **Project Integration**: Auto-categorize tasks into existing projects

### Integration Possibilities
- **Calendar Apps**: Cross-reference with existing appointments
- **Email Clients**: Enhanced email-to-task conversion
- **Note-taking Apps**: Bi-directional sync with other productivity tools
- **Team Collaboration**: Share AI-extracted tasks with team members

## Technical Dependencies

### Required Libraries
- **Foundation**: NSPasteboard monitoring
- **SwiftUI**: Dialog interface components
- **Network**: HTTP client for OpenAI API
- **Security**: Keychain services for API key storage

### External Services
- **OpenAI API**: GPT model access for text analysis
- **Internet Connection**: Required for AI processing
- **macOS Permissions**: Pasteboard access and possibly accessibility

### Compatibility
- **macOS Version**: 13.0+ (for modern SwiftUI features)
- **Hardware**: Any Mac capable of running the main app
- **Network**: Reliable internet connection for optimal experience

---

This feature will significantly enhance user productivity by capturing task intentions from everyday digital activities, reducing friction in task creation while maintaining user privacy and control.