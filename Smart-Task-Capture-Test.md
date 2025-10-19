# Smart Task Capture Testing Guide

## Basic Functionality Tests

### 1. **Setup and Configuration**
- [ ] Open the app and navigate to Smart Capture Settings
- [ ] Configure OpenAI API key (requires valid key for full testing)
- [ ] Enable Smart Task Capture feature
- [ ] Note the global hotkey (default ⌘⇧T, customizable in preferences)

### 2. **Privacy Protection Tests**
Copy these texts and verify they are **NOT** processed:

#### Sensitive Data (Should be BLOCKED)
```
sk-1234567890abcdef1234567890abcdef1234567890
```
```
4111-1111-1111-1111
```
```
MySecureP@ssw0rd123!
```
```
SSN: 123-45-6789
```
```
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
```

#### Non-Task Content (Should be IGNORED)
```
https://www.example.com/some-webpage
```
```
john.doe@example.com
```
```
{ "code": "sample", "json": true }
```
```
1234567890
```

### 3. **Task Detection Tests**
Copy these texts, then press the **global hotkey** (default ⌘⇧T) and verify they **ARE** processed:

#### Simple Tasks
```
Remember to call the dentist tomorrow at 2pm
```
```
Buy groceries after work today
```
```
Email the client about the project update by Friday
```

#### Complex Tasks with Deadlines
```
Schedule team meeting for next Tuesday at 10am to discuss Q4 planning
```
```
Submit quarterly report to manager before end of month
```
```
Review contract proposal and send feedback to legal team by noon tomorrow
```

#### Ambiguous Content (Test Confidence Threshold)
```
The weather is nice today
```
```
Meeting was productive and informative
```
```
Should probably exercise more often
```

### 4. **Dialog Interaction Tests**
When task dialogs appear:

- [ ] Verify task title is extracted correctly
- [ ] Check if deadline is parsed and displayed
- [ ] Test editing the title before accepting
- [ ] Test editing the description
- [ ] Test changing the deadline
- [ ] Verify "Accept" creates the task in the app
- [ ] Verify "Decline" dismisses without creating task
- [ ] Test keyboard shortcuts (Enter to accept, Escape to decline)

### 5. **Settings and Preferences Tests**

#### Confidence Threshold
- [ ] Set to low (30%) - should detect more suggestions
- [ ] Set to high (90%) - should detect fewer suggestions
- [ ] Test with borderline task content

#### Category Filtering
- [ ] Disable "work" category
- [ ] Copy work-related task text
- [ ] Verify it's not suggested
- [ ] Re-enable and test again

#### Privacy Mode
- [ ] Disable privacy mode
- [ ] Test with sensitive-looking content
- [ ] Re-enable and verify blocking

### 6. **Performance Tests**

#### Rapid Copying
- [ ] Copy multiple texts quickly in succession
- [ ] Verify debouncing works (no spam dialogs)
- [ ] Check memory usage doesn't grow excessively

#### Global Shortcut Operation
- [ ] Switch to other apps (browser, email, etc.)
- [ ] Copy task-like content from other apps
- [ ] Press the global hotkey and verify dialog appears over current application

### 7. **Error Handling Tests**

#### Network Issues
- [ ] Disconnect internet, copy task text
- [ ] Verify graceful failure (no crash, appropriate error)
- [ ] Reconnect and test normal operation

#### Invalid API Key
- [ ] Set invalid API key
- [ ] Copy task text
- [ ] Verify appropriate error handling

#### API Rate Limiting
- [ ] Copy many task texts rapidly
- [ ] Verify rate limiting and backoff

## Expected Behaviors

### ✅ Should Process
- Natural language describing actions to take
- Content with time/date references
- Imperative sentences ("Remember to...", "Don't forget...")
- Meeting/appointment descriptions
- Shopping lists with context
- Work assignments and deadlines

### ❌ Should NOT Process
- Personal information (SSN, passwords, API keys)
- Credit card numbers
- Pure URLs or email addresses
- Code snippets
- File paths
- Phone numbers (standalone)
- Random numeric sequences

### ⚙️ Settings Persistence
- [ ] Configure settings, quit app, restart
- [ ] Verify all settings are preserved
- [ ] Test with different user preference combinations

## Troubleshooting

### No Suggestions Appearing
1. Check if feature is enabled in settings
2. Verify API key is configured
3. Make sure you're pressing the global hotkey after copying text
4. Check confidence threshold (try lowering it)
5. Look at console logs for error messages
6. Ensure copied text meets minimum length requirements

### Too Many False Positives
1. Increase confidence threshold
2. Enable privacy mode
3. Add custom exclusion patterns
4. Disable unwanted categories

### Performance Issues
1. Check for memory leaks in monitoring
2. Verify timer cleanup on app quit
3. Monitor CPU usage during active monitoring

## Console Logs to Monitor
- "PasteboardMonitor: Started monitoring"
- "SmartTaskCapture: Analyzing text with AI..."
- "SmartTaskCapture: Task detected with confidence X"
- "SmartTaskCapture: Text excluded by user patterns"
- Error messages for API failures or parsing issues