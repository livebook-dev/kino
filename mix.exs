defmodule LiveWidget.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_widget,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [VegaLite]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:vega_lite, "~> 0.1.0", only: [:dev, :test]}
    ]
  end
end
