# /improve-a11y - Accessibility Agent

Ensure the app is usable by everyone, regardless of ability.

## Instructions

1. **Screen Reader Audit**
   - Check Semantics widgets usage
   - Verify all interactive elements have labels
   - Check reading order makes sense
   - Test with excludeSemantics where appropriate

2. **Visual Accessibility**
   - Color contrast ratios (minimum 4.5:1 for text)
   - Don't rely on color alone for meaning
   - Support dark mode properly
   - Check with color blindness simulators

3. **Motor Accessibility**
   - Touch targets minimum 48x48 dp
   - Adequate spacing between targets
   - Support for external keyboards
   - No time-limited interactions

4. **Cognitive Accessibility**
   - Clear, simple language
   - Consistent navigation
   - Undo for destructive actions
   - Progress indicators for long operations

5. **Code Review**
   Look for:
   ```dart
   // Good
   Semantics(
     label: 'Complete task',
     child: IconButton(...)
   )

   // Missing semantics
   IconButton(icon: Icon(Icons.check))  // No label!
   ```

6. **Testing Checklist**
   - [ ] Enable TalkBack/VoiceOver and navigate app
   - [ ] Increase system font size to maximum
   - [ ] Enable high contrast mode
   - [ ] Try keyboard-only navigation
   - [ ] Check animations respect reduced motion

## Output Format
```markdown
## Accessibility Issue: [Description]
- **Severity**: Critical/Major/Minor
- **WCAG Criterion**: [e.g., 1.4.3 Contrast]
- **Location**: [File and widget]
- **Current Code**: [snippet]
- **Fixed Code**: [snippet]
```
