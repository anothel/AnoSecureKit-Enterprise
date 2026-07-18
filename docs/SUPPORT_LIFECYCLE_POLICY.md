# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

# AnoSecureKit Enterprise Support Lifecycle Policy

## Lifecycle states

Support applies only to an exact released version, qualified platform row,
backend profile, Community dependency, and authorized artifact set. It is never
inferred from source availability, a passing local build, or an internal
archive.

| State | Allowed changes | Security fixes | Compatibility fixes | New features | Qualification scope | Backend and dependency scope | Notice and emergency withdrawal | Customer delivery |
|---|---|---|---|---|---|---|---|---|
| `supported` | Qualified fixes and planned release work | Yes | Yes, within documented compatibility policy | Yes, through normal review | Exact published platform matrix; new rows require fresh qualification | Only published backend profiles and exact approved Community/AnoCrypto-C identities | Normal transitions announced through release notes and this policy; immediate withdrawal allowed for security or evidence compromise | Only with current trusted evidence and release authorization |
| `maintenance` | Defect, dependency, packaging, and security maintenance | Yes | Yes when needed to preserve documented behavior | No, except a separately reviewed new release line | Existing qualified rows; no inferred expansion | Existing approved profiles; dependency updates require requalification | Maintenance or end-of-support transition announced before it takes effect when practicable; emergency withdrawal remains immediate | Existing qualified releases and approved maintenance updates only |
| `security-fixes-only` | Security patches and changes strictly required to deliver them | Yes | Only when required for the security fix | No | Frozen to affected qualified rows plus verification needed for the fix | Security updates to approved dependencies only; no new backend | End-of-support intent announced when practicable; unsafe artifacts may be withdrawn immediately | Only a freshly authorized security update; affected artifacts are not deliverable |
| `end-of-support` | No product changes promised | No | No | No | Qualification expires for support purposes | No supported backend or dependency combination | Recorded effective date and final safe-upgrade guidance when available | No |
| `unsupported` | Internal, experimental, unqualified, unknown, or post-support work | No commitment | No commitment | No commitment | None | No supported backend or dependency combination | May be blocked or removed without support notice; security evidence compromise triggers immediate release blocking | No |

Community owns the common public API, v1 formats, generic provider seam, and
OpenSSL provider. Enterprise may consume only a Community-approved revision
after Enterprise requalification. AnoCrypto-C owns its primitive, API, ABI, and
package defects. Enterprise owns its adapter, policy, diagnostics, package, and
release controls. Enterprise does not patch either dependency's source.

## Lifecycle decisions and announcements

The release owner records each supported version's state, effective date,
qualified configurations, backend profile, dependency identities, and upgrade
path in release notes or a successor lifecycle register before customer use.
Normal state transitions are announced through repository release notes and
any separately activated private customer channel. No contractual notice
period exists unless a customer contract explicitly creates one.

Emergency support withdrawal may occur without advance notice when an artifact,
manifest, SBOM, signature, provenance statement, authorization, signing
identity, verifier, trust root, Community revision, or AnoCrypto-C digest is
compromised or materially unsafe. Withdrawal blocks new delivery and requires
the response in
[SECURITY_RELEASE_AND_REVOCATION_POLICY.md](SECURITY_RELEASE_AND_REVOCATION_POLICY.md).

## Current version

Enterprise `0.1.0` is `unsupported` pre-release/internal qualification work.
No version is currently `supported`, `maintenance`, or
`security-fixes-only`. Active customer support, general availability, and
production release status are all false. Internal delivery artifacts are not
customer releases, and `customer_release_ready: false` remains mandatory.
