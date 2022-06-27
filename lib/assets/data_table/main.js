import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, data) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap");
  ctx.importCSS("https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.min.css");

  const app = Vue.createApp({
    template: `
      <div class="app">
        <div class="navigation">
          <div class="navigation__info">
            <h2 class="navigation__name">
              {{ data.name }}
            </h2>
            <span class="navigation__details">
              {{ data.content.total_rows || "?" }} entries
            </span>
          </div>
          <div class="navigation__space"></div>
          <!-- Actions -->
          <button
            v-if="data.features.includes('refetch')"
            class="icon-button"
            aria-label="refresh"
            @click="refetch()"
          >
            <remix-icon icon="refresh-line"></remix-icon>
          </button>
          <!-- Pagination -->
          <div
            v-if="data.features.includes('pagination') && (data.content.total_rows === null || data.content.total_rows > 0)"
            class="pagination"
            aria-label="table pagination"
            aria-controls="table-info"
          >
            <button
              class="pagination__button"
              @click="prev()"
              :disabled="data.content.page === 1"
            >
              <remix-icon icon="arrow-left-s-line"></remix-icon>
              <span>Prev</span>
            </button>
            <div class="pagination__info">
              <span>{{ data.content.page }} of {{ data.content.max_page || "?" }}</span>
            </div>
            <button
              class="pagination__button"
              @click="next()"
              :disabled="data.content.max_page && data.content.page >= data.content.max_page"
            >
              <span>Next</span>
              <remix-icon icon="arrow-right-s-line"></remix-icon>
            </button>
          </div>
        </div>

        <!-- In case we don't have information about table structure yet -->
        <p v-if="data.content.columns.length === 0" class="no-data">
          No data
        </p>

        <!-- Data table -->
        <div
          v-else
          class="table-container tiny-scrollbar"
          :class="{ 'table-container--loading': loading }"
        >
          <table class="table" :aria-label="data.content.order_by ? orderDescription() : '' ">
            <thead class="table__head">
              <tr class="table__row">
                <th v-for="column in data.content.columns"
                  :key="column.key"
                  class="table__cell"
                  :class="{ 'table__cell--clickable': data.features.includes('sorting') }"
                  @click="data.features.includes('sorting') && orderBy(column.key)"
                  aria-controls="table-info"
                >
                  <div class="table__cell-content">
                    <div class="table__cell-content-primary">
                      <span>{{ column.label }}</span>
                      <span :class="{invisible: data.content.order_by !== column.key}">
                        <remix-icon :icon="data.content.order === 'asc' ? 'arrow-up-s-line' : 'arrow-down-s-line'"></remix-icon>
                      </span>
                    </div>
                    <div v-if="column.type" class="table__cell-content-secondary">
                      {{ column.type }}
                    </div>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody class="table__body">
              <tr v-for="row in data.content.rows" class="table__row table__row--hover table__row--no-trailing-border">
                <td v-for="column in data.content.columns" :key="column.key" class="table__cell">
                  {{ row.fields[column.key] }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div class="sr-only" role="region" id="table-info" aria-live="polite">
        <span>{{ data.content.order_by ? orderDescription() : 'unordered'  }}</span>
        <span>you are on table page {{ data.content.page }}</span>
      </div>
    `,

    data() {
      return {
        data,
        loading: false,
      };
    },

    methods: {
      prev() {
        this.loading = true;
        ctx.pushEvent("show_page", { page: this.data.content.page - 1 });
      },

      next() {
        this.loading = true;
        ctx.pushEvent("show_page", { page: this.data.content.page + 1 });
      },

      refetch() {
        this.loading = true;
        ctx.pushEvent("refetch");
      },

      orderBy(newKey) {
        this.loading = true;
        const [key, order] = reorder(this.data.content.order_by, this.data.content.order, newKey)
        ctx.pushEvent("order_by", { key, order });
      },

      orderDescription() {
        const key = this.data.content.order_by;
        const { label } = this.data.content.columns.find((column) => column.key === key);
        const order = this.data.content.order === "asc" ? "ascending" : "descending";
        return `ordered by ${label}, ${order}`;
      },
    },

    components: {
      RemixIcon: {
        props: ["icon"],
        template: `
          <i :class="'ri ri-' + icon" aria-hidden="true"></i>
        `
      }
    }
  }).mount(ctx.root);

  ctx.handleEvent("update_content", (content) => {
    app.data.content = content;
    app.loading = false;
  });
}

function reorder(orderBy, order, key) {
  if (orderBy === key) {
    if (order === "asc") {
      return [key, "desc"];
    } else {
      return [null, "asc"];
    }
  } else {
    return [key, "asc"]
  }
}
