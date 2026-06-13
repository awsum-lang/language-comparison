# stack-safe-recursion — Awsum

Each target: build with `awsum build`, then invoke the resulting artefact directly. Identical stdout on all five.

## LLVM (native)

```sh
awsum build --program-type cli -t llvm -o out.ll          Main.aww && clang out.ll -o program && ./program 5000000 1
```

## JVM

```sh
awsum build --program-type cli -t jvm  -o AwsumMain.class Main.aww && java -Dsun.jnu.encoding=UTF-8 -Dfile.encoding=UTF-8 AwsumMain 5000000 1
```

## CLR (.NET)

The build emits `AwsumMain.runtimeconfig.json` alongside the dll; `dotnet` reads it automatically, so keep the two together and no extra flags are needed.

```sh
awsum build --program-type cli -t clr  -o AwsumMain.dll   Main.aww && dotnet AwsumMain.dll 5000000 1
```

## WASM

```sh
awsum build --program-type cli -t wasm -o out.wasm        Main.aww && wasmtime out.wasm 5000000 1
```

## JS (Node)

```sh
awsum build --program-type cli -t js   -o out.js          Main.aww && node out.js 5000000 1
```
