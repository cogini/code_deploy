defmodule Mix.Tasks.CodeDeploy.Revision do
  @moduledoc """
  Create CodeDeploy revision files from release.

  ## Command line options

    * `--version` - selects a specific app version

  ## Usage

      # Creates revision from current release with MIX_ENV=dev (the default)
      mix code_deploy.revision

      # Builds a release with MIX_ENV=prod
      MIX_ENV=prod mix code_deploy.revision
  """
  @shortdoc "Create CodeDeploy revision files from release"
  use Mix.Task

  alias Mix.Releases.Shell

  @spec run(OptionParser.argv()) :: no_return
  def run(args) do
    # Parse options
    opts = parse_args(args)
    verbosity = Keyword.get(opts, :verbosity)
    Shell.configure(verbosity)

    # Mix.Task.run("release", [])

    Shell.debug("Loading configuration..")
    config = CodeDeploy.config()

    app_name = Mix.Project.config[:app] |> Atom.to_string
    version = opts[:version] || Mix.Project.config[:version]
    build_path = Mix.Project.build_path()

    tarball = Path.join([build_path, "rel", app_name, "releases", version, "#{app_name}.tar.gz"])

    unless File.exists?(tarball) do
      Shell.error("Missing release tarball: #{tarball}")
      System.halt(1)
    end

    Shell.info("Creating revison..")
    CodeDeploy.create_revision(config, tarball)
  end

  @doc false
  @spec parse_args(OptionParser.argv()) :: Keyword.t() | no_return
  # @spec parse_args(OptionParser.argv(), Keyword.t()) :: Keyword.t() | no_return
  def parse_args(argv) do
    switches = [
      silent: :boolean,
      quiet: :boolean,
      verbose: :boolean,
      version: :string,
    ]
    {args, _argv} = OptionParser.parse!(argv, strict: switches)

    defaults = %{
      verbosity: :normal,
    }

    args = Enum.reduce args, defaults, fn arg, config ->
      case arg do
        {:verbose, _} ->
          %{config | :verbosity => :verbose}
        {:quiet, _} ->
          %{config | :verbosity => :quiet}
        {:silent, _} ->
          %{config | :verbosity => :silent}
        {key, value} ->
          Map.put(config, key, value)
      end
    end

    Map.to_list(args)
  end

end
