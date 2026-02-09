# /roadmap - View and Manage Improvement Roadmap

View, update, or prioritize the app improvement roadmap.

## Arguments
- `$ARGUMENTS` - Action: `show`, `add`, `complete`, `prioritize`

## Instructions

### For `show` or no argument:
1. Read `IMPROVEMENTS.md` if it exists
2. Display improvements grouped by:
   - In Progress
   - Quick Wins (ready to implement)
   - Planned Features
   - Backlog
3. Show completion statistics

### For `add [description]`:
1. Add new improvement to `IMPROVEMENTS.md`
2. Ask for category (UX, Feature, Wellbeing, A11y, Code)
3. Ask for effort (Quick Win, Medium, Major)
4. Ask for priority (High, Medium, Low)

### For `complete [id]`:
1. Mark improvement as completed
2. Move to "Completed" section with date
3. Celebrate! Show progress stats

### For `prioritize`:
1. Show all pending improvements
2. Use AskUserQuestion to let user rank top priorities
3. Reorder the roadmap accordingly

## Roadmap File Format
```markdown
# Checklist App Improvements

## In Progress
- [ ] #1 [Category] Description - Started: date

## Quick Wins
- [ ] #2 [UX] Improvement description

## Planned Features
- [ ] #3 [Feature] Feature description

## Backlog
- [ ] #4 [Code] Technical debt item

## Completed
- [x] #0 [Category] What was done - Completed: date
```
