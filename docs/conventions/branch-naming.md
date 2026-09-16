# Branch Naming Conventions

Branch names should make it immediately clear **what kind of work** is happening and **which issue** it's tied to.

## Format

```
<type>/#<issue-number>-<short-description>
```

**Example:**
```
feat/#42-user-profile-page
fix/#108-payment-webhook-null-check
refactor/#215-extract-auth-middleware
docs/#77-update-api-setup-instructions
chore/#93-bump-eslint
test/#134-session-expiry-coverage
```

## Field breakdown

| Field | Example | Meaning |
|---|---|---|
| `type` | `feat` | Same vocabulary to commit messages |
| `issue-number` | `#42` | The tracked issue this branch addresses |
| `short-description` | `user-profile-page` | A few kebab-case words describing the change |

## Allowed types

Same as [commit-messages.md](./commit-messages.md):


## Guidelines

- Use **kebab-case** for the description (lowercase, hyphens, no underscores or spaces).
- Keep the description short — 3–5 words is usually enough.
- Omit the issue number only if there's genuinely no tracked issue (rare — prefer creating one).
- Branch names should stay stable for the life of the branch; don't rename mid-work.
