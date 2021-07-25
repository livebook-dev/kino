defmodule Kino.MixProject do
  use Mix.Project

  @version "0.2.2"
  @description "Interactive widgets for Livebook"

  def project do
    [
      app: :kino,
      version: @version,
      description: @description,
      name: "Kino",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      xref: [exclude: [VegaLite, Ecto.Query, Ecto.Queryable]]
    ]
  end

  def application do
    [
      mod: {Kino.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:vega_lite, "~> 0.1.0", optional: true},
      {:ecto, "~> 3.0", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Kino",
      source_url: "https://github.com/elixir-nx/kino",
      source_ref: "v#{@version}",
      logo: "images/kino_without_text.png"
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
