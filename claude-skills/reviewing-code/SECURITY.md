# Security Review Guide

## OWASP Top 10 Checklist

### 1. Injection
- SQL: Parameterized queries used?
- Command: User input sanitized before shell execution?
- LDAP/XPath: Input validated?

```javascript
// Bad
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// Good
db.query('SELECT * FROM users WHERE id = ?', [userId]);
```

### 2. Broken Authentication
- Password hashing with bcrypt/argon2?
- Session tokens properly managed?
- MFA implemented for sensitive actions?

### 3. Sensitive Data Exposure
- Secrets in code? (API keys, passwords)
- Data encrypted at rest and in transit?
- PII properly handled?

```bash
# Search for potential secrets
grep -rn "password\|secret\|api_key\|token" --include="*.{js,ts,py,json}"
```

### 4. XXE (XML External Entities)
- XML parsing disabled external entities?
- DTD processing disabled?

### 5. Broken Access Control
- Authorization checks on all endpoints?
- IDOR vulnerabilities? (user can access other users' data)
- Principle of least privilege applied?

### 6. Security Misconfiguration
- Debug mode disabled in production?
- Default credentials changed?
- Unnecessary features disabled?

### 7. XSS (Cross-Site Scripting)
- User input escaped in HTML output?
- Content-Security-Policy headers set?
- DOM manipulation safe?

```javascript
// Bad
element.innerHTML = userInput;

// Good
element.textContent = userInput;
```

### 8. Insecure Deserialization
- Untrusted data deserialized?
- Object types validated before deserialization?

### 9. Using Components with Known Vulnerabilities
- Dependencies up to date?
- Known CVEs in dependencies?

```bash
# Check for vulnerabilities
npm audit
pip-audit
```

### 10. Insufficient Logging & Monitoring
- Security events logged?
- Sensitive data excluded from logs?
- Alerts configured for anomalies?

## Language-Specific Concerns

### JavaScript/TypeScript
- `eval()` usage
- `dangerouslySetInnerHTML` in React
- Prototype pollution
- RegExp DoS

### Python
- `pickle` with untrusted data
- `subprocess` with shell=True
- Format string vulnerabilities

### Go
- Race conditions
- Integer overflow
- Unsafe pointer usage

### SQL
- Raw queries vs ORM
- Stored procedure injection
- Privilege escalation

## Red Flags

| Pattern | Risk |
|---------|------|
| Hardcoded credentials | Critical |
| `eval()` / `exec()` | Critical |
| SQL string concatenation | Critical |
| Disabled SSL verification | High |
| Overly permissive CORS | High |
| Missing auth middleware | High |
| Verbose error messages | Medium |
