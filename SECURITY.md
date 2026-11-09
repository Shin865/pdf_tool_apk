# Security Policy

## Supported Versions

Only the latest release of Document Reviewer is supported for security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

---

## Reporting a Vulnerability

Document Reviewer takes security and user privacy with paramount seriousness. Because Document Reviewer is designed to operate 100% offline with zero remote telemetry, vulnerabilities typically concern:
- Local file sandboxing breaches or path traversal attacks.
- Flaws in the PBKDF2 + AES-256 backup archive encryption scheme.
- Unhandled native exceptions in Apache POI or PDFBox parsers that could lead to crashes or data corruption.

### How to Report
Please **DO NOT** report security vulnerabilities via public GitHub issues.

Instead, please report security issues through **GitHub Private Vulnerability Reporting** on our repository, or email the security maintainers at:
`security@documentreviewer.app` (or submit via your trusted security contact).

### What to Include
- Detailed description of the vulnerability and attack vector.
- Reproduction steps or minimal malicious document fixture.
- Proof of concept demonstrating unexpected execution or data exposure.

### Response Timeline
- **Initial Response**: Within 48 hours acknowledging receipt.
- **Triage & Assessment**: Within 5 business days.
- **Patch Release**: Critical security fixes will be prioritized and published in a targeted point release.
