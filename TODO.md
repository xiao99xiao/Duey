# Duey Todo Management App - Implementation Tasks

## Phase 1: Data Model & Persistence

### 1. Update Task Model
- [ ] Rename `Item.swift` to `Task.swift`
- [ ] Add required properties per CLAUDE.md:
  - `title: String` (required)
  - `content: String?` (optional, markdown)
  - `deadline: Date?` (optional)
  - `isCompleted: Bool` (default false)
  - `createdAt: Date` (auto-set)
  - `completedAt: Date?` (set when marked done)

### 2. Configure CloudKit Integration
- [ ] Enable CloudKit capability in Xcode project settings
- [ ] Configure SwiftData model container with CloudKit support in `DueyApp.swift`
- [ ] Set up proper CloudKit container identifier
- [ ] Test sync functionality

## Phase 2: Sidebar Implementation

### 3. Task List Sidebar
- [ ] Update sidebar to show task list with:
  - Task title
  - Days until deadline indicator (if deadline exists)
- [ ] Implement sorting algorithm per CLAUDE.md:
  - Unfinished tasks first (sorted by deadline, earliest first)
  - Tasks without deadline at bottom of unfinished section
  - Finished tasks second (sorted by completedAt, most recent first)
- [ ] Add visual distinction between finished/unfinished tasks

### 4. Sidebar Interactions
- [ ] Implement swipe-to-delete for tasks
- [ ] Add task selection highlighting
- [ ] Handle empty state when no tasks exist

## Phase 3: Task Detail View

### 5. Detail View Header
- [ ] Create header layout with:
  - Multiline title field (top)
  - Deadline picker button (right side)
- [ ] Implement calendar/time picker for deadline:
  - Date picker component
  - Time picker (default to 18:00 if not specified)
  - Option to clear deadline

### 6. Markdown Content Editor
- [ ] Research and select markdown editor library for macOS
- [ ] Integrate markdown editor with:
  - Live preview capability
  - Syntax highlighting
  - Auto-save on change
- [ ] Add sufficient bottom padding to avoid float region overlap

### 7. Floating Action Region
- [ ] Create floating button container at bottom center
- [ ] For unfinished tasks:
  - "Mark as Done" button
- [ ] For finished tasks:
  - Display completion timestamp
  - "Mark as Unfinished" button
- [ ] Ensure proper z-index and positioning

## Phase 4: Task Management Features

### 8. Create New Task
- [ ] Add "Create New" button to main content navigation bar
- [ ] Implement new task creation:
  - Create task and immediately select
  - Place at top of sidebar
- [ ] Handle auto-deletion:
  - Delete if user navigates away without entering title
  - Save automatically when title is entered

### 9. Auto-Save System
- [ ] Implement debounced auto-save for:
  - Title changes
  - Content changes
  - Deadline changes
- [ ] Ensure SwiftData persistence on every change
- [ ] Add save state indicator (optional)

## Phase 5: Polish & Testing

### 10. UI/UX Refinements
- [ ] Add loading states
- [ ] Implement proper error handling
- [ ] Add keyboard shortcuts for common actions
- [ ] Ensure proper focus management

### 11. CloudKit Testing
- [ ] Test sync across multiple devices
- [ ] Verify conflict resolution
- [ ] Test offline functionality
- [ ] Ensure proper data persistence

### 12. Final Testing
- [ ] Test all CRUD operations
- [ ] Verify sorting algorithm correctness
- [ ] Test edge cases (empty tasks, very long titles, etc.)
- [ ] Performance testing with many tasks

## Technical Notes

### Dependencies to Consider
- Markdown editor library (e.g., MarkdownUI, Ink, or custom implementation)
- Date/time formatting utilities
- CloudKit configuration

### Key Files to Modify
- `Item.swift` → `Task.swift`: Complete rewrite for task model
- `ContentView.swift`: Major restructuring for new UI layout
- `DueyApp.swift`: CloudKit configuration
- New files needed:
  - `SidebarView.swift`: Extracted sidebar component
  - `TaskDetailView.swift`: Task detail editor
  - `MarkdownEditor.swift`: Markdown editing component
  - `FloatingActionView.swift`: Bottom floating buttons

### Testing Checklist
- [ ] Tasks persist across app launches
- [ ] Tasks sync between devices via CloudKit
- [ ] Markdown renders correctly
- [ ] Deadlines display accurately
- [ ] Sorting works as specified
- [ ] Auto-delete of empty tasks works
- [ ] Mark done/undone functionality works
- [ ] UI is responsive and follows macOS design guidelines