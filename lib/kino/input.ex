defmodule Kino.Input do
  @moduledoc """
  Various input elements for entering data.

  ## Examples

  First, create an input and make sure it is rendered,
  either by placing it at the end of a code cell or by
  explicitly rendering it with `Kino.render/1`.

      input = Kino.Input.text("Name")

  Then read the value at any later point:

      name = Kino.Input.read(input)

  ## Async API

  You can subscribe to input changes or use the `Stream`
  API for event feed. See the `Kino.Control` module for
  more details.
  """

  defstruct [:attrs]

  @opaque t :: %__MODULE__{attrs: Kino.Output.input_attrs()}

  defp new(attrs) do
    token = Kino.Bridge.generate_token()
    persistent_id = {token, attrs} |> :erlang.phash2() |> Integer.to_string()

    ref = Kino.Output.random_ref()
    subscription_manager = Kino.SubscriptionManager.cross_node_name()

    attrs =
      Map.merge(attrs, %{
        ref: ref,
        id: persistent_id,
        destination: subscription_manager
      })

    Kino.Bridge.reference_object(ref, self())
    Kino.Bridge.monitor_object(ref, subscription_manager, {:clear_topic, ref})

    %__MODULE__{attrs: attrs}
  end

  @doc false
  def duplicate(input) do
    input.attrs
    |> Map.drop([:ref, :id, :destination])
    |> new()
  end

  @doc """
  Creates a new text input.

  ## Options

    * `:default` - the initial input value. Defaults to `""`
  """
  @spec text(String.t(), keyword()) :: t()
  def text(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = opts |> Keyword.get(:default, "") |> to_string()
    new(%{type: :text, label: label, default: default})
  end

  @doc """
  Creates a new multiline text input.

  ## Options

    * `:default` - the initial input value. Defaults to `""`
  """
  @spec textarea(String.t(), keyword()) :: t()
  def textarea(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = opts |> Keyword.get(:default, "") |> to_string()
    new(%{type: :textarea, label: label, default: default})
  end

  @doc """
  Creates a new password input.

  This is similar to text input, except the content is not
  visible by default.

  ## Options

    * `:default` - the initial input value. Defaults to `""`
  """
  @spec password(String.t(), keyword()) :: t()
  def password(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = opts |> Keyword.get(:default, "") |> to_string()
    new(%{type: :password, label: label, default: default})
  end

  @doc """
  Creates a new number input.

  The input value is can be either a number or `nil`.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`
  """
  @spec number(String.t(), keyword()) :: t()
  def number(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = Keyword.get(opts, :default, nil)

    assert_default_value!(default, "be either number or nil", fn value ->
      is_nil(value) or is_number(value)
    end)

    new(%{type: :number, label: label, default: default})
  end

  defp assert_default_value!(value, message, check) do
    unless check.(value) do
      raise ArgumentError, "expected :default to #{message}, got: #{inspect(value)}"
    end
  end

  @doc """
  Creates a new URL input.

  The input value can be either a valid URL string or `nil`.

  ## Options

    * `:default` - the initial input value. Defaults to `nil`
  """
  @spec url(String.t(), keyword()) :: t()
  def url(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = Keyword.get(opts, :default, nil)

    assert_default_value!(default, "be either string or nil", fn value ->
      is_nil(value) or is_binary(value)
    end)

    new(%{type: :url, label: label, default: default})
  end

  @doc """
  Creates a new select input.

  The input expects a list of options in the form `[{value, label}]`,
  where `value` is an arbitrary term and `label` is a descriptive
  string.

  ## Options

    * `:default` - the initial input value. Defaults to the first
      value from the given list of options

  ## Examples

      Kino.Input.select("Language", [en: "English", fr: "Français"])

      Kino.Input.select("Language", [{1, "One"}, {2, "Two"}, {3, "Three"}])
  """
  @spec select(String.t(), list({value :: term(), label :: String.t()}), keyword()) :: t()
  def select(label, options, opts \\ [])
      when is_binary(label) and is_list(options) and is_list(opts) do
    if options == [] do
      raise ArgumentError, "expected at least one option, got: []"
    end

    options = Enum.map(options, fn {key, val} -> {key, to_string(val)} end)
    values = Enum.map(options, &elem(&1, 0))
    default = Keyword.get_lazy(opts, :default, fn -> hd(values) end)

    if default not in values do
      raise ArgumentError,
            "expected :default to be either of #{Enum.map_join(values, ", ", &inspect/1)}, got: #{inspect(default)}"
    end

    new(%{type: :select, label: label, options: options, default: default})
  end

  @doc """
  Creates a new checkbox.

  The input value can be either `true` or `false`.

  ## Options

    * `:default` - the initial input value. Defaults to `false`
  """
  @spec checkbox(String.t(), keyword()) :: t()
  def checkbox(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = Keyword.get(opts, :default, false)
    assert_default_value!(default, "be a boolean", &is_boolean/1)
    new(%{type: :checkbox, label: label, default: default})
  end

  @doc """
  Creates a new slider input.

  The input value can be either float in the configured range.

  ## Options

    * `:default` - the initial input value. Defaults to the
      minimum value

    * `:min` - the minimum value

    * `:max` - the maximum value

    * `:step` - the slider increment
  """
  @spec range(String.t(), keyword()) :: t()
  def range(label, opts \\ []) when is_binary(label) and is_list(opts) do
    min = Keyword.get(opts, :min, 0)
    max = Keyword.get(opts, :max, 100)
    step = Keyword.get(opts, :step, 1)
    default = Keyword.get(opts, :default, min)

    if min >= max do
      raise ArgumentError,
            "expected :min to be less than :max, got: #{inspect(min)} and #{inspect(max)}"
    end

    if step <= 0 do
      raise ArgumentError, "expected :step to be positive, got: #{inspect(step)}"
    end

    assert_default_value!(default, "be a number", &is_number/1)

    if default < min or default > max do
      raise ArgumentError,
            "expected :default to be between :min and :max, got: #{inspect(default)}"
    end

    new(%{
      type: :range,
      label: label,
      default: default,
      min: min,
      max: max,
      step: step
    })
  end

  @doc """
  Creates a new color input.

  The input value can be a hex color string.

  ## Options

    * `:default` - the initial input value. Defaults to `#6583FF`
  """
  @spec color(String.t(), keyword()) :: t()
  def color(label, opts \\ []) when is_binary(label) and is_list(opts) do
    default = Keyword.get(opts, :default, "#6583FF")
    assert_default_value!(default, "be a string", &is_binary/1)
    new(%{type: :color, label: label, default: default})
  end

  @doc """
  Synchronously reads the current input value.

  Note that to retrieve the value, the input must be rendered first,
  otherwise an error is raised.

  ## Examples

      input = Kino.Input.text("Name")

      Kino.Input.read(input)
  """
  @spec read(t()) :: term()
  def read(%Kino.Input{} = input) do
    case Kino.Bridge.get_input_value(input.attrs.id) do
      {:ok, value} ->
        value

      {:error, reason} ->
        raise "failed to read input value, reason: #{inspect(reason)}"
    end
  end
end
