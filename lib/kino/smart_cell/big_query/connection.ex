defmodule Kino.SmartCell.BigQuery.Connection do
  @moduledoc false
  use GenServer

  alias GoogleApi.BigQuery.V2.Api.Jobs
  alias GoogleApi.BigQuery.V2.Connection
  alias GoogleApi.BigQuery.V2.Model.DatasetReference
  alias GoogleApi.BigQuery.V2.Model.QueryRequest

  @goth Kino.SmartCell.BigQuery.Goth

  @scopes ["https://www.googleapis.com/auth/cloud-platform"]

  @impl true
  def init(opts) do
    with {:ok, _pid} <- start_goth(opts),
         {:ok, token} <- get_token() do
      conn = Connection.new(token)
      {:ok, %{opts: opts, conn: conn}}
    end
  end

  defp start_goth(opts) do
    Goth.start_link(
      name: @goth,
      source: {:service_account, credentials(opts), [scopes: @scopes]}
    )
  end

  defp credentials(opts) do
    %{
      "type" => "service_account",
      "project_id" => opts[:project_id],
      "private_key_id" => opts[:private_key_id],
      "private_key" => private_key(opts[:private_key]),
      "client_email" => opts[:client_email],
      "client_id" => opts[:client_id],
      "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
      "token_uri" => "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url" => opts[:client_x509_cert_url]
    }
  end

  defp private_key(private_key) do
    String.replace(private_key, "\\n", "\n")
  end

  defp get_token do
    with {:ok, %{token: token}} <- Goth.fetch(@goth) do
      {:ok, token}
    end
  end

  @doc """
  Starts the BigQuery connection as a child
  """
  def child_spec(opts) do
    %{
      id: String.to_atom(opts[:project_id]),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc """
  Starts a new BigQuery connection
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Executes the query into the current BigQuery connection.
  """
  def exec_query!(query) do
    GenServer.call(__MODULE__, {:exec_query!, query})
  end

  ## GenServer Callbacks

  @impl true
  def handle_call({:exec_query!, query}, _from, %{conn: conn, opts: opts} = state) do
    query_req = prepare(query, opts)
    {:ok, response} = Jobs.bigquery_jobs_query(conn, opts[:project_id], body: query_req)

    {:reply, prepare_rows(response), state}
  end

  defp prepare(sql, opts) do
    dataset_ref =
      struct!(DatasetReference,
        datasetId: opts[:dataset],
        projectId: opts[:project_id]
      )

    struct!(QueryRequest, defaultDataset: dataset_ref, query: sql)
  end

  defp prepare_rows(%{rows: rows, schema: %{fields: fields}}) do
    Enum.map(rows, &build_row_map(&1.f, fields))
  end

  defp build_row_map(row, fields) do
    row
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {%{v: value}, index}, acc ->
      field = Enum.at(fields, index)
      key = String.to_atom(field.name)
      type = field.type

      Map.put_new(acc, key, convert_value(type, value))
    end)
  end

  defp convert_value("BOOLEAN", value), do: String.downcase(value) == "true"
  defp convert_value("INTEGER", value), do: String.to_integer(value)
  defp convert_value("FLOAT", value), do: String.to_float(value)
  defp convert_value(_, value), do: value
end
