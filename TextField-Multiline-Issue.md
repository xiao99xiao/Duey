# SwiftUI TextField Multiline Text Cutoff Issue

## Problem Description

When using `TextField` with `axis: .vertical` for multiline text input in SwiftUI on macOS, text content gets cut off when the field loses focus. Specifically:

- Text displays correctly while editing (when focused)
- Second and subsequent lines disappear when the TextField loses focus
- Text appears truncated even though the full content is still stored in the binding

## Root Cause

SwiftUI's `TextField` with multiline support has inconsistent height calculation behavior:
- During editing: Height expands to accommodate all text
- When not focused: Height shrinks to single-line, causing visual truncation

## Failed Solutions Attempted

1. **TextEditor replacement** - Wrong height calculations
2. **fixedSize() modifier** - No effect on the issue
3. **Vertical padding** - Cosmetic only, didn't fix cutoff
4. **lineLimit with range** - Still had cutoff issues
5. **reservesSpace: true** - Fixed cutoff but forced unnecessary space for short text
6. **Manual minHeight** - Cutoff issue returned

## Working Solution: TextField/TextEditor Overlay

Use `TextField` as an invisible layout foundation and overlay it with `TextEditor` for actual editing:

```swift
TextField("Task Title", text: $task.title, axis: .vertical)
    .textFieldStyle(.plain)
    .font(.title2)
    .lineLimit(1...3)
    .frame(maxWidth: .infinity)
    .foregroundStyle(Color.clear)  // Make TextField invisible
    .focused($titleFocused)
    .overlay(
        TextEditor(text: $task.title)
            .font(.title2)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .focused($titleFocused)
            .allowsHitTesting(task.title.isEmpty ? false : true)
    )
```

## Why This Works

1. **TextField provides layout**: Handles proper height calculation and placeholder behavior
2. **TextEditor provides editing**: Handles multiline text input and display
3. **Shared bindings**: Both use the same text binding and focus state
4. **Clear foregroundStyle**: TextField becomes invisible but maintains its layout properties
5. **Overlay positioning**: TextEditor sits exactly on top of TextField

## Key Implementation Details

- Use the actual text binding on TextField, not `.constant("")`
- Apply `foregroundStyle(Color.clear)` to make TextField invisible
- Share the same `@FocusState` binding between both components
- Control hit testing based on content state
- Apply same font and styling to both components

## When to Use

This solution is recommended when you need:
- Multiline text input that looks like a TextField
- Consistent text display regardless of focus state
- Proper height calculation for varying text lengths
- Native SwiftUI behavior without custom NSView wrappers

## References

- Stack Overflow: "Multiline TextField/TextEditor in SwiftUI for MacOS in forms"
- Stack Overflow: "How to make TextEditor look like TextField - SwiftUI"