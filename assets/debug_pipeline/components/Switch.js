import React from "react";

export default function Switch(props) {
  return (
    <label class="switch-button">
      <input type="checkbox" class="switch-button__checkbox" {...props} />
      <div class="switch-button__bg" />
    </label>
  );
}
