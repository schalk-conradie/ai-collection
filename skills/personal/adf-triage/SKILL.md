---
name: adf-triage
description: Triage Azure Data Factory pipeline and Copy activity issues using live run evidence, Jam SQL source and staging checks, and read-only Dataverse verification. Use when an ADF load fails, skips rows, reports success without the expected target data, or writes incorrect lookup values.
---

# ADF triage

Find the first wrong state in the real source-to-target path. Diagnose by default. Do not edit, rerun, publish, or change external data unless the user asks.

## Start with the reported item

Identify the factory, pipeline, run, affected activity, source business key, and expected Dataverse record. Use IDs, URLs, screenshots, and timestamps supplied by the user. Do not treat a screenshot as proof of values outside the visible columns.

Fetch current Microsoft documentation when connector or ADF behavior affects the diagnosis. Use official Microsoft sources only.

## Trace the live path

1. Inspect the latest relevant ADF run.
   - Record the pipeline and activity run IDs, times, terminal status, source, sink, and integration runtime.
   - Read the activity input and output. Capture `rowsRead`, `rowsCopied`, `rowsSkipped`, errors, and any session-log path.
   - A `Succeeded` Copy activity is not proof of a complete load. If `rowsSkipped` is nonzero, treat the skipped rows as unresolved failures.
   - Distinguish Debug runs, which may use local pipeline configuration, from triggered runs using published configuration.

2. Inspect the pipeline definition used by that run.
   - Read the exact source query, mappings, sink write behavior, alternate key, null handling, fault tolerance, session logging, and activity dependencies.
   - Check whether lookup staging finishes before the dependent sink activity starts.
   - Compare with SSIS only when migration parity is relevant. A disabled SSIS path is not automatically missing ADF coverage.

3. Query source and staging data with Jam SQL.
   - Read and follow the available `jam-sql` skill. Use the `jam-sql` CLI only.
   - Run `jam-sql status` and `jam-sql connections` before querying. Launch or repair pairing when needed.
   - Ask before connecting an inactive saved connection. Keep the connection read-only for triage.
   - Query the reported rows first. Select every mapped key and lookup value, not only the visible symptom column.
   - Reproduce the ADF source query for those rows and show raw, staged, and resolved values side by side.
   - Then count or classify all relevant rows to determine whether the issue is isolated or systemic.
   - If query execution is blocked, open the query in Jam SQL for the user and explain which permission setting blocks execution.

4. Verify the target directly.
   - Prefer the read-only `dynamics-webapi` skill over browser inspection when a Dataverse URL is available.
   - Confirm the expected target record, alternate-key row, and every mapped lookup GUID.
   - For a missing lookup, test both the GUID selected by ADF and the current GUID from staging.
   - An absent target row plus a nonzero skipped-row count is stronger evidence than an ADF success badge.

## Lookup checks

Treat non-null values as potentially stale. For enrichment such as:

```sql
COALESCE(source.LookupId, staging.LookupId)
```

verify that the chosen source GUID still exists in the current Dataverse environment. A stale non-null GUID prevents the valid staged GUID from being selected. If staging is refreshed from the target before the load, test whether staging-first resolution is the correct rule:

```sql
COALESCE(staging.LookupId, source.LookupId)
```

Do not recommend reversing precedence until the affected GUIDs and the activity dependency order have both been verified.

## Report the diagnosis

Lead with the outcome. Separate:

- observed evidence from ADF, SQL, and Dataverse;
- the first wrong value or decision;
- the smallest proposed correction;
- checks not run and actions not taken.

Include run IDs and row counts. If skip-incompatible-row is enabled without session logging, call out the hidden failure mode and recommend warning-level session logging. Keep fault tolerance if the integration needs SSIS-style continuation, but require skipped-row evidence before calling a run successful.
