defmodule Kino.MixProject do
  use Mix.Project

  @version "0.7.0"
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
          Kino.Process
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
