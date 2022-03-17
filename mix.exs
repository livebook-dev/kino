defmodule Kino.MixProject do
  use Mix.Project

  @version "0.5.2"
  @description "Interactive widgets for Livebook"

  def project do
    [
      app: :kino,
      version: @version,
      description: @description,
      name: "Kino",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      xref: [exclude: [VegaLite, Ecto.Query, Ecto.Queryable, DBConnection]]
    ]
  end

  def application do
    [
      mod: {Kino.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:vega_lite, "~> 0.1.0", optional: true},
      {:ecto, "~> 3.0", optional: true},
      {:postgrex, "~> 0.16", optional: true},
      {:myxql, "~> 0.6", optional: true},
      {:db_connection, "~> 2.4.2", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Kino",
      source_url: "https://github.com/elixir-nx/kino",
      source_ref: "v#{@version}",
      logo: "images/kino_without_text.png",
      groups_for_modules: [
        Widgets: [
          Kino.DataTable,
          Kino.ETS,
          Kino.Ecto,
          Kino.Frame,
          Kino.Image,
          Kino.Markdown,
          Kino.VegaLite
        ],
        Inputs: [
          Kino.Input,
          Kino.Control
        ],
        Custom: [
          Kino.JS,
          Kino.JS.Live,
          Kino.JS.Live.Context,
          Kino.SmartCell
        ],
        Internal: [
          Kino.Render,
          Kino.Output
        ]
      ]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elixir-nx/kino"
      }
    ]
  end
end
