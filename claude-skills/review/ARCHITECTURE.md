# Architecture & Design Review Guide

## SOLID Principles

### Single Responsibility (SRP)
- Does class/function do one thing well?
- Would changes to one feature affect unrelated code?

```typescript
// Bad: Mixed concerns
class UserService {
	createUser() { /* ... */ }
	sendEmail() { /* ... */ }
	generateReport() { /* ... */ }
}

// Good: Separated concerns
class UserService { createUser() { /* ... */ } }
class EmailService { send() { /* ... */ } }
class ReportService { generate() { /* ... */ } }
```

### Open/Closed (OCP)
- Can behavior be extended without modifying existing code?
- Are abstractions used appropriately?

### Liskov Substitution (LSP)
- Can subtypes replace base types without breaking?
- Are inherited methods semantically consistent?

### Interface Segregation (ISP)
- Are interfaces small and focused?
- Do clients depend only on methods they use?

### Dependency Inversion (DIP)
- Do high-level modules depend on abstractions?
- Are dependencies injectable?

## Other Design Principles

### DRY (Don't Repeat Yourself)
- Duplicated logic across multiple locations?
- Common patterns that should be extracted?

### YAGNI (You Aren't Gonna Need It)
- Over-engineered solutions?
- Unused flexibility/configurability?

### KISS (Keep It Simple)
- Unnecessarily complex logic?
- Could a simpler approach work?

## Code Smells

| Smell | Symptom | Action |
|-------|---------|--------|
| Long Method | >20 lines | Extract methods |
| Large Class | >200 lines | Split responsibilities |
| Long Parameter List | >3 params | Use object/builder |
| Feature Envy | Method uses other class more | Move method |
| Data Clumps | Same data groups appear together | Create class |
| Primitive Obsession | Primitives instead of small objects | Value objects |
| Shotgun Surgery | One change requires many edits | Consolidate |
| Divergent Change | One class changed for different reasons | Split class |

## Dependency Management

### Good Patterns
- Dependency injection
- Interface-based coupling
- Layer separation (presentation/business/data)

### Bad Patterns
- Circular dependencies
- God objects
- Tight coupling to concrete implementations

```bash
# Check for circular dependencies (TypeScript)
npx madge --circular src/
```

## API Design

### REST
- Proper HTTP methods (GET/POST/PUT/DELETE)
- Consistent naming (`/users/{id}` not `/getUser`)
- Appropriate status codes
- Versioning strategy

### Error Handling
- Consistent error response format
- Appropriate error granularity
- No sensitive info in errors

## Performance Considerations

| Issue | Pattern | Check |
|-------|---------|-------|
| N+1 queries | Loop with DB calls | Use joins/batch |
| Memory leaks | Unclosed resources | Check cleanup |
| Unbounded results | No pagination | Add limits |
| Blocking I/O | Sync in async context | Use async |

## Testability

- Can components be tested in isolation?
- Are dependencies mockable?
- Is test data easy to set up?
- Are side effects isolated?
