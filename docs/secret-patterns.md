# Secret-pattern catalog

This file documents every regex shipped with `ccaudit` in `hooks/auto-flush.sh`. Each entry explains *what* the pattern catches, *why* it is conservative the way it is, and *how* to recognize false positives.

The list is intentionally small and generic. Anything organization-specific (internal token prefixes, company hostnames, custom secret formats) belongs in `CCAUDIT_PRE_FLUSH_HOOK`, never here.

## How to use this document

- When you add or modify a pattern in `hooks/auto-flush.sh`, update this file in the same commit.
- When you read a flush log that says `secret pattern matched: <regex>`, look up the regex here to understand what triggered.
- When auditors ask "what does the secret scan actually cover?", point them here — the answer is exhaustive.

## A note on examples

Example strings in this file use angle-bracket placeholders (e.g. `glpat-<20-char-payload>`) instead of realistic token shapes. This is deliberate: any string that visually conforms to a real token format can be flagged by upstream secret scanners (including GitHub push protection) and prevent the documentation itself from being committed. Keep that convention when adding new sections.

## Patterns

### GitHub PAT (classic)

```regex
ghp_[A-Za-z0-9]{36}
```

| Aspect | Detail |
|---|---|
| Token prefix | `ghp_` (literal, fixed) |
| Body | 36 chars from `[A-Za-z0-9]` — letters and digits, no symbols |
| Format reference | Introduced in 2021; documented in GitHub's token format announcement |
| Matches | `ghp_<36-char-payload>` — i.e. the literal `ghp_` prefix followed by exactly 36 characters from the `[A-Za-z0-9]` alphabet |
| Does not match | `ghp_short`, `ghp_AbCd` (length filter); any string whose payload is shorter than 36 chars or contains characters outside the alphabet |
| False positives | Very low. The 36-char fixed length and `ghp_` prefix together are distinctive enough that natural prose almost never matches |
| Notes | Fine-grained PATs (`github_pat_...`) are a different format, covered separately when added |

### GitLab PAT

```regex
glpat-[A-Za-z0-9_-]{20}
```

| Aspect | Detail |
|---|---|
| Token prefix | `glpat-` (literal, fixed) |
| Body | 20 chars from `[A-Za-z0-9_-]` — letters, digits, underscore, hyphen |
| Format reference | Introduced in GitLab 14.5 (Nov 2021) |
| Matches | `glpat-<20-char-payload>` — i.e. the literal `glpat-` prefix followed by exactly 20 characters from the `[A-Za-z0-9_-]` alphabet |
| Does not match | `glpat-example`, `glpat-abc` (length filter); any string whose payload is shorter than 20 chars or contains characters outside the alphabet |
| False positives | Low. The combination of fixed prefix and 20-char length filters out short example strings |
| Notes | Hyphen is placed at the end of the character class (`_-`) to be interpreted as a literal, not a range |

### AWS Access Key ID

```regex
AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}
```

| Aspect | Detail |
|---|---|
| Token prefix | `AKIA` (IAM user permanent key) or `ASIA` (STS temporary credentials) |
| Body | 16 chars from `[A-Z0-9]` — uppercase letters and digits only |
| Total length | 20 characters |
| Format reference | AWS access key format, documented across IAM and STS API references |
| Matches | `AKIA<16-char-uppercase-alnum-payload>`, `ASIA<16-char-uppercase-alnum-payload>` |
| Does not match | Lowercase variants; payloads with symbols; `AROA...` / `AGPA...` (these are identifiers, not credentials) |
| False positives | Low. The 4-char prefix combined with the uppercase-only 16-char body is restrictive |
| Notes | Other AWS resource ID prefixes exist (`AROA`, `AGPA`, `AIDA`, `ANPA`); they are excluded because they identify resources but do not authenticate API requests. The pattern uses alternation (`\|`) over a character class (`A[KS]IA...`) so future readers can grep for the literal prefixes |

### OpenAI API key

```regex
sk-[A-Za-z0-9]{48}
sk-proj-[A-Za-z0-9_-]{40,}
```

Two patterns, one per format family. Listed separately so each family can carry its own alphabet and length constraint.

| Aspect | Detail |
|---|---|
| Token prefix | `sk-` (classic) or `sk-proj-` (project keys, 2024+) |
| Body (classic) | 48 chars from `[A-Za-z0-9]` — letters and digits only |
| Body (project) | 40+ chars from `[A-Za-z0-9_-]` — allows underscore and hyphen; upper length is unbounded |
| Total length | 51 (classic) or 48+ (project) |
| Format reference | OpenAI does not publish a strict format spec; pattern derived from observed tokens |
| Matches | `sk-<48-char-alnum-payload>`, `sk-proj-<40+ char payload with optional _ and ->` |
| Does not match | `sk-test`, `sk-config`, `sk-learn` (too short); strings without an `sk-` prefix |
| False positives | Low for classic (48-char alnum is rare in prose). The project pattern is wider; the `{40,}` lower bound rejects short example tokens while still allowing arbitrarily long real keys |
| Notes | `sk-svcacct-...` (service account keys) and `sk-admin-...` (admin keys, late 2024) follow the same family but are not yet enumerated. Add separate lines once their formats are confirmed by an authoritative source. The unbounded upper length on project keys is intentional — OpenAI does not publish a max length, and bounding it could cause false negatives on real long-form keys |

### GitHub PAT (fine-grained)

```regex
github_pat_[A-Za-z0-9_]{82}
```

| Aspect | Detail |
|---|---|
| Token prefix | `github_pat_` (literal, fixed, 11 chars) |
| Body | 82 chars from `[A-Za-z0-9_]` — letters, digits, underscore |
| Total length | 93 characters |
| Format reference | GitHub fine-grained personal access tokens (introduced 2022) |
| Matches | `github_pat_<82-char-payload>` — the literal prefix followed by exactly 82 chars from the alphabet |
| Does not match | Strings with payload shorter than 82 chars or containing characters outside the alphabet (e.g., hyphens, dots) |
| False positives | Very low. The 11-char prefix combined with the 82-char fixed length filters out almost everything except real fine-grained tokens |
| Notes | The internal structure of fine-grained PATs is `<22 chars>_<59 chars>` with the underscore in a fixed position. The regex accepts any 82-char string from `[A-Za-z0-9_]`, a superset of the precise format. This is intentional: matching the superset future-proofs the pattern against potential rebalancing of the internal segments by GitHub |

### PEM private key header

```regex
-----BEGIN [A-Z ]*PRIVATE KEY-----
```

| Aspect | Detail |
|---|---|
| Catches | The header line of any PEM-encoded private key (RSA, EC, DSA, OPENSSH, PKCS#8 plain or encrypted) |
| Strategy | Match the literal `-----BEGIN ` and ` PRIVATE KEY-----` boundaries; allow zero or more uppercase letters and spaces between them |
| Format reference | RFC 7468 (PEM) and OpenSSH key file format |
| Matches | `-----BEGIN <variant> PRIVATE KEY-----` where `<variant>` is one or more uppercase words separated by spaces, or empty (for PKCS#8 plain keys) |
| Does not match | Lowercase variants; headers for public keys, certificates, or CSRs (`-----BEGIN PUBLIC KEY-----`, `-----BEGIN CERTIFICATE-----`); lines that contain symbols or digits between the boundaries |
| False positives | Very low. The `-----BEGIN ... PRIVATE KEY-----` boundary phrase is distinctive enough that it almost never appears in normal prose unaccompanied by an actual key |
| Notes | Catching only the header is sufficient for a flush-time scan: if a header is present, the body almost certainly follows. The regex uses a bounded character class (`[A-Z ]*`) rather than `.*` so trail entries that incidentally contain `BEGIN` and `PRIVATE KEY-----` on the same line — separated by symbols, digits, or lowercase text — are not falsely matched. The `*` quantifier (zero-or-more) is what allows the empty-middle PKCS#8 case `-----BEGIN PRIVATE KEY-----` |

### JWT (JSON Web Token)

```regex
eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
```

| Aspect | Detail |
|---|---|
| Catches | Signed JSON Web Tokens with header, payload, and signature segments |
| Strategy | Anchor on `eyJ` (the base64url encoding of `{"`-prefixed JSON) at the start of both header and payload; require all three segments to be at least 10 base64url chars long |
| Format reference | RFC 7519 (JWT), RFC 7515 (JWS) |
| Matches | `eyJ<base64url-header>.eyJ<base64url-payload>.<base64url-signature>` |
| Does not match | Dot-separated identifiers like `cache.session.user.id`; SHA hashes; URL slugs; `alg=none` unsigned tokens (which have an empty signature segment) |
| False positives | Moderate-low. The `eyJ` anchor on both first and second segments cuts most non-JWT dot-separated strings. Remaining false positives are typically other base64-encoded JSON objects, which are rare in trail entries |
| Notes | The signature segment does not require the `eyJ` anchor — it is a binary signature value, not a JSON object. The dot is escaped (`\.`) because `.` matches any character in extended regex. The pattern intentionally rejects unsigned JWTs (`alg=none`); they are widely considered insecure and are rare in practice. The `eyJ` anchor exploits the fact that `{"` followed by any letter encodes to `eyJ<X>` in base64url — see the JWT spec or any base64 calculator for verification |

## Open categories (TODO)

All initial-roadmap categories are covered. The following are deferred pending authoritative format confirmation. Layer them on top via `CCAUDIT_PRE_FLUSH_HOOK` if you need coverage in the meantime.

- OpenAI service account / admin keys (`sk-svcacct-...`, `sk-admin-...`)
- Cloud provider keys (GCP service account, Azure SAS, etc.)

If your environment uses other token shapes (cloud provider keys, internal tokens, third-party SaaS), do not add them here. Use `CCAUDIT_PRE_FLUSH_HOOK` to layer them on top.

## Update protocol

1. Add or modify the regex in `hooks/auto-flush.sh` inside `scan_secrets()`.
2. Add or modify the matching section in this file with prefix, body, references, examples, and false-positive notes.
3. If the pattern is being removed, leave a note in this file about why (drift, replacement, false positive rate).
4. Commit both files together. A PR that touches only one of them should be rejected.
