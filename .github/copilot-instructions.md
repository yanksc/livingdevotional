# Copilot instructions for livingdevotional

This file gives concise, actionable guidance for AI coding agents working in this SwiftUI codebase.

Architecture (big picture)
- App entry: [livingdevotionalApp.swift](livingdevotionalApp.swift) creates `ServiceContainer.shared` and `AppRouter` and injects them into the environment.
- Navigation: centralized in `AppRouter` ([Core/Router.swift](Core/Router.swift)) using `NavigationPath` and `AppRoute` enum.
- Dependency injection: `ServiceContainer` ([Services/ServiceContainer.swift](Services/ServiceContainer.swift)) exposes core singletons (`BibleService`, `SettingsStore`, `ProgressStore`) and optional protocol-backed services (auth, AI, user, daily verse, conversation, check-ins).
- Data layer: `BibleService` ([Data/BibleService.swift](Data/BibleService.swift)) loads JSON files from a bundled `BibleData.bundle` by translation/book/chapter. Tests and features rely on this local bundle.
- View layer: SwiftUI views use `@Environment(\.services)`, `@EnvironmentObject` router, `@StateObject` view models and `async/await` tasks (see `ReadingView` and `ReadingViewModel`).

Key patterns & conventions
- Use the `ServiceContainer.shared` instance for service access in view models; prefer constructor injection where possible (many view models accept a `ServiceContainer` parameter).
- Services exposing behavior conform to protocols in [Services/ServiceProtocols.swift](Services/ServiceProtocols.swift). Implementations register with `ServiceContainer.register...`.
- Async flows: view models frequently use `Task { ... }` and `await MainActor.run { ... }` to update `@Published` state.
- Bundle data: Bible JSON files are expected under `BibleData.bundle/{translation}/{bookId}/{chapter}.json`. Failure to include the bundle in target resources is the most common runtime error — `BibleService` provides helpful `BibleServiceError` messages.
- Localization/Language: `SettingsStore` controls `primaryLanguage` / `secondaryLanguage`; views show dual-language content when both are set.

Integration points & TODO placeholders
- AI and Auth: `AIService` and `AuthenticationService` exist as placeholders ([Services/AI/AIService.swift](Services/AI/AIService.swift), [Services/Auth/AuthenticationService.swift](Services/Auth/AuthenticationService.swift)). Their protocols are defined; implementations should call `ServiceContainer.registerAIService(...)` and `registerAuthService(...)` in `livingdevotionalApp.setupServices()`.
- External API references: comments reference `https://bible.helloao.org/api` and migration routes (use them as implementation targets).

Developer workflows
- Build & run: open the Xcode project/workspace and run on a simulator or device. Typical commands:

```
xed .                # open current folder in Xcode
# or open the project/workspace in Finder then Cmd+O in Xcode
```

- Common runtime issue: missing `BibleData.bundle` in app target resources. Verify in Xcode → Target → Build Phases → Copy Bundle Resources.
- Debug helpers: `BundleHelper.debugBundleStructure()` is called in `BibleService` under `#if DEBUG` to help diagnose resource layout.

What to change and how to test
- When adding a new service implementation:
  - Add a protocol in `Services/ServiceProtocols.swift` if needed.
  - Implement the class under `Services/` or `Services/<feature>/` and register it in `setupServices()` in [livingdevotionalApp.swift](livingdevotionalApp.swift).
  - Use `ServiceContainer.shared` in view models, or prefer explicit injection for testability.
- When modifying data parsing in `BibleService`, add unit tests that load sample JSON from test bundles or use the `BibleData.bundle` fixtures.

Files to inspect for examples
- Routing & navigation: [Core/Router.swift](Core/Router.swift)
- DI surface: [Services/ServiceContainer.swift](Services/ServiceContainer.swift)
- Service contracts: [Services/ServiceProtocols.swift](Services/ServiceProtocols.swift)
- Local JSON loader: [Data/BibleService.swift](Data/BibleService.swift)
- Example view + async pattern: [Views/ReadingView.swift](Views/ReadingView.swift) and [Features/Home/HomeViewModel.swift](Features/Home/HomeViewModel.swift)

Notes for AI agents
- Be conservative: many services are placeholders; don't implement large features without noting integration points and adding tests.
- Preserve existing singletons and environment keys — replacing them is a breaking change across views.
- Prefer small, targeted changes with tests and a clear migration plan (register service, update `setupServices()`, run app to verify resource loading).

If anything here is unclear or you want more detail (tests, CI, or example implementations), tell me which area to expand.
