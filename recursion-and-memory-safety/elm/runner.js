// Node CLI runner for the compiled Elm worker. Subscribes to the `stdout`
// port and prints whatever the program emits, then exits.

const { Elm } = require('./build/main.js');

const app = Elm.Main.init();
app.ports.stdout.subscribe((s) => {
  console.log(s);
  process.exit(0);
});
