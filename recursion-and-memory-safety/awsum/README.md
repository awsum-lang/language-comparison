# recursion-and-memory-safety — Awsum

Each target: build with `awsum build`, then invoke the resulting artefact directly. Identical stdout on all five.

## LLVM (native)

```sh
awsum build --program-type cli -t llvm -o out.ll          Main.aww && clang out.ll -o program && ./program
```

## JVM

```sh
awsum build --program-type cli -t jvm  -o AwsumMain.class Main.aww && java -Dsun.jnu.encoding=UTF-8 -Dfile.encoding=UTF-8 AwsumMain
```

## CLR (.NET)

```sh
awsum build --program-type cli -t clr  -o AwsumMain.dll   Main.aww && dotnet AwsumMain.dll
```

## WASM

```sh
awsum build --program-type cli -t wasm -o out.wasm        Main.aww && wasmtime out.wasm
```

## JS (Node)

```sh
awsum build --program-type cli -t js   -o out.js          Main.aww && node out.js
```
