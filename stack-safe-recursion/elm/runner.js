// Node CLI runner for the compiled Elm worker. Reads treeDepth and mirrorCount
// from the last two CLI args, passes them to the worker as flags, prints
// whatever the program emits on the `stdout` port, then exits.

const { Elm } = require('./build/main.js');

const args = process.argv.slice(-2);
const app = Elm.Main.init({
  flags: { treeDepth: parseInt(args[0], 10), mirrorCount: parseInt(args[1], 10) },
});
app.ports.stdout.subscribe((s) => {
  console.log(s);
  process.exit(0);
});
