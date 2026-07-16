# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A flat collection of standalone SysML v2 textual-notation (`.sysml`) files. Each file is a small,
self-contained experiment probing one specific question about SysML v2 execution semantics —
`send`/`accept` message transfer, port/interface `flow` transfer, action binding vs. flow, ownership
of composite items across a transfer, and nondeterministic dispatch to parallel accepters. This is
not a buildable software project: there is no package manager, build system, linter, or test runner.
It is not a git repository.

## Working with these files

There is no compiler/simulator in this environment. Validation and semantic questions are handled
through the **Hypha** Claude Code plugin (`mycelium-hypha`), which is installed here:

- `hypha:sysml-validation` skill / `hypha:sysml-validator` agent — check a `.sysml` file's syntax and
  structure against the grammar and metamodel.
- `hypha:metamodel-lookup` skill / `hypha:metamodel-navigator` agent — look up how a metaclass
  (`AcceptActionUsage`, `TransitionUsage`, `SendActionUsage`, etc.) is defined, its features,
  redefinitions, and constraints.
- `hypha:spec-citation` skill — get verbatim, clause-cited OMG KerML/SysML v2 spec text for a
  semantics question. Its knowledge base is generated locally (git-ignored) from OMG PDFs via
  `tools/spec-extract` inside the plugin directory; if it's empty, that pipeline needs to be re-run
  (see the plugin's own README under `tools/spec-extract/`).

When adding a new experiment file, prefer running it past the validator skill and grounding any claim
about *why* it behaves a certain way in a spec citation rather than intuition — this codebase exists
specifically because SysML v2 transfer/accept/dispatch semantics are subtle and easy to get wrong
(see `send_fork_accept.sysml`'s note that its behavior differs from PSSM).

## File conventions

Every file follows the same shape:

```
package '<name>' {
  doc /* one- or two-line statement of the mechanism/question being probed */

  private import ScalarValues::Integer;
  private import VerificationCases::*;
  // sometimes also: ISQ::*, SI::*, Occurrences::*, IPI::*

  item def ...      // payload type(s)
  port def ...      // port type(s), if the scenario goes through ports
  interface def ...  // interface + flow, if the scenario goes through an interface
  part def ... { ... }   // or `action def` — the parts/actions under test

  verification '<name>' {   // or `case '<name>'` for nondeterministic scenarios
    subject subj : ...;
    doc /* Expectation: prose description of the expected runtime behavior */
  }
}
```

- The trailing `verification`/`case` block's `doc` comment is the actual assertion — expectations are
  recorded as prose, not (always) as executable `return verdict` checks. Where a `return verdict` line
  exists but is commented out (e.g. `bind_out_to_in.sysml`, `flow_out_to_in.sysml`), it's because the
  tooling available couldn't reach into a nested action's attribute — noted inline, not a TODO to
  silently "fix."
- File names describe the mechanism under test in snake_case (e.g. `send_via_accept.sysml` = send
  through an intermediary part, `bad_accept_filter.sysml` = an accept whose declared item type doesn't
  match the payload type, so it filters to the empty sequence).

## Semantic themes already explored here

- **Direct vs. mediated send/accept**: `send_accept.sysml`, `send_via_accept.sysml` — a `send` can
  target a receiver directly or route `via` an intermediary part.
- **Port/interface flow transfer**: `port_interface_flow.sysml`, `action_allocation.sysml` — moving an
  item from an output port to an input port across an `interface`'s `flow`, including allocating the
  same pattern onto `action`s directly (vs. `part`s) in `action_allocation.sysml`.
- **Type-mismatched accept**: `bad_accept_filter.sysml` — an `accept` fires because the incoming
  buffer is non-empty, but the payload doesn't match the declared item type, so the accepted value is
  the empty sequence.
- **Parallel/forked accept nondeterminism**: `send_fork_accept.sysml` — only one of several forked
  accepters actually consumes a given message; contrast noted with PSSM's differing semantics.
- **Binding vs. flow between sibling actions**: `bind_out_to_in.sysml` vs. `flow_out_to_in.sysml` —
  two ways to move a value from one action's output to another's input, and what that implies about
  where the value "lives" between a non-immediate succession.
- **Composite ownership across a transfer**: `payload_ownership.sysml` — what happens to a composite
  (`item`) feature's value when it's transferred out via a port; the danger of a stale duplicate being
  left behind at the source if it isn't manually cleared, and use of `Occurrence::superoccurrence`
  (not `this.that`) to reach an owning composite context.
