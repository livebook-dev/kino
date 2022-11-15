import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

// TODO: use Macro.classify_atom/1 after switching to Elixir 1.14

const SIMPLE_ATOM = /^[a-zA-Z0-9_]+$/;
const MODULE_NAME = /^Elixir\.[a-zA-Z0-9_]+$/;

function atomToString(atom) {
  if (MODULE_NAME.test(atom)) {
    return atom.slice(7);
  } else if (atom === "nil" || atom === "true" || atom === "false") {
    return atom;
  } else if (SIMPLE_ATOM.test(atom)) {
    return `:${atom}`;
  } else {
    return `:"${atom.replaceAll('"', '\\"')}"`;
  }
}

export function init(ctx, tree) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap");
  ctx.importCSS("https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css");

  const app = Vue.createApp({
    template: `
      <div class="app">
        <!-- add controls here -->
        <div class="tree">
          <TreeNode :node="tree" :level="1" :lastChild="true" />
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
        props: ["node", "level", "lastChild"],
        data() {
          return {
            collapsed: this.level !== 1,
          };
        },
        methods: {
          value({ type, value }) {
            switch (type) {
              case "string":
                return `"${value}"`;
              case "atom":
                return atomToString(value);
              case "integer":
                return value;
              case "float":
                return value;
              case "compoundkey":
                return value;
              default:
                return "";
            }
          },
          containerPrefix() {
            switch (this.node.type) {
              case "list":
                return "[";
              case "tuple":
                return `{`;
              case "struct":
                return `%${atomToString(this.node.value)}{`;
              case "map":
                return "%{";
              default:
                return "";
            }
          },
          containerSuffix() {
            switch (this.node.type) {
              case "list":
                return "]";
              case "tuple":
                return `}`;
              case "struct":
                return `}`;
              case "map":
                return "}";
              default:
                return "";
            }
          },
          keyText() {
            return this.node.key.type === "atom"
              ? `${this.node.key.value}: `
              : `${this.value(this.node.key)} => `;
          },
          itemText() {
            // Subset of "key" => [...],
            let text = "";

            if (this.node.key != null) {
              text = this.keyText();
            }

            if (this.node.children != null) {
              text += this.containerPrefix();
              if (this.collapsed) {
                text += "...";
                text += this.containerSuffix();
                if (!this.lastChild) {
                  text += ",";
                }
              }
            } else {
              text += this.value(this.node);
              if (!this.lastChild) {
                text += ",";
              }
            }

            return text;
          },
          suffix() {
            // Subset of ],
            let text = "";
            if (this.node.children != null) {
              if (!this.collapsed) {
                text += this.containerSuffix();

                if (!this.lastChild) {
                  text += ",";
                }
              }
            }

            return text;
          },
        },
        template: `
          <div class="item" @click="collapsed = !collapsed" :class="{clickable: node.children != null}">
          <i class="ri ri-empty" v-if="node.children == null"></i><i class="ri ri-arrow-right-s-fill" v-if="node.children != null && collapsed"></i><i class="ri ri-arrow-down-s-fill" v-if="node.children != null && !collapsed"></i>{{ itemText() }}
          </div>
          <ol v-if="node.children != null" :class="{show: !collapsed}">
            <li v-for="(child, index) in node.children">
              <TreeNode :node="child" :level="level + 1" :lastChild="index === node.children.length - 1"/>
            </li>
          </ol>
          <div class="suffix">{{ suffix() }}</div>
        `,
      },
    },
  }).mount(ctx.root);
}
