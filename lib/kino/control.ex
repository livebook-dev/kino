defmodule Kino.Control do
  @moduledoc """
  Various widgets for user interactions.

  Each widget is a UI control element that the user interacts
  with, consequently producing an event stream.

  Those widgets are often useful paired with `Kino.Frame` for
  presenting content that changes upon user interactions.

  ## Examples

  First, create a control and make sure it is rendered,
  either by placing it at the end of a code cell or by
  explicitly rendering it with `Kino.render/1`.

      button = Kino.Control.button("Hello")

  Next, to receive events from the control, a process needs to
  subscribe to it and specify pick a name to distinguish the
  events.

      Kino.Control.subscribe(button, :hello)

  As the user interacts with the button, the subscribed process
  receives corresponding events.

      IEx.Helpers.flush()
      #=> {:hello, %{origin: "client1"}}
      #=> {:hello, %{origin: "client1"}}
  """

  defstruct [:attrs]

  @opaque t :: %__MODULE__{attrs: Kino.Output.control_attrs()}

  @opaque interval :: {:interval, milliseconds :: non_neg_integer()}

  @type event_source :: t() | Kino.Input.t() | interval()

  defp new(attrs) do
    ref = Kino.Output.random_ref()
    subscription_manager = Kino.SubscriptionManager.cross_node_name()

    attrs = Map.merge(attrs, %{ref: ref, destination: subscription_manager})

    Kino.Bridge.reference_object(ref, self())
    Kino.Bridge.monitor_object(ref, subscription_manager, {:clear_topic, ref})

    %__MODULE__{attrs: attrs}
  end

  @doc """
  Creates a new button.
  """
  @spec button(String.t()) :: t()
  def button(label) when is_binary(label) do
    new(%{type: :button, label: label})
  end

  @doc """
  Creates a new keyboard control.

  This widget is represented as button that toggles interception
  mode, in which the given keyboard events are captured.

  ## Event info

  In addition to standard properties, all events include additional
  properties.

  ### Key events

    * `:type` - either `:keyup` or `:keydown`

    * `:key` - the value matching the browser [KeyboardEvent.key](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)

  ### Status event

    * `:type` - either `:status`

    * `:enabled` - whether the keyboard is activated

  ## Examples

  Create the widget:

      keyboard = Kino.Control.keyboard([:keyup, :keydown, :status])

  Subscribe to events:

      Kino.Control.subscribe(keyboard, :keyboard)

  As the user types events are streamed:

      IEx.Helpers.flush()
      #=> {:keyboard, %{enabled: true, origin: "client1", type: :status}
      #=> {:keyboard, %{key: "o", origin: "client1", type: :keydown}}
      #=> {:keyboard, %{key: "k", origin: "client1", type: :keydown}}
      #=> {:keyboard, %{key: "o", origin: "client1", type: :keyup}}
      #=> {:keyboard, %{key: "k", origin: "client1", type: :keyup}}
  """
  @spec keyboard(list(:keyup | :keydown | :status)) :: t()
  def keyboard(events) when is_list(events) do
    if events == [] do
      raise ArgumentError, "expected at least one event, got: []"
    end

    for event <- events do
      unless event in [:keyup, :keydown, :status] do
        raise ArgumentError,
              "expected event to be either :keyup, :keydown or :status, got: #{inspect(event)}"
      end
    end

    new(%{type: :keyboard, events: events})
  end

  @doc """
  Creates a new form.

  A form is composed of regular inputs from the `Kino.Input` module,
  however in a form input values are not synchronized between users.
  Consequently, the form is another control for producing user-specific
  events.

  Either `:submit` or `:report_changes` must be specified.

  ## Options

    * `:submit` - specifies the label to use for the submit button
      and enables submit events

    * `:report_changes` - whether to send new form value whenever any
      of the input changes. Defaults to `false`

    * `:reset_on_submit` - a list of fields to revert to their default
      values once the form is submitted. Use `true` to indicate all
      fields. Defaults to `[]`

  ## Event info

  In addition to standard properties, all events include additional
  properties.

    * `:type` - either `:submit` or `:change`

    * `:data` - a map with field values, matching the field list

  ## Examples

  Create a form out of inputs:

      form =
        Kino.Control.form(
          [
            name: Kino.Input.text("Name"),
            message: Kino.Input.textarea("Message")
          ],
          submit: "Send"
        )

  Subscribe to events:

      Kino.Control.subscribe(form, :chat_form)

  As users submit the form the payload is sent:

      IEx.Helpers.flush()
      #=> {:chat_form,
      #=>   %{
      #=>     data: %{message: "Hola", name: "Amy"},
      #=>     origin: "client1",
      #=>     type: :submit
      #=>   }}
      #=> {:chat_form,
      #=>   %{
      #=>     data: %{message: "Hey!", name: "Jake"},
      #=>     origin: "client2",
      #=>     type: :submit
      #=>   }}
  """
  @spec form(list({atom(), Kino.Input.t()}), keyword()) :: t()
  def form(fields, opts \\ []) when is_list(fields) do
    if fields == [] do
      raise ArgumentError, "expected at least one field, got: []"
    end

    for {field, input} <- fields do
      unless is_atom(field) do
        raise ArgumentError,
              "expected each field key to be an atom, got: #{inspect(field)}"
      end

      unless is_struct(input, Kino.Input) do
        raise ArgumentError,
              "expected each field to be a Kino.Input widget, got: #{inspect(input)} for #{inspect(field)}"
      end
    end

    unless opts[:submit] || opts[:report_changes] do
      raise ArgumentError, "expected either :submit or :report_changes option to be enabled"
    end

    fields =
      Enum.map(fields, fn {field, input} ->
        # Make sure we use this input only in the form and nowhere else
        input = Kino.Input.duplicate(input)
        {field, input.attrs}
      end)

    submit = Keyword.get(opts, :submit, nil)

    report_changes =
      if Keyword.get(opts, :report_changes, false) do
        Map.new(fields, fn {field, _} -> {field, true} end)
      else
        %{}
      end

    reset_on_submit =
      case Keyword.get(opts, :reset_on_submit, []) do
        true -> Keyword.keys(fields)
        false -> []
        fields -> fields
      end

    new(%{
      type: :form,
      fields: fields,
      submit: submit,
      report_changes: report_changes,
      reset_on_submit: reset_on_submit
    })
  end

  @doc """
  Subscribes the calling process to control or input events.

  This is an alternative API to `stream/1`, such that event
  messages are consumed via process messages instead of streams.

  The events are sent as `{tag, info}`, where info is a map with
  event details. In particular, it always includes `:origin`, which
  is an opaque identifier of the client that triggered the event.
  """
  @spec subscribe(t() | Kino.Input.t(), term()) :: :ok
  def subscribe(source, tag)
      when is_struct(source, Kino.Control) or is_struct(source, Kino.Input) do
    Kino.SubscriptionManager.subscribe(source.attrs.ref, self(), tag)
  end

  @doc """
  Unsubscribes the calling process from control or input events.
  """
  @spec unsubscribe(t() | Kino.Input.t()) :: :ok
  def unsubscribe(source)
      when is_struct(source, Kino.Control) or is_struct(source, Kino.Input) do
    Kino.SubscriptionManager.unsubscribe(source.attrs.ref, self())
  end

  @doc """
  Returns a new interval event source.

  This can be used as event source for `stream/1` and `tagged_stream/1`.
  The events are emitted periodically with an increasing value, starting
  from 0 and have the form:

      %{type: :interval, iteration: non_neg_integer()}
  """
  @spec interval(non_neg_integer()) :: interval()
  def interval(milliseconds) when is_number(milliseconds) and milliseconds > 0 do
    {:interval, milliseconds}
  end

  @doc """
  Returns a `stream` of control events.

  It accepts a single source or a list of sources, where each
  source is either of:

    * `Kino.Control` - emitting value on relevant interaction

    * `Kino.Input` - emitting value on value change

  You can then consume the stream to access its events.

  ## Example

      button = Kino.Control.button("Hello")

      for event <- Kino.Control.stream(button) do
        IO.inspect(event)
      end
      #=> %{origin: "client1", type: :click}
      #=> %{origin: "client1", type: :click}

  Or with multiple sources:

      button = Kino.Control.button("Hello")
      input = Kino.Input.checkbox("Check")
      interval = Kino.Control.interval(1000)

      for event <- Kino.Control.stream([button, input, interval]) do
        IO.inspect(event)
      end
      #=> %{type: :interval, iteration: 0}
      #=> %{origin: "client1", type: :click}
      #=> %{origin: "client1", type: :change, value: true}
  """
  @spec stream(event_source() | list(event_source())) :: Enumerable.t()
  def stream(source)

  def stream(sources) when is_list(sources) do
    for source <- sources, do: assert_stream_source!(source)

    tagged_topics = for %{attrs: %{ref: ref}} <- sources, do: {nil, ref}
    tagged_intervals = for {:interval, ms} <- sources, do: {nil, ms}

    build_stream(tagged_topics, tagged_intervals, fn nil, event -> event end)
  end

  def stream(source) do
    stream([source])
  end

  # TODO: remove on Kino v0.8
  @deprecated "Use Kino.Control.stream/1 and Kino.listen/2 instead"
  def stream(source, fun) when is_function(fun, 1) do
    source
    |> stream()
    |> Kino.listen(fun)
  end

  # TODO: remove on Kino v0.8
  @deprecated "Use Kino.Control.stream/1 and Kino.listen/3 instead"
  def stream(source, state, fun) when is_function(fun, 2) do
    source
    |> stream()
    |> Kino.listen(state, fn event, state ->
      {:cont, fun.(event, state)}
    end)
  end

  @doc """
  Same as `stream/1`, but attaches custom tag to every stream item.

  ## Example

      button = Kino.Control.button("Hello")
      input = Kino.Input.checkbox("Check")

      for event <- Kino.Control.tagged_stream([hello: button, check: input]) do
        IO.inspect(event)
      end
      #=> {:hello, %{origin: "client1", type: :click}}
      #=> {:check, %{origin: "client1", type: :change, value: true}}
  """
  @spec tagged_stream(list({atom(), event_source()})) :: Enumerable.t()
  def tagged_stream(entries) when is_list(entries) do
    for entry <- entries do
      case entry do
        {tag, source} when is_atom(tag) ->
          assert_stream_source!(source)

        _other ->
          raise ArgumentError, "expected a keyword list, got: #{inspect(entries)}"
      end
    end

    tagged_topics = for {tag, %{attrs: %{ref: ref}}} <- entries, do: {tag, ref}
    tagged_intervals = for {tag, {:interval, ms}} <- entries, do: {tag, ms}

    build_stream(tagged_topics, tagged_intervals, fn tag, event -> {tag, event} end)
  end

  # TODO: remove on Kino v0.8
  @deprecated "Use Kino.Control.tagged_stream/1 and Kino.listen/2 instead"
  def tagged_stream(entries, fun) when is_list(entries) and is_function(fun, 1) do
    entries
    |> tagged_stream()
    |> Kino.listen(fun)
  end

  # TODO: remove on Kino v0.8
  @deprecated "Use Kino.Control.tagged_stream/1 and Kino.listen/3 instead"
  def tagged_stream(entries, state, fun) when is_list(entries) and is_function(fun, 2) do
    entries
    |> tagged_stream()
    |> Kino.listen(state, fn event, state ->
      {:cont, fun.(event, state)}
    end)
  end

  defp assert_stream_source!(%Kino.Control{}), do: :ok
  defp assert_stream_source!(%Kino.Input{}), do: :ok
  defp assert_stream_source!({:interval, ms}) when is_number(ms) and ms > 0, do: :ok

  defp assert_stream_source!(item) do
    raise ArgumentError,
          "expected source to be either %Kino.Control{}, %Kino.Input{} or {:interval, ms}, got: #{inspect(item)}"
  end

  defp build_stream(tagged_topics, tagged_intervals, mapper) do
    Stream.resource(
      fn ->
        ref = make_ref()

        for {tag, topic} <- tagged_topics do
          Kino.SubscriptionManager.subscribe(topic, self(), {ref, tag}, notify_clear: true)
        end

        for {tag, ms} <- tagged_intervals do
          Process.send_after(self(), {{ref, tag}, :__interval__, ms, 0}, ms)
        end

        topics = Enum.map(tagged_topics, &elem(&1, 1))

        {ref, topics}
      end,
      fn {ref, topics} ->
        receive do
          {{^ref, tag}, event} ->
            {[mapper.(tag, event)], {ref, topics}}

          {{^ref, _tag}, :topic_cleared, topic} ->
            case topics -- [topic] do
              [] -> {:halt, {ref, []}}
              topics -> {[], {ref, topics}}
            end

          {{^ref, tag}, :__interval__, ms, i} ->
            Process.send_after(self(), {{ref, tag}, :__interval__, ms, i + 1}, ms)
            event = %{type: :interval, iteration: i}
            {[mapper.(tag, event)], {ref, topics}}
        end
      end,
      fn {_ref, topics} ->
        for topic <- topics do
          Kino.SubscriptionManager.unsubscribe(topic, self())
        end
      end
    )
  end
end
