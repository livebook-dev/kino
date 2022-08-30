import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export async function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono&display=swap"
  );

  const app = Vue.createApp({
    template: `
    <div class="app">
      <div class="headline">
        <span class="dbg">dbg:{{ dbgLine }}</span>
        <span>{{ dbgInfo }}</span>
      </div>
      <div class="source">{{source}}</div>
    </div>
    `,

    data() {
      return {
        dbgLine: payload.dbg_line,
        dbgSameFile: payload.dbg_same_file,
        callCount: payload.call_count,
        source: payload.source,
      };
    },

    computed: {
      dbgInfo() {
        const info = [
          !this.dbgSameFile && "from another cell",
          this.callCount > 1 && `showing first out of ${this.callCount} calls`,
        ]
          .filter((x) => x)
          .join("; ");

        if (info) {
          return `(${info})`;
        } else {
          return null;
        }
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("call_count_updated", ({ call_count }) => {
    app.callCount = call_count;
  });
}
