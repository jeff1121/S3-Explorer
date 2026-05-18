# Repository Guidelines

## Project Structure & Module Organization

This repository contains a Flutter macOS desktop app for browsing S3-compatible storage. The main application lives in `app/`.

- `app/lib/main.dart`: Flutter entry point.
- `app/lib/features/`: UI and view-model code grouped by workflow, including `connection`, `browser`, `transfer`, `preview`, `permissions`, `sync`, and `logs`.
- `app/lib/services/`: S3 access, transfer queue, multipart upload, sync, permissions, profiles, bookmarks, and logging services.
- `app/lib/models/`: shared entity models.
- `app/lib/theme/`: Now UI Pro theme integration.
- `app/test/`: widget and integration tests.
- `specs/001-s3-desktop-app/`: product specs, plan, data model, contracts, and task list.
- `docs/creativetimofficial-now-ui-pro-flutter/`: bundled UI/theme reference package and assets used by `app/pubspec.yaml`.

## Build, Test, and Development Commands

Run app commands from `app/`.

```bash
flutter pub get          # install Dart/Flutter dependencies
flutter run -d macos     # run the desktop app locally
flutter analyze          # run static analysis and project lints
flutter test             # run all available tests
./scripts/build_macos.sh # build the macOS release app
./scripts/create_dmg.sh  # create a distributable DMG
```

Integration tests require S3 or MinIO settings passed with `--dart-define`, as documented in `app/README.md`.

## Coding Style & Naming Conventions

Use Dart defaults and `flutter_lints`. The analyzer also enforces `avoid_print`, `prefer_single_quotes`, and `always_use_package_imports`. Format Dart changes with:

```bash
dart format lib test
```

Use 2-space indentation. Name files in `snake_case.dart`, classes in `UpperCamelCase`, methods and variables in `lowerCamelCase`. Keep feature UI code under `lib/features/<feature>/` and shared logic under `lib/services/`.

## Testing Guidelines

Use `flutter_test`. Keep fast widget or service tests in `app/test/`; place end-to-end S3 flows in `app/test/integration/`. Name tests with a `_test.dart` suffix, for example `us1_basic_flow_test.dart`. Before opening a pull request, run:

```bash
flutter analyze
flutter test
```

For integration coverage, provide the required `TEST_S3_*` values via `--dart-define` and avoid committing real credentials.

## Commit & Pull Request Guidelines

Recent history uses short imperative messages, often with Conventional Commit prefixes such as `feat:` and `chore:`. Prefer messages like `feat: add sync conflict handling` or `chore: update macos build script`.

Pull requests should include a focused summary, test results, linked issue or spec task when relevant, and screenshots for UI changes. Call out S3/MinIO environment assumptions, credential handling, and any macOS entitlement changes.

## Security & Configuration Tips

Do not commit access keys, bucket secrets, generated profiles, or local Application Support data. Treat presigned URLs and public ACL changes as sensitive during tests and reviews.


Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.



Create principles focused on code quality, testing standards, user experience consistency, and performance requirements

use ui-ux-pro-max skill to design frontend 

use Felo-Search skill to search 

use playwright-cli skill to use "playwright-cli head mode" test frontend

use MVP，do not overdesign

use MVP，do not overdesign

use MVP，do not overdesign

use zh-tw (all document , chat , program comments)

use zh-tw (all document , chat , program comments)

use zh-tw (all document , chat , program comments)
