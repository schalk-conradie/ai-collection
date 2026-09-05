# Personal coding standards

These are personal defaults. Repository instructions and established conventions take precedence. Add a rule only after concrete, recurring friction.

## General

### Design

- Build only what the current request needs. Do not add speculative features, flags, hooks, or compatibility layers.
- Prefer direct code over premature abstractions. Do not add single-use wrappers, factories, managers, providers, interfaces, or helper modules without a current benefit.
- Minimize indirection and mutable state. Use a typed model, lookup table, state machine, or suitable collection when it replaces repeated shape assumptions or branching.
- When replacing an internal API, migrate its callers and remove the old path within the owned scope. Preserve compatibility when consumers cannot migrate together.
- Prefer deletion when it solves the problem and preserves clear behavior. Write code a human can understand in one pass.

### Errors and boundaries

- Reproduce failures when practical, trace the relevant path, and fix the root cause. State when a diagnosis remains unverified. Preserve meaningful errors.
- Guard external boundaries such as user input, network data, files, and processes. Trust established internal types.
- Do not add hidden fallbacks, swallow errors, or return an ordinary empty value to represent failure.
- Prefer operations that can safely run twice and end in the same state.

### Dependencies and verification

- Use the standard library, platform, and installed dependencies before adding another dependency.
- Match verification to the changed behavior and risk. Use the actual artifact or integration path when the claim depends on it, within the authorized environment and scope.
- Add a focused regression test for non-trivial behavior changes when it provides useful coverage. Skip new tests for low-impact edits whose result is directly inspectable, or tests that only mirror the implementation.
- Distinguish build, test, deployment, and runtime evidence. Report relevant checks that were not run and what remains unproven.

## TypeScript

### Types and boundaries

- Validate external or untyped data once with a schema or focused guard, then use the validated type directly.
- Do not re-check types the compiler already guarantees or add optional chaining and defaults to non-nullable values.
- Do not use `Record<string, unknown>`, `Record<string, any>`, or `object` when the shape is known.
- Do not use `as unknown as T` or `JSON.parse(x) as T` to skip validation.
- Compare explicitly when `0`, `""`, or `false` is valid.
- Prefer obvious inference. Name types when they clarify a domain concept or contract, and do not prefix interfaces with `I`.
- Keep required fields required. Use `Partial<T>` for a genuinely partial contract, not to avoid supplying required data.
- Use `undefined` by default for absence and do not mix it with `null` for the same meaning in one module. Preserve external contracts that distinguish them.
- Do not use non-null assertions to silence an unproven type. Narrow it or fix the type upstream.

### Functions and abstractions

- Add generic type parameters only when they preserve useful type relationships or satisfy a current contract. Caller count alone does not determine their value.
- Keep one-use functions next to their caller unless extraction clarifies a domain concept or boundary.
- Avoid `utils.ts`, `helpers.ts`, barrel `index.ts` files, or `*Helper`, `*Util`, `*Manager`, and `*Service` modules for one-off code unless they clarify a current contract or boundary, or follow an established project convention.
- Do not wrap one `fetch` call in a client class, one function in a class, or a plain value in a getter without a current benefit, such as handling a boundary or satisfying a framework contract.
- Use an options object when named fields make the call clearer, even for one field. Do not add flags nobody passes.
- Await returned promises when local error handling or resource cleanup depends on their completion. Elsewhere, follow the repository's `return await` convention.
- Use specific names. Avoid `data`, `result`, `item`, `temp`, `value`, `handleX`, `processY`, and `doZ` when the domain provides a name.

### Error handling

- Catch only when the code can add context, translate, or recover. Otherwise let the error propagate.
- Preserve the original error with `cause` when adding context.
- Do not log an error and then continue as if the operation succeeded.
- Keep catch variables as `unknown` and narrow them.
- Do not invent `Result`, `Either`, or a custom error hierarchy without a current benefit to the contract or error handling.
- Share error-formatting code when it removes meaningful duplication or gives a boundary a consistent error format.

### Platform features

- Do not add `lodash`, `uuid`, `axios`, `dotenv`, `chalk`, or similar packages when the pinned runtime adequately provides the required operation.

### Testing

- Test behavior through the public interface, not private state, internal call order, or exact log text.
- Run pure functions and local temporary files for real. Control network access and clocks in unit tests; exercise real boundaries in integration tests when those boundaries are the subject of the check.
- Assert actual values and contracts. Do not use placeholder assertions such as `toBeDefined()` or `not.toThrow()` as the only proof.
- Cover the contract and the edge that motivated the change. Await promises or use fake timers instead of sleeping.

### Syntax and comments

- Comment intent, constraints, and surprises. Do not restate code, repeat signatures, or add decorative section banners.
- Finish current work instead of leaving `TODO` or `FIXME` comments.
- Fix type and lint problems. If suppression is unavoidable, keep it narrow and explain why; use `@ts-expect-error` for TypeScript diagnostics rather than `@ts-ignore`.
- Do not use `enum`. Use string literal unions or an `as const` object.
- Do not use emojis in logs, errors, or CLI output.
- Pick one boolean-conversion style within a file.
- Do not add summary blocks or file comments that repeat the filename and exports.
