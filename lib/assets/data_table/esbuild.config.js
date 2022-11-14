const res = require("esbuild").buildSync({
  entryPoints: ["app.js"],
  bundle: true,
  minify: true,
  format: "esm",
  sourcemap: true,
  outfile: "main.js",
  loader: { ".js": "jsx" },
  // external: ['react', 'react-dom'],
});
