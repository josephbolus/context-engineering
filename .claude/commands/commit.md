# Commit Changes

You are tasked with creating git commits for the changes made during this session. If there is no established history, adopt Conventional Commits  to set the baseline.

# https://medium.com/@aslandjc7/git-is-a-powerful-version-control-system-but-writing-clear-and-meaningful-commit-messages-is-48eebc428a00

## Process:

1. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Inspect the working tree for sensitive files before initializing a repository, staging files, committing, or pushing
   - Review `.gitignore` and the example environment file to ensure sensitive files are excluded from version control
   - If a potentially sensitive file is already tracked, do not assume adding it to `.gitignore` is sufficient; explicitly identify it and stop before committing or pushing
   - Run `git status` to see current changes
   - Run `git diff` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits



2. **Plan your commit(s):**
   - Identify which files belong together
   - Draft clear, descriptive commit messages
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what

3. **Present your plan to the user:**
   - List the files you plan to add for each commit
   - Show the commit message(s) you'll use
   - Ask: "I plan to create [N] commit(s) with these changes. Shall I proceed?"

4. **Execute upon confirmation:**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show the result with `git log --oneline -n [number]`
   - Use `git add` with specific files (never use `-A` or `.`)
   - Never commit the `thoughts/` directory or anything inside it!
   - Never commit dummy files, test scripts, or other files which you created or which appear to have been created but which were not part of your changes or directly caused by them (e.g. generated code)
   - Create commits with your planned messages until all of your changes are committed with `git commit -m`

## Conventional Commits Specifications

Following a structured commit format helps: 
- Improve project history readability 
- Streamline collaboration in teams 
- Enable automation (e.g., automatically generating CHANGELOGs., release versioning, triggering build and publish processes.) 
- Make debugging and rollbacks easier

### Branch Types and Conventions:

feat/ (Feature Branch):
Purpose: Used for developing new features that add functionality to the application or system.

Convention: feat/<short-description-of-feature> or feat/<ticket-id>-<short-description-of-feature>.
Example: feat/user-authentication, feat/AB-123-implement-dark-mode.

chore/ (Chore Branch):
Purpose: Used for maintenance tasks, updates, or other activities that do not directly add new features or fix bugs for end-users, but are necessary for the project's health or development process.

Convention: chore/<short-description-of-task> or chore/<ticket-id>-<short-description-of-task>.
Example: chore/update-dependencies, chore/clean-up-build-scripts.

fix/ or hotfix/ (Fix Branch):
Purpose: Used for addressing bugs or issues in the existing codebase. "Hotfix" is typically reserved for urgent fixes to production.

Convention: fix/<short-description-of-bug> or fix/<ticket-id>-<short-description-of-bug>. For hotfixes: hotfix/<version-number>-<short-description-of-fix>.
Example: fix/login-bug, fix/GH-456-broken-link, hotfix/1.0.1-critical-security-patch.

### Other examples:

🎨 style: Code Formatting (No Logic Changes)
Use style for purely aesthetic changes like indentation, whitespace, or semicolons.
git commit -m "style: fix indentation in courseDetail component"

🔄 refactor: Code Improvement Without Changing Functionality
Use refactor when restructuring code without altering behavior.
git commit -m "refactor: optimize database query performance"

📄 docs: Documentation Updates
Use docs when updating README files, inline comments, or API documentation.
git commit -m "docs: update API usage guide for user authentication"

⚡ perf: Performance Improvements
Use perf when optimizing speed or memory usage.
git commit -m "perf: improve response time for course search API"

🧪 test: Adding or Updating Tests
Use test when writing or modifying test cases.
git commit -m "test: add unit tests for course enrollment logic"

🔧 ci: Changes to CI/CD Configuration
Use ci when updating CI/CD pipelines or workflows.
git commit -m "ci: update GitHub Actions to trigger tests on PRs"

## Best Practices for Writing Commit Messages:

- Use the imperative mood (e.g., “fix bug,” not “fixed bug”).
- Keep it concise but clear (Aim for 50–72 characters in the first line).
- Add details when necessary (use -m for a longer description).

Example of a detailed commit:
```
git commit -m "feat: implement course filtering by category" -m "Allows users to filter courses based on selected tags. Uses React state and URL parameters."
```

## Important:
- **NEVER add co-author information or Claude attribution**
- Commits should be authored solely by the user
- Do not include any "Generated with Claude" messages
- Do not add "Co-Authored-By" lines
- Write commit messages as if the user wrote them

## Remember:
- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit
