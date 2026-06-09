import {
  ClickOutsideContainer,
  ThemeContext,
  isEditableGridCell,
  isInnerOnlyCell,
  isObjectEditorCallbackResult,
  makeCSSStyle,
  require_react_dom
} from "./chunk-SOT7EBMF.js";
import {
  __spreadValues,
  __toESM,
  require_react,
  styled_default
} from "./chunk-YFLBMG7Q.js";

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/data-grid-overlay-editor.js
var React2 = __toESM(require_react(), 1);
var import_react_dom = __toESM(require_react_dom(), 1);

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/data-grid-overlay-editor-style.js
var _exp2 = () => (p) => p.targetX;
var _exp3 = () => (p) => p.targetY;
var _exp4 = () => (p) => p.targetWidth;
var _exp5 = () => (p) => p.targetHeight;
var _exp6 = () => (p) => p.targetY + 10;
var _exp7 = () => (p) => Math.max(0, (p.targetHeight - 28) / 2);
var DataGridOverlayEditorStyle = /* @__PURE__ */ styled_default("div")({
  name: "DataGridOverlayEditorStyle",
  class: "gdg-d19meir1",
  propsAsIs: false,
  vars: {
    "d19meir1-0": [_exp3(), "px"],
    "d19meir1-1": [_exp2(), "px"],
    "d19meir1-2": [_exp4(), "px"],
    "d19meir1-3": [_exp5(), "px"],
    "d19meir1-4": [_exp6(), "px"],
    "d19meir1-5": [_exp7(), "px"]
  }
});

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/use-stay-on-screen.js
var React = __toESM(require_react(), 1);
function useRefState() {
  const [refState, setRefState] = React.useState();
  return [refState != null ? refState : void 0, setRefState];
}
function useStayOnScreen() {
  const [ref, setRef] = useRefState();
  const [xOffset, setXOffset] = React.useState(0);
  const [isIntersecting, setIsIntersecting] = React.useState(true);
  React.useLayoutEffect(() => {
    if (ref === void 0)
      return;
    if (!("IntersectionObserver" in window))
      return;
    const observer = new IntersectionObserver((ents) => {
      if (ents.length === 0)
        return;
      setIsIntersecting(ents[0].isIntersecting);
    }, { threshold: 1 });
    observer.observe(ref);
    return () => observer.disconnect();
  }, [ref]);
  React.useEffect(() => {
    if (isIntersecting || ref === void 0)
      return;
    let rafHandle;
    const fn = () => {
      const { right: refRight } = ref.getBoundingClientRect();
      setXOffset((cv) => Math.min(cv + window.innerWidth - refRight - 10, 0));
      rafHandle = requestAnimationFrame(fn);
    };
    rafHandle = requestAnimationFrame(fn);
    return () => {
      if (rafHandle !== void 0) {
        cancelAnimationFrame(rafHandle);
      }
    };
  }, [ref, isIntersecting]);
  const style = React.useMemo(() => {
    return { transform: `translateX(${xOffset}px)` };
  }, [xOffset]);
  return {
    ref: setRef,
    style
  };
}

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/data-grid-overlay-editor.js
var DataGridOverlayEditor = (p) => {
  var _a, _b;
  const { target, content, onFinishEditing: onFinishEditingIn, forceEditMode, initialValue, imageEditorOverride, markdownDivCreateNode, highlight, className, theme, id, cell, bloom, validateCell, getCellRenderer, provideEditor, isOutsideClick } = p;
  const [tempValue, setTempValueRaw] = React2.useState(forceEditMode ? content : void 0);
  const lastValueRef = React2.useRef(tempValue != null ? tempValue : content);
  lastValueRef.current = tempValue != null ? tempValue : content;
  const [isValid, setIsValid] = React2.useState(() => {
    if (validateCell === void 0)
      return true;
    return !(isEditableGridCell(content) && (validateCell == null ? void 0 : validateCell(cell, content, lastValueRef.current)) === false);
  });
  const onFinishEditing = React2.useCallback((newCell, movement) => {
    onFinishEditingIn(isValid ? newCell : void 0, movement);
  }, [isValid, onFinishEditingIn]);
  const setTempValue = React2.useCallback((newVal) => {
    if (validateCell !== void 0 && newVal !== void 0 && isEditableGridCell(newVal)) {
      const validResult = validateCell(cell, newVal, lastValueRef.current);
      if (validResult === false) {
        setIsValid(false);
      } else if (typeof validResult === "object") {
        newVal = validResult;
        setIsValid(true);
      } else {
        setIsValid(true);
      }
    }
    setTempValueRaw(newVal);
  }, [cell, validateCell]);
  const finished = React2.useRef(false);
  const customMotion = React2.useRef(void 0);
  const onClickOutside = React2.useCallback(() => {
    onFinishEditing(tempValue, [0, 0]);
    finished.current = true;
  }, [tempValue, onFinishEditing]);
  const onEditorFinished = React2.useCallback((newValue, movement) => {
    var _a2;
    onFinishEditing(newValue, (_a2 = movement != null ? movement : customMotion.current) != null ? _a2 : [0, 0]);
    finished.current = true;
  }, [onFinishEditing]);
  const onKeyDown = React2.useCallback(async (event) => {
    let save = false;
    if (event.key === "Escape") {
      event.stopPropagation();
      event.preventDefault();
      customMotion.current = [0, 0];
    } else if (event.key === "Enter" && !event.shiftKey) {
      event.stopPropagation();
      event.preventDefault();
      customMotion.current = [0, 1];
      save = true;
    } else if (event.key === "Tab") {
      event.stopPropagation();
      event.preventDefault();
      customMotion.current = [event.shiftKey ? -1 : 1, 0];
      save = true;
    }
    window.setTimeout(() => {
      if (!finished.current && customMotion.current !== void 0) {
        onFinishEditing(save ? tempValue : void 0, customMotion.current);
        finished.current = true;
      }
    }, 0);
  }, [onFinishEditing, tempValue]);
  const targetValue = tempValue != null ? tempValue : content;
  const [editorProvider, useLabel] = React2.useMemo(() => {
    var _a2, _b2;
    if (isInnerOnlyCell(content))
      return [];
    const external = provideEditor == null ? void 0 : provideEditor(content);
    if (external !== void 0)
      return [external, false];
    return [(_b2 = (_a2 = getCellRenderer(content)) == null ? void 0 : _a2.provideEditor) == null ? void 0 : _b2.call(_a2, content), false];
  }, [content, getCellRenderer, provideEditor]);
  const { ref, style: stayOnScreenStyle } = useStayOnScreen();
  let pad = true;
  let editor;
  let style = true;
  let styleOverride;
  if (editorProvider !== void 0) {
    pad = editorProvider.disablePadding !== true;
    style = editorProvider.disableStyling !== true;
    const isObjectEditor = isObjectEditorCallbackResult(editorProvider);
    if (isObjectEditor) {
      styleOverride = editorProvider.styleOverride;
    }
    const CustomEditor = isObjectEditor ? editorProvider.editor : editorProvider;
    editor = React2.createElement(CustomEditor, { isHighlighted: highlight, onChange: setTempValue, value: targetValue, initialValue, onFinishedEditing: onEditorFinished, validatedSelection: isEditableGridCell(targetValue) ? targetValue.selectionRange : void 0, forceEditMode, target, imageEditorOverride, markdownDivCreateNode, isValid, theme });
  }
  styleOverride = __spreadValues(__spreadValues({}, styleOverride), stayOnScreenStyle);
  const portalElement = document.getElementById("portal");
  if (portalElement === null) {
    console.error('Cannot open Data Grid overlay editor, because portal not found.  Please add `<div id="portal" />` as the last child of your `<body>`.');
    return null;
  }
  let classWrap = style ? "gdg-style" : "gdg-unstyle";
  if (!isValid) {
    classWrap += " gdg-invalid";
  }
  if (pad) {
    classWrap += " gdg-pad";
  }
  const bloomX = (_a = bloom == null ? void 0 : bloom[0]) != null ? _a : 1;
  const bloomY = (_b = bloom == null ? void 0 : bloom[1]) != null ? _b : 1;
  return (0, import_react_dom.createPortal)(React2.createElement(
    ThemeContext.Provider,
    { value: theme },
    React2.createElement(
      ClickOutsideContainer,
      { style: makeCSSStyle(theme), className, onClickOutside, isOutsideClick },
      React2.createElement(
        DataGridOverlayEditorStyle,
        { ref, id, className: classWrap, style: styleOverride, as: useLabel === true ? "label" : void 0, targetX: target.x - bloomX, targetY: target.y - bloomY, targetWidth: target.width + bloomX * 2, targetHeight: target.height + bloomY * 2 },
        React2.createElement("div", { className: "gdg-clip-region", onKeyDown }, editor)
      )
    )
  ), portalElement);
};
var data_grid_overlay_editor_default = DataGridOverlayEditor;
export {
  data_grid_overlay_editor_default as default
};
//# sourceMappingURL=data-grid-overlay-editor-MWTLIABC.js.map
