# stack-safe-recursion — OCaml

```sh
ocamlopt main.ml -o main && ./main 40000000 1
```

Native (`ocamlopt`); the bytecode toplevel (`ocaml main.ml`) is far too slow at this depth.
