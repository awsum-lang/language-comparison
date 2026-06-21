// FFI: read treeDepth and mirrorCount from the program's CLI args. They are the
// last two entries of process.argv regardless of how `spago run` prefixes the
// node invocation, so slice from the end rather than hard-coding indices.
export const treeDepthImpl = () => parseInt(process.argv[process.argv.length - 2], 10);
export const mirrorCountImpl = () => parseInt(process.argv[process.argv.length - 1], 10);
