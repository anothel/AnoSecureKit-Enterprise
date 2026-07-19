# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# Development Freeze and Change Policy

Enterprise 0.1.0 is in pre-GA development freeze. The blocker registry is the
work queue; unnamed abstract contracts and speculative expansion stop here.

## Allowed changes

- directly reduce a named open blocker and update its exact evidence;
- fix a correctness or security regression;
- update a dependency revision with full requalification;
- integrate an approved AnoCrypto-C package without changing upstream source;
- restore billing/hosted execution and collect required hosted evidence;
- activate an approved operational channel/system through its existing gate;
- update a blocker status only from real evidence; or
- implement an explicitly approved decision recorded by blocker ID.

## Forbidden without explicit blocker approval

- new abstract policy, schema, fixture, or document contract;
- speculative vendor adapter or unselected system integration;
- new customer-release, evidence, or authorization mechanism;
- unsupported profile/capability claim without evidence;
- Community private patch;
- cryptographic primitive implemented inside Enterprise for AnoCrypto-C;
- v1 format or public compatibility change;
- GA, production, active-support, KCMVP, or FIPS claim; or
- documentation work that reduces no blocker and is not a named LATER item.

## Change proof

Every allowed change names blocker IDs in its plan/review, states the completion
condition it reduces, reruns the affected qualification plus aggregate gates,
and preserves `customer_release_ready: false` until independent release
authorization passes. `verified-closed` requires evidence, exact revision
binding, and validator PASS. Reopening is allowed when evidence is stale,
revoked, contradicted, or affected by a dependency/source change.

```text
NOW: none
```

No locally actionable named blocker exists at this baseline. Do not invent one.
