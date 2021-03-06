defmodule CodeDeploy.MixProject do
  use Mix.Project

  def project do
    [
      app: :code_deploy,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      code_deploy: code_deploy()
    ]
  end

  def code_deploy do
    [
      conform: true,
      chroot: true,
      paranoia: true,
      deploy_user: "deploy",
      # validate_curl_opts: "--insecure -H 'X-Forwarded-Proto: https'",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
