defmodule CodeDeploy do
  @moduledoc """
  Documentation for CodeDeploy.
  """
  @app :code_deploy
  @template_dir "code_deploy"

  @spec config() :: Keyword.t
  def config, do: config(Mix.Project.config())

  @spec config(Keyword.t) :: Keyword.t
  def config(project_config) do
    app = to_string(project_config[:app])
    version = project_config[:version]
    config = project_config[:code_deploy] || []

    # Vars used as defaults
    service_name = config[:service_name] || String.replace(app, "_", "-")
    app_user = config[:app_user] || service_name
    deploy_user = config[:deploy_user] || service_name

    http_listen_port = config[:http_listen_port] || 4000

    base_dir = "/srv/#{service_name}"
    release_dir = "#{base_dir}/current"

    defaults = [
      # Options
      # Enable conform config file
      conform: false,
      # Enable chroot
      chroot: false,
      # Enable extra restrictions
      paranoia: false,

      app: app,
      version: version,
      # systemd service name corresponding to app name
      # This is used to name the service files and directories
      service_name: service_name,
      # Output directory base
      build_path: Mix.Project.build_path(),
      # Target systemd version
      systemd_version: 235,

      # Base directory on target system
      base_dir: base_dir,
      # Directory where release will be extracted on target
      release_dir: release_dir,
      conform_conf_path: "/etc/#{service_name}/conform.conf",
      # Directory writable by app user, used for temp files, e.g. conform
      release_mutable_dir: "/run/#{service_name}",

      # OS user accounts
      app_user: app_user,
      app_group: app_user,
      deploy_user: deploy_user,
      deploy_group: deploy_user,

      mix_env: Mix.env(),
      env_lang: "en_US.UTF-8",
      env_port: http_listen_port,
      limit_nofile: 65535,
      umask: "0027",
      restart_sec: 5,

      runtime_directory: service_name,
      runtime_directory_mode: "750",
      runtime_directory_preserve: "no",
      configuration_directory: service_name,
      configuration_directory_mode: "750",
      logs_directory: service_name,
      logs_directory_mode: "750",
      state_directory: service_name,
      state_directory_mode: "750",

      # Chroot config
      root_directory: release_dir,
      read_write_paths: [],
      read_only_paths: [],
      inaccessible_paths: [],

      # CodeDeploy service validation options
      validate_hostname: "localhost",
      validate_port: http_listen_port,
      validate_attempts: 10,
      validate_curl_opts: "",
      validate_success_string: "200",
    ]

    Keyword.merge(defaults, config)

  end

  def template(name, params \\ []) do
    template_name = "#{name}.eex"
    override_path = Path.join([@template_dir, template_name])
    if File.exists?(override_path) do
      template_path(override_path)
    else
      Application.app_dir(@app, Path.join("priv", "templates"))
      |> Path.join(template_name)
      |> template_path(params)
    end
  end

  @spec template_path(String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, term}
  def template_path(template_path, params \\ []) do
    {:ok, EEx.eval_file(template_path, params, [trim: true])}
  rescue
    e ->
      {:error, {:template, e}}
  end

  @spec create_revision(Keyword.t, Path.t) :: :no_return
  def create_revision(config, tar_path) do
    base_path = Path.join(config[:build_path], "code_deploy")

    write_template(config, base_path, "appspec.yml")
    write_template(config, Path.join(base_path, "systemd/lib/systemd/system"), "systemd.service", "#{config[:service_name]}.service")
    write_template(config, Path.join(base_path, "code_deploy"), "application-stop.sh")
    write_template(config, Path.join(base_path, "code_deploy"), "before-install.sh")
    write_template(config, Path.join(base_path, "code_deploy"), "after-install.sh")
    write_template(config, Path.join(base_path, "code_deploy"), "application-start.sh")
    write_template(config, Path.join(base_path, "code_deploy"), "validate-service.sh")

    :ok = extract_tar(tar_path, Path.join(base_path, "release"))
  end

  @spec write_template(Keyword.t, Path.t, String.t) :: :ok
  def write_template(config, target_path, template) do
    :ok = File.mkdir_p(target_path)
    {:ok, data} = template(template, config)
    :ok = File.write(Path.join(target_path, template), data)
  end

  @spec write_template(Keyword.t, Path.t, String.t, Path.t) :: :ok
  def write_template(config, target_path, template, filename) do
    :ok = File.mkdir_p(target_path)
    {:ok, data} = template(template, config)
    :ok = File.write(Path.join(target_path, filename), data)
  end

  @spec extract_tar(Path.t, Path.t) :: :ok | {:error, term}
  def extract_tar(tar_path, dest_path) do
    :ok = File.mkdir_p(dest_path)
    :erl_tar.extract(String.to_charlist(tar_path), [{:cwd, String.to_charlist(dest_path)}, :compressed])
  end

end
