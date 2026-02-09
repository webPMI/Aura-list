# /init - Orchestrate Improvement Agents

Launch multiple specialized agents to analyze and improve the checklist app holistically.

## Purpose
This command orchestrates a team of AI agents, each specialized in different aspects of app improvement, working together to make the app better for users' productivity and wellbeing.

## Instructions

### Phase 1: Project Analysis
First, quickly analyze the current state:
1. Read `lib/main.dart` to understand app structure
2. Read key files in `lib/screens/`, `lib/widgets/`, `lib/providers/`
3. Check `pubspec.yaml` for current capabilities

### Phase 2: Launch Specialized Agents (in parallel)
Use the Task tool to launch these agents simultaneously:

#### 1. UX/UI Agent (`subagent_type: Explore`)
Prompt: "Analyze the checklist app's UI/UX in lib/screens/ and lib/widgets/. Focus on:
- User flow for creating/completing tasks
- Visual hierarchy and clarity
- Gesture support and interactions
- Empty states and loading states
- Error feedback to users
Suggest 3-5 concrete improvements that would make task management more delightful."

#### 2. Productivity Features Agent (`subagent_type: Explore`)
Prompt: "Analyze the checklist app and suggest features that improve users' productivity:
- Smart task organization (categories, priorities, due dates)
- Quick capture capabilities
- Reminders and notifications
- Recurring tasks
- Task templates
- Focus mode / Today view
Suggest 3-5 high-impact features not yet implemented."

#### 3. Wellbeing Agent (`subagent_type: Explore`)
Prompt: "Analyze how the checklist app could better support users' mental wellbeing:
- Celebration of completed tasks
- Progress visualization
- Avoiding overwhelm (task limits, priority guidance)
- Mindful notifications
- Daily/weekly reviews
- Streak tracking without anxiety
Suggest 3-5 features that balance productivity with peace of mind."

#### 4. Code Quality Agent (`subagent_type: Explore`)
Prompt: "Review the checklist app code quality:
- Architecture patterns (clean separation of concerns)
- Error handling completeness
- State management best practices
- Performance considerations
- Test coverage gaps
Identify 3-5 technical improvements for maintainability."

#### 5. Accessibility Agent (`subagent_type: Explore`)
Prompt: "Evaluate the checklist app's accessibility:
- Screen reader support (semantics)
- Color contrast
- Touch target sizes
- Keyboard navigation
- Dynamic text scaling
Suggest 3-5 accessibility improvements for inclusive design."

### Phase 3: Synthesize Results
After all agents complete:
1. Collect all suggestions
2. Categorize by: Quick Wins, Medium Effort, Major Features
3. Prioritize by impact on users' daily lives
4. Create a roadmap in `IMPROVEMENTS.md`

### Phase 4: Present to User
Present a summary:
```
## Improvement Analysis Complete

### Quick Wins (can implement today)
- [List items]

### Medium Effort (1-3 features)
- [List items]

### Major Features (future roadmap)
- [List items]

### Recommended First Steps
1. [Most impactful quick win]
2. [Most requested feature]
3. [Critical accessibility fix]
```

Ask user: "Which improvements would you like to implement first?"

## Philosophy
This app helps people organize their lives. Every improvement should:
- Reduce cognitive load
- Respect users' time and attention
- Celebrate progress without creating anxiety
- Be accessible to everyone
- Bring a moment of calm to a busy day
