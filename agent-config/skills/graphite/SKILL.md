# Graphite Stacking Workflow

## Overview

When implementing features or refactors, use stacked PRs via Graphite (`gt` CLI) to keep changes small, reviewable, and shippable.

## Planning Requirements

Before writing any code, create a plan as a sequence of stacked PRs. Each PR should:

- Be independently reviewable (< 400 lines ideally)
- Build on the previous PR in the stack
- Have a clear, focused scope
- Pass CI on its own

## Stack Planning Process

1. **Analyze the task** - Break down the feature into logical building blocks
2. **Order dependencies** - Interfaces → Implementation → Tests → Integration
3. **Create todos as PRs** - Each todo item = one PR in the stack
4. **Validate the plan** - Ensure each PR is self-contained and testable

## Using Graphite CLI

### Branch Naming Convention

Branch names should start with your GitHub username followed by a slash:

```
username/some-new-feature
```

### Creating a new branch in the stack

If you are working with a particular ticket, then it should be:


```bash
gt create -m "feat: descriptive commit message" -b "username/[ticket-id]-feature-name"
```

If there is no ticket related, then it should be:

```bash
gt create -m "feat: descriptive commit message" -b "username/feature-name"
```

If you omit `-b`, Graphite will auto-generate a branch name from your commit message.

### Submitting the stack for review

```bash
gt submit --stack
```

### Syncing with trunk

```bash
gt sync
```

### Viewing your stack

```bash
gt log
```

## Stack Structure Guidelines

### Good stack structure:

1. **PR 1**: Define interfaces/types
2. **PR 2**: Implement core logic
3. **PR 3**: Add tests for core logic
4. **PR 4**: Build UI/integration layer
5. **PR 5**: Add integration tests

### Bad patterns to avoid:

- Tests in a different PR than the code they test (unless adding tests to existing code)
- Splitting a single refactor across multiple PRs
- PRs that can't pass CI independently
- Mixing unrelated changes in one PR

## Example Workflow

For a task like "Add user notification preferences":

```
Stack Plan:
├── PR 1: feat: add NotificationPreference type and repository interface (+50 lines)
├── PR 2: feat: implement notification preference repository (+120 lines)
├── PR 3: test: add unit tests for notification repository (+80 lines)
├── PR 4: feat: add notification preferences API endpoints (+150 lines)
├── PR 5: feat: add notification preferences UI component (+200 lines)
└── PR 6: test: add e2e tests for notification preferences (+100 lines)
```

## Commands Reference

| Command                | Description                   |
| ---------------------- | ----------------------------- |
| `gt create -m "msg"`   | Create new branch with commit |
| `gt modify -m "msg"`   | Amend current branch's commit |
| `gt submit`            | Submit current PR             |
| `gt submit --stack`    | Submit entire stack           |
| `gt sync`              | Sync stack with trunk         |
| `gt restack`           | Rebase stack after conflicts  |
| `gt log`               | View current stack            |
| `gt checkout <branch>` | Switch to branch in stack     |

## When NOT to Stack

- Single-file bug fixes (< 50 lines)
- Documentation-only changes
- Config/dependency updates
