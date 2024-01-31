import "./main.css";

import * as Vue from "vue/dist/vue.esm-browser.prod.js";

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
        default: null,
      },
      inputClass: {
        type: String,
        default: "input",
      },
      modelValue: {
        type: [String, Number],
        default: "",
      },
      required: {
        type: Boolean,
        default: false,
      },
    },

    template: `
    <div class="field">
      <label v-if="label" class="input-label">
        {{ label }}
      </label>
      <input
        :value="modelValue"
        @input="$emit('update:modelValue', $event.target.value)"
        v-bind="$attrs"
        :class="[inputClass, { required: !(modelValue || $attrs.value) && required }]"
      >
    </div>
    `,
  };

  const InlineLabel = {
    name: "InlineLabel",

    props: {
      label: {
        type: String,
        default: null,
      },
    },

    template: `
    <label class="inline-label">
      {{ label }}
    </label>
    `,
  };

  const BaseSecret = {
    name: "BaseSecret",

    components: {
      BaseInput: BaseInput,
    },

    props: {
      textInputName: {
        type: String,
        default: "",
      },
      secretInputName: {
        type: String,
        default: "",
      },
      toggleInputName: {
        type: String,
        default: "",
      },
      label: {
        type: String,
        default: null,
      },
      toggleInputValue: {
        type: [String, Number],
        default: "",
      },
      secretInputValue: {
        type: [String, Number],
        default: "",
      },
      textInputValue: {
        type: [String, Number],
        default: "",
      },
      modalTitle: {
        type: String,
        default: "Select secret",
      },
      required: {
        type: Boolean,
        default: false,
      },
    },

    methods: {
      selectSecret() {
        const preselectName = this.secretInputValue || "";
        ctx.selectSecret(
          (secretName) => {
            ctx.pushEvent("update_field", {
              field: this.secretInputName,
              value: secretName,
            });
            this.$emit("update:secretInputValue", secretName);
          },
          preselectName,
          { title: this.modalTitle }
        );
      },
    },

    template: `
      <div class="input-icon-container">
        <BaseInput
          v-if="toggleInputValue"
          :name="secretInputName"
          :label="label"
          :value="secretInputValue"
          inputClass="input secret-input"
          readonly
          @click="selectSecret"
          @input="$emit('update:secretInputValue', $event.target.value)"
          :required="required"
        />
        <BaseInput
          v-else
          :name="textInputName"
          :label="label"
          type="text"
          :value="textInputValue"
          inputClass="input"
          @input="$emit('update:textInputValue', $event.target.value)"
          :required="required"
        />
        <label class="icon-container">
          <input
            type="checkbox"
            :name="toggleInputName"
            :checked="toggleInputValue"
            @input="$emit('update:toggleInputValue', $event.target.checked)"
            class="hidden-checkbox-input"
          />
          <svg v-if="toggleInputValue" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                width="22" height="22">
            <path fill="none" d="M0 0h24v24H0z"/>
            <path d="M18 8h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1h2V7a6 6 0 1 1 12 0v1zM5
              10v10h14V10H5zm6 4h2v2h-2v-2zm-4 0h2v2H7v-2zm8 0h2v2h-2v-2zm1-6V7a4 4 0 1 0-8 0v1h8z" fill="#000"/>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
            <path fill="none" d="M0 0h24v24H0z"/>
            <path d="M21 3v18H3V3h18zm-8.001 3h-2L6.6 17h2.154l1.199-3h4.09l1.201 3h2.155l-4.4-11zm-1 2.885L13.244
              12h-2.492l1.247-3.115z" fill="#445668"/>
          </svg>
        </label>
      </div>
    `,
  };

  const app = Vue.createApp({
    components: {
      BaseInput,
      InlineLabel,
      BaseSecret,
    },

    template: `
    <div class="app">
      <form @change="handleFieldChange">
        <div class="header">
          <div class="field-wrapper">
            <InlineLabel label="Node" />
            <BaseSecret
              textInputName="node"
              secretInputName="node_secret"
              toggleInputName="use_node_secret"
              v-model:textInputValue="fields.node"
              v-model:secretInputValue="fields.node_secret"
              v-model:toggleInputValue="fields.use_node_secret"
              modalTitle="Set node value"
              required
            />
          </div>
          <div class="field-wrapper">
            <InlineLabel label="Cookie" />
            <BaseSecret
              textInputName="cookie"
              secretInputName="cookie_secret"
              toggleInputName="use_cookie_secret"
              v-model:textInputValue="fields.cookie"
              v-model:secretInputValue="fields.cookie_secret"
              v-model:toggleInputValue="fields.use_cookie_secret"
              modalTitle="Set cookie value"
              required
            />
          </div>
          <div class="field-wrapper">
            <InlineLabel label="Assign to" />
            <BaseInput
              name="assign_to"
              v-model="fields.assign_to"
              inputClass="input input--xs"
            />
          </div>
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
        const field = event.target.name;
        const value = this.fields[field];
        ctx.pushEvent("update_field", { field, value });
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
