# Reporting

A good report is reproducible, distinguishes evidence from inference, and
contains no unnecessary target code or private data.

## Structure

1. **Executive summary** — what the binary is, what it does, confidence.
2. **Target identity** — path, hashes, signature, version, build date.
3. **Authorization and scope** — who authorized it, what was allowed.
4. **Environment** — host/VM, Windows build, tools, network mode.
5. **Static findings** — PE traits, imports, strings, resources, packing.
6. **Dynamic findings** — scenarios, side effects, network, errors.
7. **Behavior map** — entry points, inputs, outputs, state, formats.
8. **Security observations** — trust boundaries, secrets, update channel.
9. **Unknowns** — what could not be determined and why.
10. **Independent implementation plan** — architecture, compatibility tests.
11. **Evidence index** — paths, hashes, screenshots, logs.

## Confidence levels

- **Observed** — directly seen in static or dynamic evidence.
- **Inferred** — supported by multiple clues but not directly proven.
- **Unknown** — not determined; list the next experiment.

Never present an inference as an observation.

## Evidence rules

- Quote only short decompiled excerpts, with address and build hash.
- Prefer summaries and diagrams over copied code.
- Include command lines and tool versions.
- Hash every exported artifact.
- Redact secrets, tokens, personal data, and customer names.
- Keep screenshots cropped to the relevant UI.

## Independent reimplementation plan

Describe:

- required behavior and compatibility guarantees;
- inputs, outputs, and state;
- file formats and protocols;
- error handling and edge cases;
- test fixtures and golden outputs;
- architecture and module boundaries;
- what will deliberately differ.

Do not include copied source, assets, icons, logos, or branding.

## Quality checklist

- [ ] Hashes and provenance recorded.
- [ ] Authorization documented.
- [ ] Static and dynamic evidence separated.
- [ ] Findings labeled observed/inferred/unknown.
- [ ] Secrets redacted.
- [ ] Report reproducible from the evidence index.
- [ ] No target code or assets proposed for reuse.
