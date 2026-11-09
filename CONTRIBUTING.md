# Contributing to Document Reviewer

Thank you for your interest in contributing to **Document Reviewer**! We welcome bug reports, documentation improvements, and pull requests that adhere to our architectural principles.

---

## 1. Core Principles (Non-Negotiable)

1. **100% Offline-First Invariant**:
   - The application must NEVER declare `android.permission.INTERNET`.
   - Never add network libraries, cloud dependencies, analytics SDKs, or remote telemetry.
2. **Zero File Corruption (The Edit Verification Cycle)**:
   - Original user documents must remain strictly untouchable until atomic commits succeed via `SaveCoordinator`.
   - Never perform destructive write operations directly on input SAF streams.
3. **Open-Source License Purity**:
   - Only dependencies with Tier 1 Permissive licenses (MIT, BSD, Apache-2.0, ISC) are permitted.
   - Infectious copyleft licenses (GPL, AGPL, SSPL) are strictly barred.
4. **Android 15 Compatibility**:
   - All 64-bit native `.so` libraries must satisfy $\ge 16\text{ KB}$ ELF memory page alignment.

---

## 2. Development Setup

1. **Prerequisites**:
   - Flutter SDK $\ge 3.24.5$
   - JDK 17
   - Android SDK 36 (minSdk 26)
2. **Clone & Install**:
   ```bash
   git clone https://github.com/your-org/document_reviewer.git
   cd document_reviewer
   flutter pub get
   ```
3. **Verify Lint & Tests**:
   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   dart format --output=none --set-exit-if-changed .
   flutter test --coverage
   ```

---

## 3. Pull Request Guidelines

- Branch naming: `feature/<feature-name>`, `bugfix/<issue-name>`, `refactor/<target>`.
- Commit messages: Follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat:`, `fix:`, `docs:`, `test:`, `chore:`).
- Every PR must pass all 148+ unit and widget tests and add test coverage for newly introduced logic.
