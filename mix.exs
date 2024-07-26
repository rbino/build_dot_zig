defmodule BuildDotZig.MixProject do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :build_dot_zig,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "A build.zig compiler for Mix",
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:ssl, :inets, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/rbino/build_dot_zig"},
      maintainers: ["Riccardo Binetti"]
    ]
  end

  defp docs do
    [
      main: "Mix.Tasks.Compile.BuildDotZig",
      extras: ["CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/rbino/build_dot_zig"
    ]
  end
end
