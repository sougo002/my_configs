# Code Review Checklist

## Pre-Review Setup

```
- [ ] Understand the PR purpose (ticket/issue)
- [ ] Check branch naming convention
- [ ] Verify target branch is correct
```

## Code Quality

```
Readability:
- [ ] Clear naming (variables, functions, classes)
- [ ] Self-documenting code
- [ ] Comments explain "why", not "what"
- [ ] Consistent formatting

Structure:
- [ ] Functions are small (<20 lines preferred)
- [ ] Single responsibility per function/class
- [ ] No deeply nested logic (>3 levels)
- [ ] Appropriate abstractions

Maintainability:
- [ ] No magic numbers/strings
- [ ] Configuration externalized
- [ ] No dead code
- [ ] TODO/FIXME addressed or tracked
```

## Security

```
Input Handling:
- [ ] All user input validated
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (output escaped)
- [ ] Command injection prevented

Authentication & Authorization:
- [ ] Auth checks on all protected routes
- [ ] No IDOR vulnerabilities
- [ ] Tokens properly validated

Data Protection:
- [ ] No secrets in code
- [ ] Sensitive data encrypted
- [ ] Logs don't contain PII
- [ ] Proper error messages (no stack traces)
```

## Testing

```
Coverage:
- [ ] New code has tests
- [ ] Edge cases covered
- [ ] Error paths tested
- [ ] Existing tests updated if needed

Quality:
- [ ] Tests are independent
- [ ] Tests are readable
- [ ] No flaky tests
- [ ] Mocks used appropriately
```

## Performance

```
Efficiency:
- [ ] No N+1 queries
- [ ] Appropriate caching
- [ ] Pagination for large datasets
- [ ] No memory leaks

Resources:
- [ ] Connections/files closed
- [ ] Async operations used where appropriate
- [ ] No blocking operations in hot paths
```

## Error Handling

```
- [ ] Errors caught at appropriate level
- [ ] Meaningful error messages
- [ ] Proper logging of errors
- [ ] Graceful degradation where needed
```

## API/Interface Changes

```
- [ ] Backward compatibility considered
- [ ] Breaking changes documented
- [ ] API documentation updated
- [ ] Versioning handled properly
```

## Documentation

```
- [ ] README updated if needed
- [ ] API docs updated
- [ ] Changelog updated
- [ ] Inline comments for complex logic
```

## Final Checks

```
- [ ] CI/CD pipeline passes
- [ ] No merge conflicts
- [ ] Commit messages are clear
- [ ] PR description is complete
```

## Severity Guide

| Level | Criteria | Action |
|-------|----------|--------|
| **Critical** | Security vulnerability, data loss risk, breaking change | Block merge |
| **High** | Bug, design flaw, performance issue | Request changes |
| **Medium** | Style violation, missing tests | Suggest fix |
| **Low** | Nitpick, optional improvement | Optional comment |
