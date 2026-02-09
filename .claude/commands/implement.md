# /implement - Implement an Improvement

Take an improvement from the roadmap and implement it.

## Arguments
- `$ARGUMENTS` - Improvement ID or description

## Instructions

1. **Find the Improvement**
   - Read `IMPROVEMENTS.md`
   - Find the improvement by ID or keyword
   - Show details and confirm with user

2. **Plan Implementation**
   - Analyze what files need to change
   - Break down into steps
   - Create todo list with TodoWrite

3. **Implement**
   - Follow the project's code conventions (see CLAUDE.md)
   - Create new files using appropriate `/widget`, `/provider`, etc.
   - Update existing files carefully
   - Add tests if appropriate

4. **Verify**
   - Run `/analyze` to check for issues
   - Run `/test` if tests exist
   - Manually verify the feature works

5. **Update Roadmap**
   - Mark improvement as completed in `IMPROVEMENTS.md`
   - Add completion date
   - Note any follow-up items discovered

6. **Summarize**
   - Show what was changed
   - Explain how to use the new feature
   - Suggest what to implement next

## Guidelines
- Make atomic commits (one improvement = one commit)
- Don't over-engineer
- Maintain existing code style
- Update CLAUDE.md if patterns change
