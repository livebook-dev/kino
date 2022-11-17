import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, tree) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap");
  ctx.importCSS("https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css");

  const app = Vue.createApp({
    template: `
      <div class="app">
        <div class="tree">
          <TreeNode :node="tree" :level="1" />
        </div>
      </div>
    `,
    data() {
      return { tree };
    },
    methods: {},
    components: {
      TreeNode: {
        // Need an explicit name for recursive components.
        name: "TreeNode",
        props: ["node", "level"],
        data() {
          return { expanded: this.level === 1 };
        },
        methods: {
          style(span) {
            return span.color == null ? {} : {color: span.color};
          },
          nbsp(text) {
            return text.replaceAll(' ', '\xa0');
          },
        },
        template: `
          <div class="item" @click="expanded = !expanded" :class="{clickable: node.children != null}">
            <div class="icon-container">
              <i class="ri ri-arrow-right-s-fill" v-if="node.children != null && !expanded"></i>
              <i class="ri ri-arrow-down-s-fill" v-if="node.children != null && expanded"></i>
            </div>
            <span v-if="node.children == null || !expanded" v-for="span in node.content" :style="style(span)">{{ nbsp(span.text) }}</span>
            <span v-if="node.children != null && expanded" v-for="span in node.expanded.prefix" :style="style(span)">{{ nbsp(span.text) }}</span>
          </div>
          <ol v-if="node.children != null" :class="{show: expanded}">
            <li v-for="(child, index) in node.children">
              <TreeNode :node="child" :level="level + 1" />
            </li>
          </ol>
          <div class="suffix" v-if="node.children != null && expanded">
            <span v-for="span in node.expanded.suffix" :style="style(span)">{{ nbsp(span.text) }}</span>
          </div>
        `,
      },
    },
  }).mount(ctx.root);
}
