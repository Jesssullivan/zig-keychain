# Security Policy

zig-keychain stores and retrieves generic secrets through platform credential stores. Treat suspected memory-safety, secret-handling, backend integration, build-chain, package metadata, or documentation issues as security-sensitive until they are triaged.

## Reporting a Vulnerability

Do not open a public issue with vulnerability details, secrets, tokens, credentials, private logs, or keychain payloads that contain sensitive content.

Use GitHub's private vulnerability reporting flow for this repository when it is available. If GitHub does not offer a private reporting button, open a minimal public issue asking for a private contact path and omit technical details until a private channel exists.

Useful initial context for a private report:

- affected version or commit
- platform and Zig version
- affected API surface (`zig_keychain.h`, Zig package API, macOS Security.framework backend, Linux libsecret backend, build/package metadata, or docs)
- minimal reproduction, if it can be shared safely
- whether the issue affects confidentiality, integrity, availability, memory safety, secret lifetime, or API misuse risk

## Supported Versions

Security fixes target the latest released version and `main`. Older tags may receive follow-up notes when a vulnerability is confirmed, but active fixes should be developed against current `main`.
