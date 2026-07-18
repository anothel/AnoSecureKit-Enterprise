# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Security Operations Role Model

This model names functions, not people. It grants no production access,
customer authority, disclosure authority, support commitment, or release
approval. Every role remains unassigned until a separately approved operating
process records an assignment.

## Roles

### `security-intake-owner`

```text
assignment:
not yet assigned
```

Owns activated private intake, receipt records, data minimization, and handoff
to the incident commander. No private intake is currently active.

### `incident-commander`

```text
assignment:
not yet assigned
```

Owns incident state, scope, severity, containment decisions, decision log, and
closure criteria.

### `product-owner`

```text
assignment:
not yet assigned
```

Owns Enterprise adapter, policy, diagnostics, package, and release-control
remediation.

### `community-liaison`

```text
assignment:
not yet assigned
```

Routes Community OpenSSL provider, public API, generic provider seam, and v1
format defects upstream. This role cannot authorize a private Enterprise patch
to the Community subtree.

### `anocrypto-c-liaison`

```text
assignment:
not yet assigned
```

Routes AnoCrypto-C primitive, API, ABI, and package defects upstream and
records the approved replacement package identity and digest.

### `release-authorizer`

```text
assignment:
not yet assigned
```

May issue a fresh authorization only after every required qualification,
evidence, artifact, security, support, and legal gate passes. Incident command
cannot self-authorize release.

### `evidence-reviewer`

```text
assignment:
not yet assigned
```

Invalidates affected hosted, CodeQL, attestation, signing, provenance,
revocation, manifest, SBOM, and artifact evidence and reviews fresh evidence.

### `customer-communications-owner`

```text
assignment:
not yet assigned
```

Coordinates notices only through a separately activated channel and only for
affected customer releases. Tabletop records never send a notice.

## Separation and current channel state

Evidence review and release authorization are separate decisions. Dependency
liaisons cannot patch upstream-owned source here. Customer communications do
not begin from a repository fixture.

```text
private vulnerability reporting: not yet activated
security contact: not yet published
public disclosure channel: not yet activated
```
