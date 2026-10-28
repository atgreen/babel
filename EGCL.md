# EGCL compatibility

This fork preserves the portable upstream implementation from `git:https://github.com/cl-babel/babel.git`.
Its existing ANSI Common Lisp path works for the behavior exercised by
`egcl-smoke.lisp`; no implementation identity spoofing or replacement stubs
are used. Source provenance follows ocicl/babel/README.org.

With dependencies available to ASDF, run from this repository's root:

```sh
egcl --no-init --load egcl-smoke.lisp
```

Put this directory first in ASDF's source registry to select this fork.
The committed smoke test contains semantic assertions and prints
`EGCL babel smoke passed.` after all assertions succeed.
Validated on EGCL 0.0.10 (b94618ece), with a 2 GiB process memory cap.
Focused public API smoke coverage only; full upstream suite not run.
Tracking: `bliss-yhct8.1`.

`egcl --no-init --load egcl-streams-smoke.lisp` also validates babel-streams:
writing ASCII and Greek characters through an in-memory Gray stream produces
the expected UTF-8 octets. Use the EGCL trivial-gray-streams fork for this system.

`egcl-array-bindings-smoke.lisp` checks EGCL's inline `WITH-SIMPLE-VECTOR`
bindings, including displacement chains, nonzero bounds, fill pointers,
adjustable-input copying, mutation aliases, declarations, evaluation order,
and zero/multiple values. The adjustable branch retains the portable helper's
copy-only behavior: changes to its temporary are not copied back. Other Lisp
implementations retain their existing expansion. This check also runs on SBCL
for the common semantics, with its documented direct-storage mutation behavior.
