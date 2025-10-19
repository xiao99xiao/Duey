# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Duey is a macOS todo management application built with SwiftUI and SwiftData. It provides a native Mac experience for managing tasks with deadlines, markdown content, and CloudKit sync.

## Technology Stack
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData with CloudKit sync
- **Platform**: macOS (minimum deployment target: macOS 26.0)
- **Development Environment**: Xcode 26.0.1
- **Markdown**: For task content editing and rendering

## Build Commands
```bash
# Build the project
xcodebuild -project Duey.xcodeproj -scheme Duey build

# Clean build folder
xcodebuild -project Duey.xcodeproj -scheme Duey clean

# Build and run (opens in Xcode)
open Duey.xcodeproj
# Then use ⌘+R to run
```

## Dependencies
Add this Swift Package Manager dependency via Xcode:
- **HighlightedTextEditor**: `https://github.com/kyle-n/HighlightedTextEditor` (version 2.1.0+)
  - For markdown syntax highlighting in the editor

To add: File → Add Package Dependencies in Xcode

## Architecture
The app follows a SwiftUI + SwiftData architecture with CloudKit sync:

- **DueyApp.swift**: App entry point that configures the SwiftData model container with CloudKit
- **ContentView.swift**: Main UI implementing NavigationSplitView for master-detail interface
- **Task Model**: SwiftData model with title, content (markdown), deadline, completion status, and timestamps

The app uses SwiftData's automatic persistence with CloudKit sync. Views access data through SwiftUI's Query property wrapper and modify it through the ModelContext.

## Core Features & Requirements

### Task Model
- **Title**: Required, supports multiline display
- **Content**: Optional, stored as markdown text
- **Deadline**: Optional Date + Time (defaults to 18:00 if time not specified)
- **Status**: Unfinished or Done
- **Timestamps**: Creation time, completion time (when marked done)

### Sidebar (Task List)
- Shows all tasks with title and days until deadline (if set)
- Sorting order:
  1. Unfinished tasks (sorted by deadline, earliest first, no deadline at bottom)
  2. Finished tasks (sorted by completion time, most recent first)

### Main Content Area (Task Detail)
- **Header**: Task title (top), deadline picker (right side)
- **Content Editor**: Markdown editor with live preview
- **Auto-save**: All changes save automatically
- **Bottom Float Region**:
  - For unfinished tasks: "Mark as Done" button
  - For finished tasks: Shows completion time + "Mark as Unfinished" button
- **Important**: Content editor needs bottom padding to prevent overlap with float region

### Task Management
- **Create New**: Button in main content area navigation bar
- **Auto-delete**: Empty new tasks delete automatically when deselected
- **Auto-save**: Tasks save when title is entered
- **Delete**: Standard SwiftUI swipe-to-delete in sidebar

## Key Implementation Details
- All data syncs via CloudKit for cross-device access
- Markdown rendering for task content
- Calendar/time picker for deadline selection
- Reactive UI updates through SwiftData/SwiftUI integration
- Proper state management for task creation/deletion flow

## Development Workflow
- **IMPORTANT**: Create a git commit after completing each implementation step
- Each commit should represent a single, working feature or fix
- Use descriptive commit messages that reference the feature being implemented
- Test the app builds and runs before committing

## Development Configuration
- **Bundle ID**: com.xiao99xiao.Duey
- **Team ID**: CNVBGR2V76
- **Code Signing**: Automatic
- **App Sandbox**: Enabled
- **Minimum macOS**: 26.0