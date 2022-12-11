defmodule Kino.MixProject do
  use Mix.Project

  @version "0.8.0"
  @description "Interactive widgets for Livebook"

  def project do
    [
      app: :kino,
      version: @version,
      description: @description,
      name: "Kino",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:table, "~> 0.1.2"},
      {:nx, "~> 0.1", optional: true},
      {:explorer, "~> 0.5.0-dev", github: "elixir-nx/explorer", optional: true},
      {:rustler, "~> 0.26.0", optional: true},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Kino",
      source_url: "https://github.com/livebook-dev/kino",
      source_ref: "v#{@version}",
      logo: "images/kino_without_text.png",
      groups_for_modules: [
        Kinos: [
          Kino.DataTable,
          Kino.Download,
          Kino.ETS,
          Kino.Frame,
          Kino.Image,
          Kino.Layout,
          Kino.Markdown,
          Kino.Mermaid,
          Kino.Process,
          Kino.Tree
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
          Kino.Output,
          Kino.Inspect
        ],
        Testing: [
          Kino.Test
        ]
      ]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/livebook-dev/kino"
      }
    ]
  end
end
