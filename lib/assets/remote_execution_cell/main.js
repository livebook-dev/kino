import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );
  ctx.importCSS("main.css");

  const BaseInput = {
    name: "BaseInput",

    props: {
      label: {
        type: String,
        default: "",
      },
      inputClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: [String, Number],
        default: "",
      },
      inline: {
        type: Boolean,
        default: false,
      },
      required: {
        type: Boolean,
        default: false,
      },
    },

    template: `
    <div v-bind:class="[inline ? 'inline-field' : 'field']">
      <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
        {{ label }}
      </label>
      <input
        :value="modelValue"
        @input="$emit('update:data', $event.target.value)"
        v-bind="$attrs"
        :class="[inputClass, { required: !modelValue && required }]"
      >
    </div>
    `,
  };

  const app = Vue.createApp({
    components: {
      BaseInput: BaseInput,
    },

    template: `
    <div class="app">
      <form @change="handleFieldChange">
        <div class="header">
          <BaseInput
            name="node"
            label="Node"
            v-model="fields.node"
            inputClass="input input--md"
            :inline
            :required
          />
          <BaseInput
            name="cookie"
            label="Cookie"
            v-model="fields.cookie"
            inputClass="input"
            :inline
            :required
          />
          <BaseInput
            name="assign_to"
            label="Assign to"
            v-model="fields.assign_to"
            inputClass="input input--xs"
            :inline
          />
        </div>
      </form>
    </div>
    `,

    data() {
      return {
        fields: payload.fields,
      };
    },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;
        ctx.pushEvent("update_field", { field: name, value });
      },
    },
  }).mount(ctx.root);

  ctx.handleEvent("update_field", ({ fields }) => {
    setFields(fields);
  });

  function setFields(fields) {
    for (const field in fields) {
      app.fields[field] = fields[field];
    }
  }
}
