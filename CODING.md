# Personal Coding Standards

These are personal defaults. Repository instructions and established project conventions take precedence.

Only add a rule after encountering concrete, recurring friction.

## General

The best code is the least code that a human would write and can read in one pass. Every rule below is a specific case of that.

### Design

- Build only what the current request needs (YAGNI). No "while we're here" features, config flags nobody asked for, or hooks for a future that may never arrive.
- Prefer direct, concrete code over speculative abstractions. Three similar lines beat one premature abstraction.
- Do not add single-use wrappers, factories, managers, providers, or interfaces without a current benefit. A wrapper with one caller is the caller.
- Prefer deletion when it fully solves the problem while preserving clear behavior. Before adding, remove the dead weight in the same area first, then build on the smaller base.
- Minimize what the reader has to hold in their head. Count the layers, indirections, and pieces of mutable state between the entry point and the effect, and collapse the ones that do not earn their place. Keep mutable scope small.
- When logic branches a lot or the same shape assumption repeats across files, encode the domain in a structure (a typed model, a lookup table, a state machine, the right collection) instead of scattered conditionals.
- Integrate a new requirement as if it had been there from day one. Do not bolt it on beside the old design, and do not keep a temporary compatibility layer that nobody will remove.
- When you replace an internal API, migrate all callers and delete the old one in the same change.
- Write code a human would write. If a reviewer would ask "why is this so complicated", it is.

### Errors and fallbacks

- Do not add hidden fallbacks or silently swallow meaningful errors.
- Fix the root cause. Reproduce the failure first, then trace the symptom back until the fix removes the cause rather than the message.
- Guard at system boundaries (user input, network, files, other processes). Inside, trust your own types and keep the core logic free of defensive checks.
- Prefer operations that can run twice and end in the same state. Retries and crashes happen.

### Dependencies

- Do not add dependencies when the standard library, platform, or an installed dependency adequately solves the problem.

### Verification

- Prove the change works against the real artifact (run it, hit the endpoint, open the UI). "It compiles" and "the tests I wrote pass" are not proof on their own.
- Split multi-step work into units that each end in a check, and verify each before starting the next.

## TypeScript

### Types and boundaries

- Validate data at external or untyped boundaries. Avoid redundant runtime checks for trusted internal values whose ownership and types already establish validity.
- Do not use generic guards like `isRecord`, `isObject`, or `typeof x === "object" && x !== null` on values whose shape is already known. Type the source instead. One schema or guard at the boundary, then plain property access.

```ts
// Prefer
const user = userSchema.parse(json);
return user.name;

// Avoid
if (isRecord(data) && typeof data.name === "string") return data.name;
```

- Do not re-check types the compiler already guarantees. No `typeof id === "string"` on a `string` parameter, no `Array.isArray(items) ? items : []` on an `Item[]`, no `if (!user) throw` on a non-nullable `User`.
- Do not use `Record<string, unknown>`, `Record<string, any>`, or `object` for a shape you know. Declare the type.
- Do not use `as unknown as T` or `JSON.parse(x) as T` to skip validation. Parse with a schema or narrow with a guard whose result you use.
- Do not use optional chaining or `??` defaults on values that cannot be null. `user?.name ?? ""` on a required `user` hides the bug it is supposedly guarding against and lies about the type.
- Do not use truthiness checks where `0`, `""`, or `false` are valid values. Compare explicitly (`=== undefined`, `.length === 0`).
- Do not make every field optional or wrap the type in `Partial<T>` to avoid supplying data. Required means required.
- Prefer inferred types where inference is obvious. Do not annotate every `const`, arrow callback, or trivially inferable return type.
- Do not create one-off type aliases or interfaces for an inline object literal that appears once.
- Do not prefix interfaces with `I`.

### Functions and abstractions

- Do not add generic type parameters when the function is called with one concrete type. `<T extends Record<string, unknown>>` on a function that only ever receives `User` is noise.
- Do not create `utils.ts`, `helpers.ts`, or `*Helper`, `*Util`, `*Manager`, `*Service` modules for one-off functions. Put the function next to its only caller.
- Do not create barrel `index.ts` files that only re-export.
- Do not wrap a single `fetch` call in an `ApiClient` class, a single function in a class with one method, or a plain value in a getter.
- Do not extract a function that is called once unless it names a concept the caller needs. A well-named local block is fine.
- Do not add `options` objects with a single field, or configuration flags nobody passes.
- Do not write `return await x` inside an `async` function unless it sits in a `try` block.
- Name things after what they hold or do. Avoid `data`, `result`, `item`, `temp`, `value`, `handleX`, `processY`, `doZ` when a specific name exists.

### Error handling

- Do not wrap every function body in `try/catch`. Catch where you can do something useful (add context, translate, recover) and let everything else propagate.
- Do not catch and rethrow `new Error("Failed to X: " + err)`. That drops the stack and the original type. Use `throw new Error("Failed to X", { cause: err })` or do not catch.
- Do not repeat the `err instanceof Error ? err.message : String(err)` boilerplate in every catch. If it is needed more than twice, one shared function; otherwise rethrow.
- Do not `console.error` inside a catch and then continue as if nothing happened. Either handle it or throw.
- Do not type the catch variable as `any`. Use `unknown` (the default) and narrow.
- Do not invent `Result<T, E>` or `Either` types, or a custom error class hierarchy, for a single call site. Throw.
- Do not return `null`, `undefined`, `""`, or `[]` to signal failure when the caller cannot distinguish that from a real empty value.

### Dependencies

- Do not add `lodash`, `uuid`, `axios`, `dotenv`, `chalk`, or similar when `Array.prototype`, `structuredClone`, `crypto.randomUUID()`, `fetch`, `process.loadEnvFile` / `--env-file`, or `util.styleText` already do the job on the pinned runtime.

### Testing

- Test behaviour through the public interface. Do not assert on private state, call order of internal helpers, or exact log messages.
- Do not mock modules the test can run for real (pure functions, in-memory data, local filesystem under a temp dir). Mock the network and clocks.
- Do not write tests whose only assertion is `toBeDefined()`, `not.toThrow()`, or `expect(true).toBe(true)`. Assert the actual value.
- Do not write one test per line of implementation. Cover the contract and the edge that motivated the change.
- Do not use `setTimeout` or `sleep` to wait in tests. Await the promise or use fake timers.

### Style and syntax

- Do not write comments that restate the code (`// increment counter`, `// return the user`), section banners (`// ===== Helpers =====`), or JSDoc that repeats the signature (`@param id The id`). Comment intent, constraints, and surprises only.
- Do not leave `// TODO` or `// FIXME` for work you are doing now. Do it or leave it out.
- Do not add `// eslint-disable-next-line` or `@ts-ignore` / `@ts-expect-error` to silence a real problem. Fix the type or the code. If a suppression is unavoidable, use `@ts-expect-error` with a reason.
- Do not mix `null` and `undefined` for the same meaning in one module. Pick one (default `undefined`) and keep it.
- Do not use `!!x`, `Boolean(x)`, and `x ? true : false` interchangeably in one file. Pick one.
- Do not use non-null assertions (`!`) to silence a type you have not actually proven. Narrow, or fix the type upstream.
- Do not use `enum`. Use a union of string literals or an `as const` object.
- Do not use emojis in log output, error messages, or CLI output.
- Do not add trailing "summary" blocks, headers, or file-level doc comments describing what a module does when the file name and exports already say it.

