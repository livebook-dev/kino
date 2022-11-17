defmodule Kino.SmartCell.Server do
  @moduledoc false

  require Logger

  import Kino.Utils, only: [has_function?: 3]

  @chunk_joiner "\n\n"
  @chunk_joiner_size byte_size(@chunk_joiner)

  def start_link(module, ref, attrs, target_pid) do
    case :proc_lib.start_link(__MODULE__, :init, [module, ref, attrs, target_pid]) do
      {:error, error} ->
        {:error, error}

      {:ok, pid, source, chunks, init_opts} ->
        editor =
          if editor_opts = init_opts[:editor] do
            source = attrs[editor_opts[:attribute]] || editor_opts[:default_source]

            %{
              language: editor_opts[:language],
              placement: editor_opts[:placement],
              source: source
            }
          end

        {:ok, pid,
         %{
           source: source,
           chunks: chunks,
           js_view: %{
             ref: ref,
             pid: pid,
             assets: module.__assets_info__()
           },
           editor: editor,
           scan_binding: if(has_function?(module, :scan_binding, 3), do: &module.scan_binding/3),
           scan_eval_result:
             if(has_function?(module, :scan_eval_result, 2), do: &module.scan_eval_result/2)
         }}
    end
  end

  def init(module, ref, initial_attrs, target_pid) do
    {:ok, ctx, init_opts} = Kino.JS.Live.Server.call_init(module, initial_attrs, ref)
    init_opts = validate_init_opts!(init_opts)

    editor_source_attr = get_in(init_opts, [:editor, :attribute])
    reevaluate_on_change = Keyword.get(init_opts, :reevaluate_on_change, false)

    attrs = module.to_attrs(ctx)

    attrs =
      if editor_source_attr do
        source = initial_attrs[editor_source_attr] || init_opts[:editor][:default_source]
        Map.put(attrs, editor_source_attr, source)
      else
        attrs
      end

    {source, chunks} = to_source(module, attrs)

    :proc_lib.init_ack({:ok, self(), source, chunks, init_opts})

    state = %{
      module: module,
      ctx: ctx,
      target_pid: target_pid,
      attrs: attrs,
      editor_source_attr: editor_source_attr,
      reevaluate_on_change: reevaluate_on_change
    }

    :gen_server.enter_loop(__MODULE__, [], state)
  end

  defp validate_init_opts!(opts) do
    opts
    |> Keyword.validate!([:editor, :reevaluate_on_change])
    |> Keyword.update(:editor, nil, fn editor_opts ->
      editor_opts =
        Keyword.validate!(editor_opts, [
          :attribute,
          :language,
          placement: :bottom,
          default_source: ""
        ])

      unless Keyword.has_key?(editor_opts, :attribute) do
        raise ArgumentError, "missing editor option :attribute"
      end

      unless editor_opts[:placement] in [:top, :bottom] do
        raise ArgumentError,
              "editor :placement must be either :top or :bottom, got #{inspect(editor_opts[:placement])}"
      end

      editor_opts
    end)
  end

  def handle_info({:editor_source, source}, state) do
    attrs = Map.put(state.attrs, state.editor_source_attr, source)
    {:noreply, set_attrs(state, attrs)}
  end

  def handle_info(msg, state) do
    case Kino.JS.Live.Server.call_handle_info(msg, state.module, state.ctx) do
      {:ok, ctx} -> {:noreply, recompute_attrs(%{state | ctx: ctx})}
      :error -> {:noreply, state}
    end
  end

  def terminate(reason, state) do
    Kino.JS.Live.Server.call_terminate(reason, state.module, state.ctx)
  end

  defp recompute_attrs(state) do
    attrs = state.module.to_attrs(state.ctx)

    attrs =
      if state.editor_source_attr do
        Map.put(attrs, state.editor_source_attr, state.attrs[state.editor_source_attr])
      else
        attrs
      end

    set_attrs(state, attrs)
  end

  defp set_attrs(%{attrs: attrs} = state, attrs), do: state

  defp set_attrs(state, attrs) do
    {source, chunks} = to_source(state.module, attrs)

    send(
      state.target_pid,
      {:runtime_smart_cell_update, state.ctx.__private__.ref, attrs, source,
       %{chunks: chunks, reevaluate: state.reevaluate_on_change}}
    )

    %{state | attrs: attrs}
  end

  defp to_source(module, attrs) do
    case module.to_source(attrs) do
      sources when is_list(sources) ->
        {chunks, _} =
          Enum.map_reduce(sources, 0, fn source, offset ->
            size = byte_size(source)
            {{offset, size}, offset + size + @chunk_joiner_size}
          end)

        source = Enum.join(sources, @chunk_joiner)
        {source, chunks}

      source when is_binary(source) ->
        {source, nil}
    end
  end
end
