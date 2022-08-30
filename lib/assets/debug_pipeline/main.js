export async function init(ctx, payload) {
  await importJS(
    "https://cdn.jsdelivr.net/npm/vue@3.2.37/dist/vue.global.prod.js"
  );
  await importJS(
    "https://cdn.jsdelivr.net/npm/vue-dndrop@1.2.13/dist/vue-dndrop.min.js"
  );

  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono&display=swap"
  );
  ctx.importCSS(
    "https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css"
  );

  const BaseSwitch = {
    name: "BaseSwitch",

    template: `
    <label class="switch-button">
      <input type="checkbox" v-bind="$attrs" class="switch-button__checkbox" />
      <div class="switch-button__bg" />
    </label>
    `,
  };

  const app = Vue.createApp({
    components: {
      BaseSwitch,
      Container: VueDndrop.Container,
      Draggable: VueDndrop.Draggable,
    },

    template: `
    <div class="app">
      <div class="navigation">
        <div class="headline">
          <span class="dbg">dbg:{{ dbgLine }}</span>
          <span>{{ dbgInfo }}</span>
        </div>
        <div class="actions">
          <div class="copy-source" @click="copySource">
            <span class="change-indicator" v-if="isChanged">
              <span class="dot"></span>
              <span>Copy new pipeline</span>
            </span>
            <button class="icon-button">
              <i class="ri ri-clipboard-line" aria-hidden="true"></i>
            </button>
          </div>
        </div>
      </div>
      <Container @drop="handleItemDrop">
        <Draggable
          v-for="(item, index) in items"
          :key="item.id"
          :drag-not-allowed="index === 0"
        >
          <div
            class="box"
            :class="{
              selectable: isItemSelectable(item),
              selected: item.id === selectedId,
              errored: item.id === erroredId,
              first: index === 0,
            }"
            @click="handleItemClick(item)"
          >
            <div class="primary">
              <span class="source">{{ item.source }}</span>
              <BaseSwitch
                :checked="item.enabled"
                @change="handleEnabledChange(item, $event)"
                @click.stop
                v-if="item !== items[0]"
              />
            </div>
            <div class="error" v-if="item.id === erroredId">
              {{error}}
            </div>
          </div>
        </Draggable>
      </Container>
      <div class="output-label">
        Output:
      </div>
    </div>
    `,

    data() {
      return {
        dbgSameFile: payload.dbg_same_file,
        dbgLine: payload.dbg_line,
        callCount: payload.call_count,
        items: payload.items,
        selectedId: payload.selected_id,
        erroredId: payload.errored_id,
        error: payload.error,
        isChanged: payload.changed,
      };
    },

    computed: {
      abortedIds() {
        if (this.erroredId === null) {
          return [];
        } else {
          const erroredIdx = this.items.findIndex(
            (item) => item.id === this.erroredId
          );
          return this.items.slice(erroredIdx).map((item) => item.id);
        }
      },

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

    methods: {
      isItemSelectable(item) {
        return item.enabled && !this.abortedIds.includes(item.id);
      },

      handleItemClick(item) {
        if (this.isItemSelectable(item)) {
          ctx.pushEvent("select_item", { id: item.id });
        }
      },

      handleEnabledChange(item, event) {
        ctx.pushEvent("update_enabled", {
          id: item.id,
          enabled: event.target.checked,
        });
      },

      handleItemDrop({ removedIndex, addedIndex }) {
        addedIndex = Math.max(addedIndex, 1);
        if (removedIndex === addedIndex) return;
        const item = this.items[removedIndex];
        ctx.pushEvent("move_item", { id: item.id, index: addedIndex });
      },

      copySource() {
        const source = this.items
          .filter((item) => item.enabled)
          .map((item) => item.source)
          .join("\n");

        if ("clipboard" in navigator) {
          navigator.clipboard.writeText(source);
        } else {
          alert(
            "Sorry, your browser does not support clipboard copy.\nThis generally requires a secure origin — either HTTPS or localhost."
          );
        }
      },

      moveSelection(offset) {
        const items = this.items.filter((item) => this.isItemSelectable(item));
        const idx = items.findIndex((item) => item.id === this.selectedId);
        const item = items[idx + offset];

        if (item) {
          ctx.pushEvent("select_item", { id: item.id });
        }
      },
    },

    created() {
      window.addEventListener("keydown", (event) => {
        if (event.key === "ArrowUp") {
          this.moveSelection(-1);
          event.preventDefault();
        } else if (event.key === "ArrowDown") {
          this.moveSelection(1);
          event.preventDefault();
        }
      });
    },
  }).mount(ctx.root);

  ctx.handleEvent("item_selected", ({ id }) => {
    app.selectedId = id;
  });

  ctx.handleEvent("set_errored", ({ id, error, selected_id }) => {
    app.erroredId = id;
    app.error = error;
    app.selectedId = selected_id;
  });

  ctx.handleEvent(
    "enabled_updated",
    ({ id, enabled, selected_id, changed }) => {
      const item = app.items.find((item) => item.id === id);
      item.enabled = enabled;
      app.selectedId = selected_id;
      app.isChanged = changed;
    }
  );

  ctx.handleEvent("item_moved", ({ id, index, changed }) => {
    const currentIndex = app.items.findIndex((item) => item.id === id);
    const item = app.items[currentIndex];
    app.items.splice(currentIndex, 1);
    app.items.splice(index, 0, item);
    app.isChanged = changed;
  });

  ctx.handleEvent("call_count_updated", ({ call_count }) => {
    app.callCount = call_count;
  });
}

// Imports a JS script globally using a <script> tag
function importJS(url) {
  return new Promise((resolve, reject) => {
    const scriptEl = document.createElement("script");
    scriptEl.addEventListener(
      "load",
      (event) => {
        resolve();
      },
      { once: true }
    );
    scriptEl.src = url;
    document.head.appendChild(scriptEl);
  });
}
