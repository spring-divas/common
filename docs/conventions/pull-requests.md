# Pull Request Conventions

Pull requests should be easy to review and easy to trace back to the issue they address.

## Title

Follow the same format as commit messages:

```
<type>(#<issue-number>): <short description>
```

**Example:**
```
feat(#42): add user profile page
```

If the PR contains multiple commits of different types, use the type that best represents the overall change.

## Description template

```markdown
### Summary
<One or two sentences describing what this PR does and why.>
Closes #<issue-number>

### Changes
- <Key change 1>
- <Key change 2>
```

## Guidelines

- **Keep PRs small and focused.** One issue, one PR, where possible.
- **Link the issue** using a closing keyword (`Closes #42`, `Fixes #42`) so it auto-closes on merge.
- **Self-review before requesting review** — read your own diff first.
- **Squash-merge** unless the team has agreed otherwise, so the merged commit follows the [commit message convention](./commit-messages.md) and the PR number is appended automatically.
- **Don't merge your own PR** without at least one approval, except for trivial/urgent fixes agreed with the team.
