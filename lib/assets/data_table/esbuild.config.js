require("esbuild").build({
  entryPoints: ["main.js"],
  bundle: true,
  minify: true,
  format: "esm",
  sourcemap: false,
  outfile: "build/main.js",
  loader: { ".js": "jsx" },
  watch: {
    onRebuild(error, result) {
      if (error) console.error('watch build failed:', error)
      else console.log('watch build succeeded:', result)
    },
  },
}).then(result => {
  console.log('watching...')
})
