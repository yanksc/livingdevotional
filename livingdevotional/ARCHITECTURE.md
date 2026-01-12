# Living Devotional - Architecture Documentation

## 📁 Project Structure

```
livingdevotional/
├── Core/                    # Core app infrastructure
│   └── Router.swift         # Centralized routing
├── Services/                # Service layer (protocols & implementations)
│   ├── ServiceProtocols.swift      # Service protocol definitions
│   ├── ServiceContainer.swift      # Dependency injection container
│   ├── Auth/                       # Authentication services
│   │   └── AuthenticationService.swift
│   └── AI/                         # AI services
│       └── AIService.swift
├── Features/                # Feature modules
│   ├── Home/               # Home page feature
│   │   └── HomeView.swift
│   └── Auth/               # Authentication feature
│       ├── LoginView.swift
│       └── SignupView.swift
├── Views/                   # UI Views (Bible reading)
│   ├── MainTabView.swift
│   ├── BookListView.swift
│   ├── ChapterGridView.swift
│   ├── ReadingView.swift
│   └── SettingsView.swift
├── ViewModels/             # ViewModels for Views
│   ├── BibleViewModel.swift
│   └── ReadingViewModel.swift
├── Models/                 # Data models
│   ├── Models.swift
│   └── BibleData.swift
├── Data/                   # Data layer
│   ├── BibleService.swift
│   ├── SettingsStore.swift
│   └── ProgressStore.swift
└── Utils/                  # Utilities
    ├── AppTheme.swift
    └── BundleHelper.swift
```

## 🏗️ Architecture Principles

### 1. **Service Layer Pattern**
- All business logic is abstracted behind protocols
- Services are registered in `ServiceContainer` for dependency injection
- Easy to mock and test

### 2. **Feature-Based Organization**
- Features are self-contained modules
- Each feature can have its own Views, ViewModels, and Services
- Easy to add/remove features

### 3. **Dependency Injection**
- Services are injected via `Environment` values
- Centralized in `ServiceContainer`
- Promotes testability and flexibility

### 4. **Protocol-Oriented Design**
- Services defined as protocols first
- Implementations can be swapped easily
- Supports multiple implementations (e.g., mock services for testing)

## 🔌 Service Layer

### Service Protocols

All services follow a protocol-first approach:

- `AuthenticationServiceProtocol` - User authentication
- `AIServiceProtocol` - AI features (explain, search, Q&A)
- `UserServiceProtocol` - User profile and data
- `DailyVerseServiceProtocol` - Verse of the day
- `ConversationServiceProtocol` - AI conversations
- `CheckInServiceProtocol` - Daily check-ins

### Service Container

The `ServiceContainer` manages all service instances:

```swift
let services = ServiceContainer.shared
services.registerAuthService(AuthenticationService())
services.registerAIService(AIService())
```

Access in views:
```swift
@Environment(\.services) var services
```

## 🧭 Routing

Centralized routing via `AppRouter`:

```swift
enum AppRoute {
    case home
    case bible
    case reading(book: BibleBook, chapter: Int)
    case settings
    case profile
    case login
    case signup
}
```

## 🎨 Adding New Features

### Step 1: Define Service Protocol
```swift
protocol MyFeatureServiceProtocol {
    func doSomething() async throws -> Result
}
```

### Step 2: Implement Service
```swift
class MyFeatureService: MyFeatureServiceProtocol {
    func doSomething() async throws -> Result {
        // Implementation
    }
}
```

### Step 3: Register Service
```swift
// In livingdevotionalApp.swift
serviceContainer.registerMyFeatureService(MyFeatureService())
```

### Step 4: Create Feature Module
```
Features/
└── MyFeature/
    ├── MyFeatureView.swift
    └── MyFeatureViewModel.swift
```

### Step 5: Add Route
```swift
enum AppRoute {
    case myFeature
    // ...
}
```

## 🔐 Authentication Flow

1. App checks `authService.isAuthenticated`
2. If not authenticated → Show `LoginView`
3. If authenticated → Show `MainTabView`
4. Services can check auth state before making API calls

## 🤖 AI Features Integration

AI services are ready to be implemented:

1. **Verse Explanation** - `explainVerse()`
2. **Related Verses** - `findRelatedVerses()`
3. **Q&A** - `askQuestion()`
4. **Chapter Summary** - `summarizeChapter()`
5. **Bible Search** - `searchBible()`

Reference implementations in `migration/api/` folder.

## 📝 Best Practices

1. **Keep Views Thin** - Business logic in ViewModels/Services
2. **Use Protocols** - Define interfaces before implementations
3. **Dependency Injection** - Don't create services directly in views
4. **Error Handling** - Use `Result` types or `throws` for async operations
5. **State Management** - Use `@StateObject` for ViewModels, `@ObservedObject` for shared state

## 🧪 Testing Strategy

Services can be easily mocked:

```swift
class MockAIService: AIServiceProtocol {
    func explainVerse(...) async throws -> String {
        return "Mock explanation"
    }
}

// In tests
serviceContainer.registerAIService(MockAIService())
```

## 🚀 Future Enhancements

- [ ] Implement AuthenticationService with backend API
- [ ] Implement AIService with OpenAI/Claude integration
- [ ] Add UserService for profile management
- [ ] Add DailyVerseService for verse of the day
- [ ] Add ConversationService for chat history
- [ ] Add CheckInService for daily check-ins
- [ ] Add offline support with Core Data
- [ ] Add push notifications





