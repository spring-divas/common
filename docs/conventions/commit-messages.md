# Commit Message Conventions

This project follows [Conventional Commits](https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13) with one important modification: **the scope field holds the related issue number, not a component name.**

## Format

```
<type>(#<issue-number>): <short description> (#<pr-number>)
```

**Example:**
```
feat(#42): add user profile (#67)
```

## Field breakdown

| Field | Example | Meaning |
|---|---|---|
| `type` | `feat` | The kind of change (see list below) |
| `scope` | `(#42)` | The **issue number** this commit addresses — not a module/component name |
| description | `add user profile` | Short, imperative summary of the change |
| trailing ref | `(#67)` | The **pull request number**, usually auto-appended by the platform on merge — don't add this manually |


## Allowed types

| Type | Use for |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `style` | Formatting, whitespace, missing semicolons — no code logic change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `chore` | Build process, tooling, or dependency changes |