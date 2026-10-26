# ST-POL-002 Independent Check

## Result

**PASS WITH CONDITIONS**

## Review objective

Independently review the proposed provider-neutral contract for `STANDARD`, `RESTRICTED` and temporary overlays before implementation authorization.

## Risk review

Classification: **YELLOW — 6/10**.

Rationale:

- no provider mutation is planned;
- no device enrollment occurs;
- however, this Story defines user-visible parental-control semantics and policy-composition rules that will directly influence later enforcement;
- incorrect precedence or expiry behavior could weaken protection or create confusing consumer behavior.

## Mandatory conditions

1. Product Input Gate must close before Authorized Base freeze.
2. PO must explicitly approve or amend the consumer semantics of `STANDARD`, `RESTRICTED` and the initial overlay set.
3. ST-POL-001 baseline remains immutable from ordinary mode/overlay composition.
4. Security / Threat Baseline always outranks Essential Services, modes, schedules and temporary overrides.
5. Mandatory Safety Restrictions cannot be removed by `ALLOW_SOCIAL` or any other overlay.
6. Essential Services may bypass ordinary leisure restrictions only.
7. Temporary overlays must have explicit bounded expiry, except `CLEAR_TEMPORARY` which is an action rather than an active overlay.
8. Expiry must restore the underlying persistent mode deterministically.
9. Conflicting overlays must resolve using domain rules, not Cloudflare rule order.
10. Provider IDs or expressions must not enter provider-neutral mode/overlay intent.
11. No child/device record or selector may be invented before enrollment.
12. Cloudflare remains read-only/non-mutated for the entire Story.
13. No output may claim `APPLIED`.
14. Compilation must remain blocked until scoped-enforcement prerequisites are later satisfied.
15. PII and secrets must remain absent from versioned desired state and evidence.

## Product semantics review

The recommended first-family model is coherent and intentionally small:

- `STANDARD`: baseline only;
- `RESTRICTED`: baseline + social/gaming/entertainment leisure restrictions;
- `STUDY`: bounded focus restriction;
- `ALLOW_SOCIAL`: bounded social exception;
- `PAUSE_ENTERTAINMENT`: bounded leisure pause;
- `CLEAR_TEMPORARY`: restore persistent mode.

This set supports progressive disclosure, reversibility, <=2-tap common actions and child explainability without overloading Phase 1.

The exact semantics remain a Product Owner decision and MUST NOT be silently frozen by the Technical Director or Development Agent.

## Required test classes

- baseline non-regression;
- mode-to-effective-policy composition;
- overlay-to-effective-policy composition;
- overlay expiry and restore;
- conflict ordering;
- Essential Services interaction;
- deterministic compilation;
- fail-closed malformed/unknown intent;
- provider-neutrality scan;
- no-mutation proof;
- privacy/secret scan.

## Stop conditions

Stop if:

- Product Input Gate remains open when implementation is about to be authorized;
- requested product semantics conflict materially with frozen architecture;
- a mode/overlay requires weakening the security baseline;
- provider mutation becomes necessary;
- safe device scope is assumed;
- an unexpected Auto-RED surface appears.

## Independent conclusion

The Story is structurally sound and may proceed through preflight, but implementation readiness is conditional on explicit Product Owner approval of the first-family mode and overlay semantics.
