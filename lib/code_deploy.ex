defmodule CodeDeploy do
  @moduledoc """
  Documentation for CodeDeploy.
  """
  @app :code_deploy

  def config do
    config(Mix.Project.config())
  end

  def config(project_config) do
    app = to_string(project_config[:app])
    config = project_config[:systemd] || []
    config = [app: app] ++ config
    service_name = config[:service_name] || String.replace(app, "_", "-")
    app_user = config[:app_user] || app

    [
      app: app,
      service_name: service_name,
      app_user: app_user,
      app_group: config[:app_group] || app_user,
      project: config[:project],
      deploy_dir: config[:deploy_dir] || deploy_dir(config),
      mix_env: config[:mix_env] || Mix.env(),
      release_mutable_dir: config[:release_mutable_dir] || "/run/#{service_name}",
      env_lang: config[:env_lang] || "en_US.UTF-8",
      env_port: config[:env_port] || 4000,
      conform_conf_path: config[:conform_conf_path],
      limit_nofile: config[:limit_nofile] || 65535,
      umask: config[:umask] || "0027",
      restart_sec: config[:restart_sec] || 5,
      runtime_directory: config[:runtime_directory] || service_name,
      runtime_directory_mode: config[:runtime_directory_mode] || "0750",
      runtime_directory_preserve: config[:runtime_directory_preserve] || "no",
      configuration_directory: config[:configuration_directory] || service_name,
      configuration_directory_mode: config[:configuration_directory_mode] || "0750",
      logs_directory: config[:logs_directory] || service_name,
      logs_directory_mode: config[:logs_directory_mode] || "0750",
      state_directory: config[:state_directory] || service_name,
      state_directory_mode: config[:state_directory_mode] || "0750",
      chroot: config[:chroot],
      root_directory: config[:root_directory],
      read_write_paths: config[:read_write_paths] || [],
      read_only_paths: config[:read_only_paths] || [],
      inaccessible_paths: config[:inaccessible_paths] || [],
      systemd_version: config[:systemd_version] || 235,
      paranoia: config[:paranoia],
    ]

  end

  def template(name, params \\ []) do
    Application.app_dir(@app, Path.join("priv", "templates"))
    |> Path.join("#{name}.eex")
    |> template_path(params)
  end

  @spec template_path(String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, term}
  def template_path(template_path, params \\ []) do
    {:ok, EEx.eval_file(template_path, params, [trim: true])}
  rescue
    e ->
      {:error, {:template, e}}
  end

  def deploy_dir(config) do
    app = config[:app]
    service_name = config[:service_name] || String.replace(app, "_", "-")
    base_dir = config[:base_dir] || "/srv"
    case Keyword.fetch(config, :project) do
      {:ok, project} ->
        Path.join([base_dir, project, service_name])
      :error ->
        Path.join([base_dir, service_name])
      end
  end

end
