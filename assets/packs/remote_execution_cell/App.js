import React, { useEffect, useRef, useState } from "react";
import {
  RiLockPasswordLine,
  RiInputMethodLine,
  RiArrowDownSLine,
} from "@remixicon/react";
import classNames from "classnames";

export default function App({ ctx, payload }) {
  const [fields, setFields] = useState(payload.fields);
  const [nodeVariables, setNodeVariables] = useState(payload.node_variables);
  const [cookieVariables, setCookieVariables] = useState(
    payload.cookie_variables,
  );

  useEffect(() => {
    ctx.handleEvent("update_field", ({ fields }) => {
      setFields((currentFields) => ({ ...currentFields, ...fields }));
    });

    ctx.handleEvent("variables", ({ node_variables, cookie_variables }) => {
      setNodeVariables(node_variables);
      setCookieVariables(cookie_variables);
    });
  }, []);

  function pushUpdate(field, value) {
    ctx.pushEvent("update_field", { field, value });
  }

  function handleChange(event, push = true) {
    const field = event.target.name;

    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;

    setFields({ ...fields, [field]: value });

    if (push) {
      pushUpdate(field, value);
    }
  }

  function handleBlur(event) {
    const field = event.target.name;

    pushUpdate(field, fields[field]);
  }

  return (
    <div className="font-sans">
      <Header>
        <FieldWrapper>
          <InlineLabel label="Node" />
          <SecretField
            ctx={ctx}
            source={fields.node_source}
            onSourceChange={(source) => pushUpdate("node_source", source)}
            textInputProps={{
              name: "node_text",
              value: fields.node_text,
              onChange: (event) => handleChange(event, false),
              onBlur: handleBlur,
            }}
            secretInputProps={{
              name: "node_secret",
              value: fields.node_secret,
              onChange: handleChange,
            }}
            variableSelectProps={{
              name: "node_variable",
              value: fields.node_variable,
              onChange: handleChange,
              options: nodeVariables.map((variable) => ({
                label: variable,
                value: variable,
              })),
            }}
            modalTitle="Set node value"
            required
          />
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="Cookie" />
          <SecretField
            ctx={ctx}
            source={fields.cookie_source}
            onSourceChange={(source) => pushUpdate("cookie_source", source)}
            textInputProps={{
              name: "cookie_text",
              value: fields.cookie_text,
              onChange: (event) => handleChange(event, false),
              onBlur: handleBlur,
            }}
            secretInputProps={{
              name: "cookie_secret",
              value: fields.cookie_secret,
              onChange: handleChange,
            }}
            variableSelectProps={{
              name: "cookie_variable",
              value: fields.cookie_variable,
              onChange: handleChange,
              options: cookieVariables.map((variable) => ({
                label: variable,
                value: variable,
              })),
            }}
            modalTitle="Set cookie value"
            required
          />
        </FieldWrapper>
        <FieldWrapper>
          <InlineLabel label="Assign to" />
          <div className="w-[140px]">
            <TextField
              name="assign_to"
              value={fields.assign_to}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
            />
          </div>
        </FieldWrapper>
      </Header>
    </div>
  );
}

function Header({ children }) {
  return (
    <div className="align-stretch flex flex-wrap justify-start gap-4 rounded-t-lg border border-gray-300 border-b-gray-200 bg-blue-100 px-4 py-2">
      {children}
    </div>
  );
}

function FieldWrapper({ children }) {
  return <div className="flex items-center gap-1.5">{children}</div>;
}

function InlineLabel({ label }) {
  return (
    <label className="block text-sm font-medium uppercase text-gray-600">
      {label}
    </label>
  );
}

function TextField({
  label = null,
  value,
  type = "text",
  className,
  required = false,
  fullWidth = false,
  inputRef,
  startAdornment,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <input
          {...props}
          ref={inputRef}
          type={type}
          value={value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        />
      </div>
    </div>
  );
}

export function SelectField({
  label = null,
  value,
  className,
  options = [],
  optionGroups = [],
  required = false,
  fullWidth = false,
  startAdornment,
  ...props
}) {
  function renderOptions(options) {
    return options.map((option) => (
      <option key={option.value || ""} value={option.value || ""}>
        {option.label}
      </option>
    ));
  }

  const isValueAvailable = options.some((option) => option.value === value);

  const noOptions = options.length === 0 && optionGroups.length === 0;

  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && !value ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <div
          className={classNames(["w-full relative", noOptions && "opacity-50"])}
        >
          <select
            {...props}
            value={value}
            className={classNames([
              "w-full appearance-none bg-transparent px-3 py-2 pr-7 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
              !isValueAvailable && "text-opacity-50",
              className,
            ])}
          >
            {/* If the value is not in options, we still want to show it.
                For example, a variable that is not bound yet. */}
            {!isValueAvailable && <option value={value}>{value}</option>}
            {renderOptions(options)}
            {optionGroups.map(({ label, options }) => (
              <optgroup key={label} label={label}>
                {renderOptions(options)}
              </optgroup>
            ))}
          </select>
          <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500">
            <RiArrowDownSLine size={16} />
          </div>
        </div>
      </div>
    </div>
  );
}

function SecretField({
  ctx,
  source,
  onSourceChange,
  textInputProps,
  secretInputProps,
  variableSelectProps,
  label = null,
  required = false,
  modalTitle = "Select secret",
}) {
  const secretInputRef = useRef(null);

  function selectSecret() {
    const preselectName = secretInputProps.value || "";

    ctx.selectSecret(
      (secretName) => {
        const input = secretInputRef.current;
        const value = secretName;
        // Simulate native input
        Object.getOwnPropertyDescriptor(
          HTMLInputElement.prototype,
          "value",
        ).set.call(input, value);
        input.dispatchEvent(new Event("input", { bubbles: true }));
      },
      preselectName,
      { title: modalTitle },
    );
  }

  const sources = ["text", "secret", "variable"];

  function onSourceClick() {
    const sourceIndex = sources.indexOf(source);
    const nextSource = sources[(sourceIndex + 1) % sources.length];
    onSourceChange(nextSource);
  }

  const inputTypeToggle = (
    <div
      className="flex items-center border-r border-gray-200 bg-gray-200 px-1.5 text-gray-600 hover:cursor-pointer hover:bg-gray-300"
      onClick={onSourceClick}
    >
      {source === "text" && <RiInputMethodLine size={24} />}
      {source === "secret" && <RiLockPasswordLine size={24} />}
      {source === "variable" && (
        <span className="w-6 h-6 text-center leading-none text-xl">𝑥</span>
      )}
    </div>
  );

  if (source === "text") {
    return (
      <TextField
        {...textInputProps}
        label={label}
        startAdornment={inputTypeToggle}
        required={required}
      />
    );
  }

  if (source === "secret") {
    return (
      <TextField
        {...secretInputProps}
        inputRef={secretInputRef}
        label={label}
        startAdornment={inputTypeToggle}
        required={required}
        onClick={selectSecret}
        className="cursor-pointer"
        readOnly
      />
    );
  }

  if (source === "variable") {
    return (
      <SelectField
        {...variableSelectProps}
        label={label}
        startAdornment={inputTypeToggle}
        required={required}
      />
    );
  }
}
