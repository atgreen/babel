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
Focused public API smoke coverage only; full upstream suite not run. babel-streams not validated by this smoke test.
Tracking: `bliss-yhct8.1`.
