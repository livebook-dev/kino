import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

  const app = Vue.createApp({
    template: `
      <div class="app">
        <!-- Info Messages -->
        <div id="info-box" class="info-box" v-if="missingDep">
          <p>To successfully build charts, you need to add the following dependency:</p>
          <span>{{ missingDep }}</span>
        </div>
        <div id="data-info-box" class="info-box" v-if="noDataVariable">
          <p>To successfully plot graphs, you need at least one dataset available.</p>
          <p>The dataset needs to be a map of series, for example:</p>
          <span>my_data = %{a: [89, 124, 09, 67, 45], b: [12, 45, 67, 83, 32]}</span>
          <p>Or using Explorer:</p>
          <span>iris = Explorer.Datasets.iris() |> Explorer.DataFrame.to_map()</span>
        </div>

        <!-- Chart Form -->
        <form @change="handleFieldChange">
        <div class="container">
          <div class="root">
            <BaseInput
              name="chart_title"
              label="Charting"
              type="text"
              placeholder="Title"
              v-model="fields.chart_title"
              class="input--md"
              :disabled="noDataVariable"
            />
            <BaseInput
              name="width"
              label="Width"
              type="number"
              v-model="fields.width"
              class="input--xs"
              :disabled="noDataVariable"
            />
            <BaseInput
              name="height"
              label="Height"
              type="number"
              v-model="fields.height"
              class="input--xs"
              :disabled="noDataVariable"
            />
          </div>
          <div class="row">
            <BaseSelect
              name="data_variable"
              label="Data"
              v-model="fields.data_variable"
              :options="dataVariables"
              :required
              :disabled="noDataVariable"
            />
            <BaseSelect
              name="chart_type"
              label="Chart"
              v-model="fields.chart_type"
              :options="chartOptions"
              :required
              :disabled="noDataVariable"
            />
            <div class="field"></div>
          </div>
          <div class="row">
            <BaseSelect
              name="x_field"
              label="x-axis"
              v-model="fields.x_field"
              :options="axisOptions"
              :required
              :disabled="noDataVariable"
            />
            <BaseSelect
              name="x_field_type"
              label="Type"
              v-model="fields.x_field_type"
              :options="typeOptions"
              :disabled="noXField"
            />
            <BaseSelect
              name="x_field_aggregate"
              label="Aggregate"
              v-model="fields.x_field_aggregate"
              :options="aggregateOptions"
              :disabled="noXField"
            />
          </div>
          <div class="row">
            <BaseSelect
              name="y_field"
              label="y-axis"
              v-model="fields.y_field"
              :options="axisOptions"
              :required
              :disabled="noDataVariable"
            />
            <BaseSelect
              name="y_field_type"
              label="Type"
              v-model="fields.y_field_type"
              :options="typeOptions"
              :disabled="noYField"
            />
            <BaseSelect
              name="y_field_aggregate"
              label="Aggregate"
              v-model="fields.y_field_aggregate"
              :options="aggregateOptions"
              :disabled="noYField"
            />
          </div>
          <div class="row">
            <BaseSelect
              name="color_field"
              label="Color"
              v-model="fields.color_field"
              :options="axisOptions"
              :disabled="noDataVariable"
            />
            <BaseSelect
              name="color_field_type"
              label="Type"
              v-model="fields.color_field_type"
              :options="typeOptions"
              :disabled="noColorField"
            />
            <BaseSelect
              name="color_field_aggregate"
              label="Aggregate"
              v-model="fields.color_field_aggregate"
              :options="aggregateOptions"
              :disabled="noColorField"
            />
          </div>
        </div>
        </form>
      </div>
    `,

    data() {
      return {
        fields: payload.fields,
        dataOptions: payload.data_options,
        missingDep: payload.missing_dep,
        chartOptions: ["bar", "line", "point", "area"],
        typeOptions: ["quantitative", "nominal", "ordinal"],
        aggregateOptions: ["sum", "mean"],
        dataVariables: payload.data_options.map(data => data["variable"]),
      };
    },

    computed: {
      axisOptions() {
        const dataVariable = this.fields.data_variable;
        const dataOptions = this.dataOptions.find(data => data["variable"] === dataVariable);
        return dataOptions ? dataOptions["columns"].concat("__count__") : [];
      },
      noDataVariable() {
        return !this.fields.data_variable;
      },
      noColorField() {
        return !this.fields.color_field || this.fields.color_field === "__count__";
      },
      noYField() {
        return !this.fields.y_field || this.fields.y_field === "__count__";
      },
      noXField() {
        return !this.fields.x_field || this.fields.x_field === "__count__";
      },
    },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;
        ctx.pushEvent("update_field", { field: name, value });
      },
    },

    components: {
      BaseInput: {
        props: {
          label: {
            type: String,
            default: ''
          },
          modelValue: {
            type: [String, Number],
            default: ''
          },
        },
        template: `
          <div class="root-field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `
      },
      BaseSelect: {
        props: {
          label: {
            type: String,
            default: ''
          },
          modelValue: {
            type: [String, Number],
            default: ''
          },
          options: {
            type: Array,
            default: [],
            required: true
          },
          required: {
            type: Boolean,
            default: false
          },
        },
        methods: {
          available(value, options) {
            return value ? options.includes(value) : true;
          },
          optionLabel(value) {
            return value === "__count__" ? "COUNT(*)" : value;
          },
        },
        template: `
          <div class="field">
            <label class="input-label">{{ label }}</label>
            <select
              :value="modelValue"
              v-bind="$attrs"
              @change="$emit('update:modelValue', $event.target.value)"
              class="input"
              :class="{ unavailable: !available(modelValue, options) }"
            >
              <option v-if="!required && available(modelValue, options)"></option>
              <option
                v-for="option in options"
                :value="option"
                :key="option"
                :selected="option === modelValue"
              >{{ optionLabel(option) }}</option>
              <option
                v-if="!available(modelValue, options)"
                class="unavailable-option"
                :value="modelValue"
              >{{ optionLabel(modelValue) }}</option>
            </select>
          </div>
        `
      },
    }
  }).mount(ctx.root);

  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    app.missingDep = dep;
  });

  ctx.handleEvent("set_available_data", ({ data_options, fields }) => {
    app.dataVariables = data_options.map(data => data["variable"]);
    app.dataOptions = data_options;
    setValues(fields);
  });

  function setValues(fields) {
    for (const field in fields) {
      app.fields[field] = fields[field];
    }
  }
}
