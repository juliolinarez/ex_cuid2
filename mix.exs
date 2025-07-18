defmodule ExCuid2.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cuid2,
      version: "0.9.2",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A robust implementation of Cuid2 for Elixir",
      package: [
        maintainers: ["Julio Linárez"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/juliolinarez/ex_cuid2"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExCuid2.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ecto_sql, ">= 3.6.0", optional: true}
    ]
  end
end
