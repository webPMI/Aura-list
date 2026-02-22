# AuraList Documentation

Welcome to the AuraList documentation hub. This guide will help you navigate our comprehensive documentation structure.

## 📚 Documentation Structure

```
docs/
├── README.md (you are here)
├── architecture/          # Technical architecture docs
├── features/             # Feature-specific documentation
│   ├── avatars/         # Avatar generation system
│   └── guides/          # Mystical guide characters
├── development/          # Development guides
└── releases/            # Implementation summaries
    └── implementations/ # Archived feature implementations
```

---

## 🎯 Quick Links

### For Users

- **[Main README](../README.md)** - Project overview and getting started
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute to AuraList

### For Developers

#### Architecture & Technical Docs

- **[Error Handling System](architecture/ERROR_HANDLING.md)** - Error boundaries, classification, and handling
- **[Database Refactoring Plan](architecture/DATABASE_REFACTORING_PLAN.md)** - Database schema and migration strategy
- **[Sync Audit Report](architecture/SYNC_AUDIT_REPORT.md)** - Firebase sync system audit

#### Features

- **[Avatar Generation](features/avatars/README.md)** - Complete avatar generation system
  - [Quick Start](features/avatars/QUICK_START.md)
  - [Scripts Reference](features/avatars/SCRIPTS_REFERENCE.md)
  - [Prompts Catalog](features/avatars/PROMPTS_REFERENCE.md)
  - [Guía en Español](features/avatars/es/README.md)

- **[Guides System](features/guides/)** - Mystical guide characters
  - [Character Documentation](features/guides/personajes-misticos/)

#### Development

- **[Improvements Roadmap](development/IMPROVEMENTS_ROADMAP.md)** - Active improvements and planned features
- **[Firebase Testing](development/FIREBASE_TESTING.md)** - Firebase integration testing guide

#### Release Documentation

- **[Achievements v1.0](releases/implementations/achievements-v1.0.md)**
- **[Affinity System v1.0](releases/implementations/affinity-v1.0.md)**
- **[Onboarding v1.0](releases/implementations/onboarding-v1.0.md)**

### For Claude Code AI

- **[CLAUDE.md](../CLAUDE.md)** - AI assistant instructions and project conventions

---

## 🚀 Getting Started

### New to AuraList?

1. Start with the **[Main README](../README.md)** for project overview
2. Review **[CLAUDE.md](../CLAUDE.md)** for development conventions
3. Check **[Contributing Guide](../CONTRIBUTING.md)** for contribution workflow

### Setting Up Development

```bash
# Install dependencies
flutter pub get

# Generate code (Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test
```

→ See [CLAUDE.md](../CLAUDE.md) for complete command reference

### Working on Features

**Avatar Generation:**
- Read [Avatar Quick Start](features/avatars/QUICK_START.md)
- Reference [Scripts Documentation](features/avatars/SCRIPTS_REFERENCE.md)

**Error Handling:**
- Review [Error Handling Guide](architecture/ERROR_HANDLING.md)
- Check implementation examples

**New Guide Characters:**
- Study existing [Character Docs](features/guides/personajes-misticos/)
- Follow character documentation template

---

## 📖 Documentation Standards

### File Organization

- **Root (`/`)** - Only README.md, CLAUDE.md, CONTRIBUTING.md
- **`docs/architecture/`** - System design, technical decisions
- **`docs/features/`** - Feature-specific guides and references
- **`docs/development/`** - Development guides and workflows
- **`docs/releases/`** - Implementation summaries and release notes

### Language Policy

- **English** - Primary language for all technical documentation
- **Spanish** - User-facing docs and guides in `*/es/` subdirectories
- **Bilingual** - Character lore and descriptions

### File Naming

- Use **kebab-case** for filenames: `error-handling.md`
- Use **UPPERCASE** for root-level docs: `README.md`, `CLAUDE.md`
- Prefix versions: `achievements-v1.0.md`

---

## 🔍 Finding Documentation

### By Topic

| Topic | Location |
|-------|----------|
| Architecture | `docs/architecture/` |
| Avatar Generation | `docs/features/avatars/` |
| Guide Characters | `docs/features/guides/` |
| Development Workflow | `docs/development/` |
| Past Implementations | `docs/releases/implementations/` |

### By Language

| Language | Location |
|----------|----------|
| English (Primary) | All `docs/` subdirectories |
| Spanish | `docs/*/es/` subdirectories |

---

## 🤝 Contributing to Documentation

### When to Update Docs

- **Before implementing** - Document design decisions
- **During implementation** - Update technical specs as needed
- **After completion** - Create implementation summary
- **Bug fixes** - Update relevant troubleshooting sections

### Documentation Checklist

When adding new features:

- [ ] Update relevant feature documentation
- [ ] Add troubleshooting section if applicable
- [ ] Update CLAUDE.md if new conventions added
- [ ] Create Spanish version for user-facing docs
- [ ] Update this README.md if new doc category added

### Style Guide

- **Headers:** Use sentence case (not title case)
- **Code blocks:** Always specify language for syntax highlighting
- **Links:** Use relative paths, not absolute
- **Examples:** Provide working code examples
- **Diagrams:** Use ASCII art or mermaid.js for flows

---

## 📝 Document Templates

### Feature Documentation Template

```markdown
# Feature Name

Brief description (1-2 sentences)

## Overview

What this feature does and why

## Quick Start

Minimal example to get started

## Usage

Detailed usage instructions

## API Reference

Complete API documentation

## Examples

Real-world usage examples

## Troubleshooting

Common issues and solutions
```

### Implementation Summary Template

```markdown
# Feature Name v1.0

**Implemented:** YYYY-MM-DD
**Status:** ✅ Complete / 🚧 In Progress / 📋 Planned

## Summary

What was implemented

## Changes

- List of changes
- By category (Added, Modified, Removed)

## Files Modified

- List of modified files with brief descriptions

## Testing

How to test the implementation

## Known Issues

Any known limitations or issues
```

---

## 🔗 External Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Riverpod Guide:** https://riverpod.dev
- **Hive Database:** https://docs.hivedb.dev
- **Firebase Docs:** https://firebase.google.com/docs

---

## 📞 Need Help?

- **Technical Questions:** Check [CLAUDE.md](../CLAUDE.md) for AI assistance
- **Contribution Questions:** See [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Bug Reports:** Open an issue in the repository
- **Feature Requests:** Discuss in [Improvements Roadmap](development/IMPROVEMENTS_ROADMAP.md)

---

**Last Updated:** 2026-02-22
**Documentation Version:** 2.0 (Reorganized structure)
