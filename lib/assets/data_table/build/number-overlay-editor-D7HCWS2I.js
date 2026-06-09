import {
  __toESM,
  require_react,
  styled_default
} from "./chunk-YFLBMG7Q.js";

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/private/number-overlay-editor.js
var React2 = __toESM(require_react(), 1);

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/private/number-overlay-editor-style.js
var NumberOverlayEditorStyle = /* @__PURE__ */ styled_default("div")({
  name: "NumberOverlayEditorStyle",
  class: "gdg-n15fjm3e",
  propsAsIs: false
});

// node_modules/react-number-format/dist/react-number-format.es.js
var import_react2 = __toESM(require_react());
function __rest(s, e) {
  var t = {};
  for (var p in s) {
    if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0) {
      t[p] = s[p];
    }
  }
  if (s != null && typeof Object.getOwnPropertySymbols === "function") {
    for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
      if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i])) {
        t[p[i]] = s[p[i]];
      }
    }
  }
  return t;
}
var SourceType;
(function(SourceType2) {
  SourceType2["event"] = "event";
  SourceType2["props"] = "prop";
})(SourceType || (SourceType = {}));
function noop() {
}
function memoizeOnce(cb) {
  var lastArgs;
  var lastValue = void 0;
  return function() {
    var args = [], len = arguments.length;
    while (len--)
      args[len] = arguments[len];
    if (lastArgs && args.length === lastArgs.length && args.every(function(value, index) {
      return value === lastArgs[index];
    })) {
      return lastValue;
    }
    lastArgs = args;
    lastValue = cb.apply(void 0, args);
    return lastValue;
  };
}
function charIsNumber(char) {
  return !!(char || "").match(/\d/);
}
function isNil(val) {
  return val === null || val === void 0;
}
function isNanValue(val) {
  return typeof val === "number" && isNaN(val);
}
function isNotValidValue(val) {
  return isNil(val) || isNanValue(val) || typeof val === "number" && !isFinite(val);
}
function escapeRegExp(str) {
  return str.replace(/[-[\]/{}()*+?.\\^$|]/g, "\\$&");
}
function getThousandsGroupRegex(thousandsGroupStyle) {
  switch (thousandsGroupStyle) {
    case "lakh":
      return /(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?/g;
    case "wan":
      return /(\d)(?=(\d{4})+(?!\d))/g;
    case "thousand":
    default:
      return /(\d)(?=(\d{3})+(?!\d))/g;
  }
}
function applyThousandSeparator(str, thousandSeparator, thousandsGroupStyle) {
  var thousandsGroupRegex = getThousandsGroupRegex(thousandsGroupStyle);
  var index = str.search(/[1-9]/);
  index = index === -1 ? str.length : index;
  return str.substring(0, index) + str.substring(index, str.length).replace(thousandsGroupRegex, "$1" + thousandSeparator);
}
function usePersistentCallback(cb) {
  var callbackRef = (0, import_react2.useRef)(cb);
  callbackRef.current = cb;
  var persistentCbRef = (0, import_react2.useRef)(function() {
    var args = [], len = arguments.length;
    while (len--)
      args[len] = arguments[len];
    return callbackRef.current.apply(callbackRef, args);
  });
  return persistentCbRef.current;
}
function splitDecimal(numStr, allowNegative) {
  if (allowNegative === void 0)
    allowNegative = true;
  var hasNegation = numStr[0] === "-";
  var addNegation = hasNegation && allowNegative;
  numStr = numStr.replace("-", "");
  var parts = numStr.split(".");
  var beforeDecimal = parts[0];
  var afterDecimal = parts[1] || "";
  return {
    beforeDecimal,
    afterDecimal,
    hasNegation,
    addNegation
  };
}
function fixLeadingZero(numStr) {
  if (!numStr) {
    return numStr;
  }
  var isNegative = numStr[0] === "-";
  if (isNegative) {
    numStr = numStr.substring(1, numStr.length);
  }
  var parts = numStr.split(".");
  var beforeDecimal = parts[0].replace(/^0+/, "") || "0";
  var afterDecimal = parts[1] || "";
  return (isNegative ? "-" : "") + beforeDecimal + (afterDecimal ? "." + afterDecimal : "");
}
function limitToScale(numStr, scale, fixedDecimalScale) {
  var str = "";
  var filler = fixedDecimalScale ? "0" : "";
  for (var i = 0; i <= scale - 1; i++) {
    str += numStr[i] || filler;
  }
  return str;
}
function repeat(str, count) {
  return Array(count + 1).join(str);
}
function toNumericString(num) {
  var _num = num + "";
  var sign = _num[0] === "-" ? "-" : "";
  if (sign) {
    _num = _num.substring(1);
  }
  var ref = _num.split(/[eE]/g);
  var coefficient = ref[0];
  var exponent = ref[1];
  exponent = Number(exponent);
  if (!exponent) {
    return sign + coefficient;
  }
  coefficient = coefficient.replace(".", "");
  var decimalIndex = 1 + exponent;
  var coffiecientLn = coefficient.length;
  if (decimalIndex < 0) {
    coefficient = "0." + repeat("0", Math.abs(decimalIndex)) + coefficient;
  } else if (decimalIndex >= coffiecientLn) {
    coefficient = coefficient + repeat("0", decimalIndex - coffiecientLn);
  } else {
    coefficient = (coefficient.substring(0, decimalIndex) || "0") + "." + coefficient.substring(decimalIndex);
  }
  return sign + coefficient;
}
function roundToPrecision(numStr, scale, fixedDecimalScale) {
  if (["", "-"].indexOf(numStr) !== -1) {
    return numStr;
  }
  var shouldHaveDecimalSeparator = (numStr.indexOf(".") !== -1 || fixedDecimalScale) && scale;
  var ref = splitDecimal(numStr);
  var beforeDecimal = ref.beforeDecimal;
  var afterDecimal = ref.afterDecimal;
  var hasNegation = ref.hasNegation;
  var floatValue = parseFloat("0." + (afterDecimal || "0"));
  var floatValueStr = afterDecimal.length <= scale ? "0." + afterDecimal : floatValue.toFixed(scale);
  var roundedDecimalParts = floatValueStr.split(".");
  var intPart = beforeDecimal;
  if (beforeDecimal && Number(roundedDecimalParts[0])) {
    intPart = beforeDecimal.split("").reverse().reduce(function(roundedStr, current, idx) {
      if (roundedStr.length > idx) {
        return (Number(roundedStr[0]) + Number(current)).toString() + roundedStr.substring(1, roundedStr.length);
      }
      return current + roundedStr;
    }, roundedDecimalParts[0]);
  }
  var decimalPart = limitToScale(roundedDecimalParts[1] || "", scale, fixedDecimalScale);
  var negation = hasNegation ? "-" : "";
  var decimalSeparator = shouldHaveDecimalSeparator ? "." : "";
  return "" + negation + intPart + decimalSeparator + decimalPart;
}
function setCaretPosition(el, caretPos) {
  el.value = el.value;
  if (el !== null) {
    if (el.createTextRange) {
      var range = el.createTextRange();
      range.move("character", caretPos);
      range.select();
      return true;
    }
    if (el.selectionStart || el.selectionStart === 0) {
      el.focus();
      el.setSelectionRange(caretPos, caretPos);
      return true;
    }
    el.focus();
    return false;
  }
}
var findChangeRange = memoizeOnce(function(prevValue, newValue) {
  var i = 0, j = 0;
  var prevLength = prevValue.length;
  var newLength = newValue.length;
  while (prevValue[i] === newValue[i] && i < prevLength) {
    i++;
  }
  while (prevValue[prevLength - 1 - j] === newValue[newLength - 1 - j] && newLength - j > i && prevLength - j > i) {
    j++;
  }
  return {
    from: { start: i, end: prevLength - j },
    to: { start: i, end: newLength - j }
  };
});
var findChangedRangeFromCaretPositions = function(lastCaretPositions, currentCaretPosition) {
  var startPosition = Math.min(lastCaretPositions.selectionStart, currentCaretPosition);
  return {
    from: { start: startPosition, end: lastCaretPositions.selectionEnd },
    to: { start: startPosition, end: currentCaretPosition }
  };
};
function clamp(num, min, max) {
  return Math.min(Math.max(num, min), max);
}
function geInputCaretPosition(el) {
  return Math.max(el.selectionStart, el.selectionEnd);
}
function addInputMode() {
  return typeof navigator !== "undefined" && !(navigator.platform && /iPhone|iPod/.test(navigator.platform));
}
function getDefaultChangeMeta(value) {
  return {
    from: {
      start: 0,
      end: 0
    },
    to: {
      start: 0,
      end: value.length
    },
    lastValue: ""
  };
}
function defaultIsCharacterSame(ref) {
  var currentValue = ref.currentValue;
  var formattedValue = ref.formattedValue;
  var currentValueIndex = ref.currentValueIndex;
  var formattedValueIndex = ref.formattedValueIndex;
  return currentValue[currentValueIndex] === formattedValue[formattedValueIndex];
}
function getCaretPosition(newFormattedValue, lastFormattedValue, curValue, curCaretPos, boundary, isValidInputCharacter, isCharacterSame) {
  if (isCharacterSame === void 0)
    isCharacterSame = defaultIsCharacterSame;
  var firstAllowedPosition = boundary.findIndex(function(b) {
    return b;
  });
  var prefixFormat = newFormattedValue.slice(0, firstAllowedPosition);
  if (!lastFormattedValue && !curValue.startsWith(prefixFormat)) {
    lastFormattedValue = prefixFormat;
    curValue = prefixFormat + curValue;
    curCaretPos = curCaretPos + prefixFormat.length;
  }
  var curValLn = curValue.length;
  var formattedValueLn = newFormattedValue.length;
  var addedIndexMap = {};
  var indexMap = new Array(curValLn);
  for (var i = 0; i < curValLn; i++) {
    indexMap[i] = -1;
    for (var j = 0, jLn = formattedValueLn; j < jLn; j++) {
      var isCharSame = isCharacterSame({
        currentValue: curValue,
        lastValue: lastFormattedValue,
        formattedValue: newFormattedValue,
        currentValueIndex: i,
        formattedValueIndex: j
      });
      if (isCharSame && addedIndexMap[j] !== true) {
        indexMap[i] = j;
        addedIndexMap[j] = true;
        break;
      }
    }
  }
  var pos = curCaretPos;
  while (pos < curValLn && (indexMap[pos] === -1 || !isValidInputCharacter(curValue[pos]))) {
    pos++;
  }
  var endIndex = pos === curValLn || indexMap[pos] === -1 ? formattedValueLn : indexMap[pos];
  pos = curCaretPos - 1;
  while (pos > 0 && indexMap[pos] === -1) {
    pos--;
  }
  var startIndex = pos === -1 || indexMap[pos] === -1 ? 0 : indexMap[pos] + 1;
  if (startIndex > endIndex) {
    return endIndex;
  }
  return curCaretPos - startIndex < endIndex - curCaretPos ? startIndex : endIndex;
}
function getCaretPosInBoundary(value, caretPos, boundary, direction) {
  var valLn = value.length;
  caretPos = clamp(caretPos, 0, valLn);
  if (direction === "left") {
    while (caretPos >= 0 && !boundary[caretPos]) {
      caretPos--;
    }
    if (caretPos === -1) {
      caretPos = boundary.indexOf(true);
    }
  } else {
    while (caretPos <= valLn && !boundary[caretPos]) {
      caretPos++;
    }
    if (caretPos > valLn) {
      caretPos = boundary.lastIndexOf(true);
    }
  }
  if (caretPos === -1) {
    caretPos = valLn;
  }
  return caretPos;
}
function caretUnknownFormatBoundary(formattedValue) {
  var boundaryAry = Array.from({ length: formattedValue.length + 1 }).map(function() {
    return true;
  });
  for (var i = 0, ln = boundaryAry.length; i < ln; i++) {
    boundaryAry[i] = Boolean(charIsNumber(formattedValue[i]) || charIsNumber(formattedValue[i - 1]));
  }
  return boundaryAry;
}
function useInternalValues(value, defaultValue, valueIsNumericString, format2, removeFormatting2, onValueChange) {
  if (onValueChange === void 0)
    onValueChange = noop;
  var getValues = usePersistentCallback(function(value2, valueIsNumericString2) {
    var formattedValue, numAsString;
    if (isNotValidValue(value2)) {
      numAsString = "";
      formattedValue = "";
    } else if (typeof value2 === "number" || valueIsNumericString2) {
      numAsString = typeof value2 === "number" ? toNumericString(value2) : value2;
      formattedValue = format2(numAsString);
    } else {
      numAsString = removeFormatting2(value2, void 0);
      formattedValue = format2(numAsString);
    }
    return { formattedValue, numAsString };
  });
  var ref = (0, import_react2.useState)(function() {
    return getValues(isNil(value) ? defaultValue : value, valueIsNumericString);
  });
  var values = ref[0];
  var setValues = ref[1];
  var _onValueChange = function(newValues2, sourceInfo) {
    if (newValues2.formattedValue !== values.formattedValue) {
      setValues({
        formattedValue: newValues2.formattedValue,
        numAsString: newValues2.value
      });
    }
    onValueChange(newValues2, sourceInfo);
  };
  var _value = value;
  var _valueIsNumericString = valueIsNumericString;
  if (isNil(value)) {
    _value = values.numAsString;
    _valueIsNumericString = true;
  }
  var newValues = getValues(_value, _valueIsNumericString);
  (0, import_react2.useMemo)(function() {
    setValues(newValues);
  }, [newValues.formattedValue]);
  return [values, _onValueChange];
}
function defaultRemoveFormatting(value) {
  return value.replace(/[^0-9]/g, "");
}
function defaultFormat(value) {
  return value;
}
function NumberFormatBase(props) {
  var type = props.type;
  if (type === void 0)
    type = "text";
  var displayType = props.displayType;
  if (displayType === void 0)
    displayType = "input";
  var customInput = props.customInput;
  var renderText = props.renderText;
  var getInputRef = props.getInputRef;
  var format2 = props.format;
  if (format2 === void 0)
    format2 = defaultFormat;
  var removeFormatting2 = props.removeFormatting;
  if (removeFormatting2 === void 0)
    removeFormatting2 = defaultRemoveFormatting;
  var defaultValue = props.defaultValue;
  var valueIsNumericString = props.valueIsNumericString;
  var onValueChange = props.onValueChange;
  var isAllowed = props.isAllowed;
  var onChange = props.onChange;
  if (onChange === void 0)
    onChange = noop;
  var onKeyDown = props.onKeyDown;
  if (onKeyDown === void 0)
    onKeyDown = noop;
  var onMouseUp = props.onMouseUp;
  if (onMouseUp === void 0)
    onMouseUp = noop;
  var onFocus = props.onFocus;
  if (onFocus === void 0)
    onFocus = noop;
  var onBlur = props.onBlur;
  if (onBlur === void 0)
    onBlur = noop;
  var propValue = props.value;
  var getCaretBoundary2 = props.getCaretBoundary;
  if (getCaretBoundary2 === void 0)
    getCaretBoundary2 = caretUnknownFormatBoundary;
  var isValidInputCharacter = props.isValidInputCharacter;
  if (isValidInputCharacter === void 0)
    isValidInputCharacter = charIsNumber;
  var isCharacterSame = props.isCharacterSame;
  var otherProps = __rest(props, ["type", "displayType", "customInput", "renderText", "getInputRef", "format", "removeFormatting", "defaultValue", "valueIsNumericString", "onValueChange", "isAllowed", "onChange", "onKeyDown", "onMouseUp", "onFocus", "onBlur", "value", "getCaretBoundary", "isValidInputCharacter", "isCharacterSame"]);
  var ref = useInternalValues(propValue, defaultValue, Boolean(valueIsNumericString), format2, removeFormatting2, onValueChange);
  var ref_0 = ref[0];
  var formattedValue = ref_0.formattedValue;
  var numAsString = ref_0.numAsString;
  var onFormattedValueChange = ref[1];
  var caretPositionBeforeChange = (0, import_react2.useRef)();
  var lastUpdatedValue = (0, import_react2.useRef)({ formattedValue, numAsString });
  var _onValueChange = function(values, source) {
    lastUpdatedValue.current = { formattedValue: values.formattedValue, numAsString: values.value };
    onFormattedValueChange(values, source);
  };
  var ref$1 = (0, import_react2.useState)(false);
  var mounted = ref$1[0];
  var setMounted = ref$1[1];
  var focusedElm = (0, import_react2.useRef)(null);
  var timeout = (0, import_react2.useRef)({
    setCaretTimeout: null,
    focusTimeout: null
  });
  (0, import_react2.useEffect)(function() {
    setMounted(true);
    return function() {
      clearTimeout(timeout.current.setCaretTimeout);
      clearTimeout(timeout.current.focusTimeout);
    };
  }, []);
  var _format = format2;
  var getValueObject = function(formattedValue2, numAsString2) {
    var floatValue = parseFloat(numAsString2);
    return {
      formattedValue: formattedValue2,
      value: numAsString2,
      floatValue: isNaN(floatValue) ? void 0 : floatValue
    };
  };
  var setPatchedCaretPosition = function(el, caretPos, currentValue) {
    if (el.selectionStart === 0 && el.selectionEnd === el.value.length) {
      return;
    }
    setCaretPosition(el, caretPos);
    timeout.current.setCaretTimeout = setTimeout(function() {
      if (el.value === currentValue && el.selectionStart !== caretPos) {
        setCaretPosition(el, caretPos);
      }
    }, 0);
  };
  var correctCaretPosition = function(value, caretPos, direction) {
    return getCaretPosInBoundary(value, caretPos, getCaretBoundary2(value), direction);
  };
  var getNewCaretPosition = function(inputValue, newFormattedValue, caretPos) {
    var caretBoundary = getCaretBoundary2(newFormattedValue);
    var updatedCaretPos = getCaretPosition(newFormattedValue, formattedValue, inputValue, caretPos, caretBoundary, isValidInputCharacter, isCharacterSame);
    updatedCaretPos = getCaretPosInBoundary(newFormattedValue, updatedCaretPos, caretBoundary);
    return updatedCaretPos;
  };
  var updateValueAndCaretPosition = function(params) {
    var newFormattedValue = params.formattedValue;
    if (newFormattedValue === void 0)
      newFormattedValue = "";
    var input = params.input;
    var source = params.source;
    var event = params.event;
    var numAsString2 = params.numAsString;
    var caretPos;
    if (input) {
      var inputValue = params.inputValue || input.value;
      var currentCaretPosition2 = geInputCaretPosition(input);
      input.value = newFormattedValue;
      caretPos = getNewCaretPosition(inputValue, newFormattedValue, currentCaretPosition2);
      if (caretPos !== void 0) {
        setPatchedCaretPosition(input, caretPos, newFormattedValue);
      }
    }
    if (newFormattedValue !== formattedValue) {
      _onValueChange(getValueObject(newFormattedValue, numAsString2), { event, source });
    }
  };
  (0, import_react2.useEffect)(function() {
    var ref2 = lastUpdatedValue.current;
    var lastFormattedValue = ref2.formattedValue;
    var lastNumAsString = ref2.numAsString;
    if (formattedValue !== lastFormattedValue || numAsString !== lastNumAsString) {
      _onValueChange(getValueObject(formattedValue, numAsString), {
        event: void 0,
        source: SourceType.props
      });
    }
  }, [formattedValue, numAsString]);
  var currentCaretPosition = focusedElm.current ? geInputCaretPosition(focusedElm.current) : void 0;
  var useIsomorphicLayoutEffect = typeof window !== "undefined" ? import_react2.useLayoutEffect : import_react2.useEffect;
  useIsomorphicLayoutEffect(function() {
    var input = focusedElm.current;
    if (formattedValue !== lastUpdatedValue.current.formattedValue && input) {
      var caretPos = getNewCaretPosition(lastUpdatedValue.current.formattedValue, formattedValue, currentCaretPosition);
      input.value = formattedValue;
      setPatchedCaretPosition(input, caretPos, formattedValue);
    }
  }, [formattedValue]);
  var formatInputValue = function(inputValue, event, source) {
    var input = event.target;
    var changeRange = caretPositionBeforeChange.current ? findChangedRangeFromCaretPositions(caretPositionBeforeChange.current, input.selectionEnd) : findChangeRange(formattedValue, inputValue);
    var changeMeta = Object.assign(Object.assign({}, changeRange), { lastValue: formattedValue });
    var _numAsString = removeFormatting2(inputValue, changeMeta);
    var _formattedValue = _format(_numAsString);
    _numAsString = removeFormatting2(_formattedValue, void 0);
    if (isAllowed && !isAllowed(getValueObject(_formattedValue, _numAsString))) {
      var input$1 = event.target;
      var currentCaretPosition2 = geInputCaretPosition(input$1);
      var caretPos = getNewCaretPosition(inputValue, formattedValue, currentCaretPosition2);
      input$1.value = formattedValue;
      setPatchedCaretPosition(input$1, caretPos, formattedValue);
      return false;
    }
    updateValueAndCaretPosition({
      formattedValue: _formattedValue,
      numAsString: _numAsString,
      inputValue,
      event,
      source,
      input: event.target
    });
    return true;
  };
  var setCaretPositionInfoBeforeChange = function(el, endOffset) {
    if (endOffset === void 0)
      endOffset = 0;
    var selectionStart = el.selectionStart;
    var selectionEnd = el.selectionEnd;
    caretPositionBeforeChange.current = { selectionStart, selectionEnd: selectionEnd + endOffset };
  };
  var _onChange = function(e) {
    var el = e.target;
    var inputValue = el.value;
    var changed = formatInputValue(inputValue, e, SourceType.event);
    if (changed) {
      onChange(e);
    }
    caretPositionBeforeChange.current = void 0;
  };
  var _onKeyDown = function(e) {
    var el = e.target;
    var key = e.key;
    var selectionStart = el.selectionStart;
    var selectionEnd = el.selectionEnd;
    var value = el.value;
    if (value === void 0)
      value = "";
    var expectedCaretPosition;
    if (key === "ArrowLeft" || key === "Backspace") {
      expectedCaretPosition = Math.max(selectionStart - 1, 0);
    } else if (key === "ArrowRight") {
      expectedCaretPosition = Math.min(selectionStart + 1, value.length);
    } else if (key === "Delete") {
      expectedCaretPosition = selectionStart;
    }
    var endOffset = 0;
    if (key === "Delete" && selectionStart === selectionEnd) {
      endOffset = 1;
    }
    var isArrowKey = key === "ArrowLeft" || key === "ArrowRight";
    if (expectedCaretPosition === void 0 || selectionStart !== selectionEnd && !isArrowKey) {
      onKeyDown(e);
      setCaretPositionInfoBeforeChange(el, endOffset);
      return;
    }
    var newCaretPosition = expectedCaretPosition;
    if (isArrowKey) {
      var direction = key === "ArrowLeft" ? "left" : "right";
      newCaretPosition = correctCaretPosition(value, expectedCaretPosition, direction);
      if (newCaretPosition !== expectedCaretPosition) {
        e.preventDefault();
      }
    } else if (key === "Delete" && !isValidInputCharacter(value[expectedCaretPosition])) {
      newCaretPosition = correctCaretPosition(value, expectedCaretPosition, "right");
    } else if (key === "Backspace" && !isValidInputCharacter(value[expectedCaretPosition])) {
      newCaretPosition = correctCaretPosition(value, expectedCaretPosition, "left");
    }
    if (newCaretPosition !== expectedCaretPosition) {
      setPatchedCaretPosition(el, newCaretPosition, value);
    }
    onKeyDown(e);
    setCaretPositionInfoBeforeChange(el, endOffset);
  };
  var _onMouseUp = function(e) {
    var el = e.target;
    var correctCaretPositionIfRequired = function() {
      var selectionStart = el.selectionStart;
      var selectionEnd = el.selectionEnd;
      var value = el.value;
      if (value === void 0)
        value = "";
      if (selectionStart === selectionEnd) {
        var caretPosition = correctCaretPosition(value, selectionStart);
        if (caretPosition !== selectionStart) {
          setPatchedCaretPosition(el, caretPosition, value);
        }
      }
    };
    correctCaretPositionIfRequired();
    requestAnimationFrame(function() {
      correctCaretPositionIfRequired();
    });
    onMouseUp(e);
    setCaretPositionInfoBeforeChange(el);
  };
  var _onFocus = function(e) {
    if (e.persist) {
      e.persist();
    }
    var el = e.target;
    var currentTarget = e.currentTarget;
    focusedElm.current = el;
    timeout.current.focusTimeout = setTimeout(function() {
      var selectionStart = el.selectionStart;
      var selectionEnd = el.selectionEnd;
      var value = el.value;
      if (value === void 0)
        value = "";
      var caretPosition = correctCaretPosition(value, selectionStart);
      if (caretPosition !== selectionStart && !(selectionStart === 0 && selectionEnd === value.length)) {
        setPatchedCaretPosition(el, caretPosition, value);
      }
      onFocus(Object.assign(Object.assign({}, e), { currentTarget }));
    }, 0);
  };
  var _onBlur = function(e) {
    focusedElm.current = null;
    clearTimeout(timeout.current.focusTimeout);
    clearTimeout(timeout.current.setCaretTimeout);
    onBlur(e);
  };
  var inputMode = mounted && addInputMode() ? "numeric" : void 0;
  var inputProps = Object.assign({ inputMode }, otherProps, {
    type,
    value: formattedValue,
    onChange: _onChange,
    onKeyDown: _onKeyDown,
    onMouseUp: _onMouseUp,
    onFocus: _onFocus,
    onBlur: _onBlur
  });
  if (displayType === "text") {
    return renderText ? import_react2.default.createElement(import_react2.default.Fragment, null, renderText(formattedValue, otherProps) || null) : import_react2.default.createElement("span", Object.assign({}, otherProps, { ref: getInputRef }), formattedValue);
  } else if (customInput) {
    var CustomInput = customInput;
    return import_react2.default.createElement(CustomInput, Object.assign({}, inputProps, { ref: getInputRef }));
  }
  return import_react2.default.createElement("input", Object.assign({}, inputProps, { ref: getInputRef }));
}
function format(numStr, props) {
  var decimalScale = props.decimalScale;
  var fixedDecimalScale = props.fixedDecimalScale;
  var prefix = props.prefix;
  if (prefix === void 0)
    prefix = "";
  var suffix = props.suffix;
  if (suffix === void 0)
    suffix = "";
  var allowNegative = props.allowNegative;
  var thousandsGroupStyle = props.thousandsGroupStyle;
  if (thousandsGroupStyle === void 0)
    thousandsGroupStyle = "thousand";
  if (numStr === "" || numStr === "-") {
    return numStr;
  }
  var ref = getSeparators(props);
  var thousandSeparator = ref.thousandSeparator;
  var decimalSeparator = ref.decimalSeparator;
  var hasDecimalSeparator = decimalScale !== 0 && numStr.indexOf(".") !== -1 || decimalScale && fixedDecimalScale;
  var ref$1 = splitDecimal(numStr, allowNegative);
  var beforeDecimal = ref$1.beforeDecimal;
  var afterDecimal = ref$1.afterDecimal;
  var addNegation = ref$1.addNegation;
  if (decimalScale !== void 0) {
    afterDecimal = limitToScale(afterDecimal, decimalScale, !!fixedDecimalScale);
  }
  if (thousandSeparator) {
    beforeDecimal = applyThousandSeparator(beforeDecimal, thousandSeparator, thousandsGroupStyle);
  }
  if (prefix) {
    beforeDecimal = prefix + beforeDecimal;
  }
  if (suffix) {
    afterDecimal = afterDecimal + suffix;
  }
  if (addNegation) {
    beforeDecimal = "-" + beforeDecimal;
  }
  numStr = beforeDecimal + (hasDecimalSeparator && decimalSeparator || "") + afterDecimal;
  return numStr;
}
function getSeparators(props) {
  var decimalSeparator = props.decimalSeparator;
  if (decimalSeparator === void 0)
    decimalSeparator = ".";
  var thousandSeparator = props.thousandSeparator;
  var allowedDecimalSeparators = props.allowedDecimalSeparators;
  if (thousandSeparator === true) {
    thousandSeparator = ",";
  }
  if (!allowedDecimalSeparators) {
    allowedDecimalSeparators = [decimalSeparator, "."];
  }
  return {
    decimalSeparator,
    thousandSeparator,
    allowedDecimalSeparators
  };
}
function handleNegation(value, allowNegative) {
  if (value === void 0)
    value = "";
  var negationRegex = new RegExp("(-)");
  var doubleNegationRegex = new RegExp("(-)(.)*(-)");
  var hasNegation = negationRegex.test(value);
  var removeNegation = doubleNegationRegex.test(value);
  value = value.replace(/-/g, "");
  if (hasNegation && !removeNegation && allowNegative) {
    value = "-" + value;
  }
  return value;
}
function getNumberRegex(decimalSeparator, global) {
  return new RegExp("(^-)|[0-9]|" + escapeRegExp(decimalSeparator), global ? "g" : void 0);
}
function isNumericString(val, prefix, suffix) {
  if (val === "") {
    return true;
  }
  return !(prefix === null || prefix === void 0 ? void 0 : prefix.match(/\d/)) && !(suffix === null || suffix === void 0 ? void 0 : suffix.match(/\d/)) && typeof val === "string" && !isNaN(Number(val));
}
function removeFormatting(value, changeMeta, props) {
  var assign;
  if (changeMeta === void 0)
    changeMeta = getDefaultChangeMeta(value);
  var allowNegative = props.allowNegative;
  var prefix = props.prefix;
  if (prefix === void 0)
    prefix = "";
  var suffix = props.suffix;
  if (suffix === void 0)
    suffix = "";
  var decimalScale = props.decimalScale;
  var from = changeMeta.from;
  var to = changeMeta.to;
  var start = to.start;
  var end = to.end;
  var ref = getSeparators(props);
  var allowedDecimalSeparators = ref.allowedDecimalSeparators;
  var decimalSeparator = ref.decimalSeparator;
  var isBeforeDecimalSeparator = value[end] === decimalSeparator;
  if (charIsNumber(value) && (value === prefix || value === suffix) && changeMeta.lastValue === "") {
    return value;
  }
  if (end - start === 1 && allowedDecimalSeparators.indexOf(value[start]) !== -1) {
    var separator = decimalScale === 0 ? "" : decimalSeparator;
    value = value.substring(0, start) + separator + value.substring(start + 1, value.length);
  }
  var stripNegation = function(value2, start2, end2) {
    var hasNegation2 = false;
    var hasDoubleNegation = false;
    if (prefix.startsWith("-")) {
      hasNegation2 = false;
    } else if (value2.startsWith("--")) {
      hasNegation2 = false;
      hasDoubleNegation = true;
    } else if (suffix.startsWith("-") && value2.length === suffix.length) {
      hasNegation2 = false;
    } else if (value2[0] === "-") {
      hasNegation2 = true;
    }
    var charsToRemove = hasNegation2 ? 1 : 0;
    if (hasDoubleNegation) {
      charsToRemove = 2;
    }
    if (charsToRemove) {
      value2 = value2.substring(charsToRemove);
      start2 -= charsToRemove;
      end2 -= charsToRemove;
    }
    return { value: value2, start: start2, end: end2, hasNegation: hasNegation2 };
  };
  var toMetadata = stripNegation(value, start, end);
  var hasNegation = toMetadata.hasNegation;
  assign = toMetadata, value = assign.value, start = assign.start, end = assign.end;
  var ref$1 = stripNegation(changeMeta.lastValue, from.start, from.end);
  var fromStart = ref$1.start;
  var fromEnd = ref$1.end;
  var lastValue = ref$1.value;
  var updatedSuffixPart = value.substring(start, end);
  if (value.length && lastValue.length && (fromStart > lastValue.length - suffix.length || fromEnd < prefix.length) && !(updatedSuffixPart && suffix.startsWith(updatedSuffixPart))) {
    value = lastValue;
  }
  var startIndex = 0;
  if (value.startsWith(prefix)) {
    startIndex += prefix.length;
  } else if (start < prefix.length) {
    startIndex = start;
  }
  value = value.substring(startIndex);
  end -= startIndex;
  var endIndex = value.length;
  var suffixStartIndex = value.length - suffix.length;
  if (value.endsWith(suffix)) {
    endIndex = suffixStartIndex;
  } else if (end > suffixStartIndex) {
    endIndex = end;
  } else if (end > value.length - suffix.length) {
    endIndex = end;
  }
  value = value.substring(0, endIndex);
  value = handleNegation(hasNegation ? "-" + value : value, allowNegative);
  value = (value.match(getNumberRegex(decimalSeparator, true)) || []).join("");
  var firstIndex = value.indexOf(decimalSeparator);
  value = value.replace(new RegExp(escapeRegExp(decimalSeparator), "g"), function(match, index) {
    return index === firstIndex ? "." : "";
  });
  var ref$2 = splitDecimal(value, allowNegative);
  var beforeDecimal = ref$2.beforeDecimal;
  var afterDecimal = ref$2.afterDecimal;
  var addNegation = ref$2.addNegation;
  if (to.end - to.start < from.end - from.start && beforeDecimal === "" && isBeforeDecimalSeparator && !parseFloat(afterDecimal)) {
    value = addNegation ? "-" : "";
  }
  return value;
}
function getCaretBoundary(formattedValue, props) {
  var prefix = props.prefix;
  if (prefix === void 0)
    prefix = "";
  var suffix = props.suffix;
  if (suffix === void 0)
    suffix = "";
  var boundaryAry = Array.from({ length: formattedValue.length + 1 }).map(function() {
    return true;
  });
  var hasNegation = formattedValue[0] === "-";
  boundaryAry.fill(false, 0, prefix.length + (hasNegation ? 1 : 0));
  var valLn = formattedValue.length;
  boundaryAry.fill(false, valLn - suffix.length + 1, valLn + 1);
  return boundaryAry;
}
function validateAndUpdateProps(props) {
  var ref = getSeparators(props);
  var thousandSeparator = ref.thousandSeparator;
  var decimalSeparator = ref.decimalSeparator;
  var prefix = props.prefix;
  if (prefix === void 0)
    prefix = "";
  var allowNegative = props.allowNegative;
  if (allowNegative === void 0)
    allowNegative = true;
  if (thousandSeparator === decimalSeparator) {
    throw new Error("\n        Decimal separator can't be same as thousand separator.\n        thousandSeparator: " + thousandSeparator + ' (thousandSeparator = {true} is same as thousandSeparator = ",")\n        decimalSeparator: ' + decimalSeparator + " (default value for decimalSeparator is .)\n     ");
  }
  if (prefix.startsWith("-") && allowNegative) {
    console.error("\n      Prefix can't start with '-' when allowNegative is true.\n      prefix: " + prefix + "\n      allowNegative: " + allowNegative + "\n    ");
    allowNegative = false;
  }
  return Object.assign(Object.assign({}, props), { allowNegative });
}
function useNumericFormat(props) {
  props = validateAndUpdateProps(props);
  var _decimalSeparator = props.decimalSeparator;
  var _allowedDecimalSeparators = props.allowedDecimalSeparators;
  var thousandsGroupStyle = props.thousandsGroupStyle;
  var suffix = props.suffix;
  var allowNegative = props.allowNegative;
  var allowLeadingZeros = props.allowLeadingZeros;
  var onKeyDown = props.onKeyDown;
  if (onKeyDown === void 0)
    onKeyDown = noop;
  var onBlur = props.onBlur;
  if (onBlur === void 0)
    onBlur = noop;
  var thousandSeparator = props.thousandSeparator;
  var decimalScale = props.decimalScale;
  var fixedDecimalScale = props.fixedDecimalScale;
  var prefix = props.prefix;
  if (prefix === void 0)
    prefix = "";
  var defaultValue = props.defaultValue;
  var value = props.value;
  var valueIsNumericString = props.valueIsNumericString;
  var onValueChange = props.onValueChange;
  var restProps = __rest(props, ["decimalSeparator", "allowedDecimalSeparators", "thousandsGroupStyle", "suffix", "allowNegative", "allowLeadingZeros", "onKeyDown", "onBlur", "thousandSeparator", "decimalScale", "fixedDecimalScale", "prefix", "defaultValue", "value", "valueIsNumericString", "onValueChange"]);
  var ref = getSeparators(props);
  var decimalSeparator = ref.decimalSeparator;
  var allowedDecimalSeparators = ref.allowedDecimalSeparators;
  var _format = function(numStr) {
    return format(numStr, props);
  };
  var _removeFormatting = function(inputValue, changeMeta) {
    return removeFormatting(inputValue, changeMeta, props);
  };
  var _value = isNil(value) ? defaultValue : value;
  var _valueIsNumericString = valueIsNumericString !== null && valueIsNumericString !== void 0 ? valueIsNumericString : isNumericString(_value, prefix, suffix);
  if (!isNil(value)) {
    _valueIsNumericString = _valueIsNumericString || typeof value === "number";
  } else if (!isNil(defaultValue)) {
    _valueIsNumericString = _valueIsNumericString || typeof defaultValue === "number";
  }
  var roundIncomingValueToPrecision = function(value2) {
    if (isNotValidValue(value2)) {
      return value2;
    }
    if (typeof value2 === "number") {
      value2 = toNumericString(value2);
    }
    if (_valueIsNumericString && typeof decimalScale === "number") {
      return roundToPrecision(value2, decimalScale, Boolean(fixedDecimalScale));
    }
    return value2;
  };
  var ref$1 = useInternalValues(roundIncomingValueToPrecision(value), roundIncomingValueToPrecision(defaultValue), Boolean(_valueIsNumericString), _format, _removeFormatting, onValueChange);
  var ref$1_0 = ref$1[0];
  var numAsString = ref$1_0.numAsString;
  var formattedValue = ref$1_0.formattedValue;
  var _onValueChange = ref$1[1];
  var _onKeyDown = function(e) {
    var el = e.target;
    var key = e.key;
    var selectionStart = el.selectionStart;
    var selectionEnd = el.selectionEnd;
    var value2 = el.value;
    if (value2 === void 0)
      value2 = "";
    if ((key === "Backspace" || key === "Delete") && selectionEnd < prefix.length) {
      e.preventDefault();
      return;
    }
    if (selectionStart !== selectionEnd) {
      onKeyDown(e);
      return;
    }
    if (key === "Backspace" && value2[0] === "-" && selectionStart === prefix.length + 1 && allowNegative) {
      setCaretPosition(el, 1);
    }
    if (decimalScale && fixedDecimalScale) {
      if (key === "Backspace" && value2[selectionStart - 1] === decimalSeparator) {
        setCaretPosition(el, selectionStart - 1);
        e.preventDefault();
      } else if (key === "Delete" && value2[selectionStart] === decimalSeparator) {
        e.preventDefault();
      }
    }
    if ((allowedDecimalSeparators === null || allowedDecimalSeparators === void 0 ? void 0 : allowedDecimalSeparators.includes(key)) && value2[selectionStart] === decimalSeparator) {
      setCaretPosition(el, selectionStart + 1);
    }
    var _thousandSeparator = thousandSeparator === true ? "," : thousandSeparator;
    if (key === "Backspace" && value2[selectionStart - 1] === _thousandSeparator) {
      setCaretPosition(el, selectionStart - 1);
    }
    if (key === "Delete" && value2[selectionStart] === _thousandSeparator) {
      setCaretPosition(el, selectionStart + 1);
    }
    onKeyDown(e);
  };
  var _onBlur = function(e) {
    var _value2 = numAsString;
    if (!_value2.match(/\d/g)) {
      _value2 = "";
    }
    if (!allowLeadingZeros) {
      _value2 = fixLeadingZero(_value2);
    }
    if (fixedDecimalScale && decimalScale) {
      _value2 = roundToPrecision(_value2, decimalScale, fixedDecimalScale);
    }
    if (_value2 !== numAsString) {
      var formattedValue2 = format(_value2, props);
      _onValueChange({
        formattedValue: formattedValue2,
        value: _value2,
        floatValue: parseFloat(_value2)
      }, {
        event: e,
        source: SourceType.event
      });
    }
    onBlur(e);
  };
  var isValidInputCharacter = function(inputChar) {
    if (inputChar === decimalSeparator) {
      return true;
    }
    return charIsNumber(inputChar);
  };
  var isCharacterSame = function(ref2) {
    var currentValue = ref2.currentValue;
    var lastValue = ref2.lastValue;
    var formattedValue2 = ref2.formattedValue;
    var currentValueIndex = ref2.currentValueIndex;
    var formattedValueIndex = ref2.formattedValueIndex;
    var curChar = currentValue[currentValueIndex];
    var newChar = formattedValue2[formattedValueIndex];
    var typedRange = findChangeRange(lastValue, currentValue);
    var to = typedRange.to;
    var getDecimalSeparatorIndex = function(value2) {
      return _removeFormatting(value2).indexOf(".") + prefix.length;
    };
    if (value === 0 && fixedDecimalScale && decimalScale && currentValue[to.start] === decimalSeparator && getDecimalSeparatorIndex(currentValue) < currentValueIndex && getDecimalSeparatorIndex(formattedValue2) > formattedValueIndex) {
      return false;
    }
    if (currentValueIndex >= to.start && currentValueIndex < to.end && allowedDecimalSeparators && allowedDecimalSeparators.includes(curChar) && newChar === decimalSeparator) {
      return true;
    }
    return curChar === newChar;
  };
  return Object.assign(Object.assign({}, restProps), {
    value: formattedValue,
    valueIsNumericString: false,
    isValidInputCharacter,
    isCharacterSame,
    onValueChange: _onValueChange,
    format: _format,
    removeFormatting: _removeFormatting,
    getCaretBoundary: function(formattedValue2) {
      return getCaretBoundary(formattedValue2, props);
    },
    onKeyDown: _onKeyDown,
    onBlur: _onBlur
  });
}
function NumericFormat(props) {
  var numericFormatProps = useNumericFormat(props);
  return import_react2.default.createElement(NumberFormatBase, Object.assign({}, numericFormatProps));
}

// node_modules/@glideapps/glide-data-grid/dist/esm/internal/data-grid-overlay-editor/private/number-overlay-editor.js
function getDecimalSeparator() {
  var _a, _b, _c;
  const numberWithDecimalSeparator = 1.1;
  const result = (_c = (_b = (_a = Intl.NumberFormat()) == null ? void 0 : _a.formatToParts(numberWithDecimalSeparator)) == null ? void 0 : _b.find((part) => part.type === "decimal")) == null ? void 0 : _c.value;
  return result != null ? result : ".";
}
function getThousandSeprator() {
  return getDecimalSeparator() === "." ? "," : ".";
}
var NumberOverlayEditor = (p) => {
  const { value, onChange, disabled, highlight, validatedSelection, fixedDecimals, allowNegative, thousandSeparator, decimalSeparator } = p;
  const inputRef = React2.useRef();
  React2.useLayoutEffect(() => {
    var _a;
    if (validatedSelection !== void 0) {
      const range = typeof validatedSelection === "number" ? [validatedSelection, null] : validatedSelection;
      (_a = inputRef.current) == null ? void 0 : _a.setSelectionRange(range[0], range[1]);
    }
  }, [validatedSelection]);
  return React2.createElement(
    NumberOverlayEditorStyle,
    null,
    React2.createElement(NumericFormat, {
      autoFocus: true,
      getInputRef: inputRef,
      className: "gdg-input",
      onFocus: (e) => e.target.setSelectionRange(highlight ? 0 : e.target.value.length, e.target.value.length),
      disabled: disabled === true,
      decimalScale: fixedDecimals,
      allowNegative,
      thousandSeparator: thousandSeparator != null ? thousandSeparator : getThousandSeprator(),
      decimalSeparator: decimalSeparator != null ? decimalSeparator : getDecimalSeparator(),
      value: Object.is(value, -0) ? "-" : value != null ? value : "",
      // decimalScale={3}
      // prefix={"$"}
      onValueChange: onChange
    })
  );
};
var number_overlay_editor_default = NumberOverlayEditor;
export {
  number_overlay_editor_default as default
};
//# sourceMappingURL=number-overlay-editor-D7HCWS2I.js.map
