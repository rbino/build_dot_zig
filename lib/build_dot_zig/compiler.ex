defmodule BuildDotZig.Compiler do
  alias BuildDotZig.ZigInstaller

  @latest_stable_zig "0.10.1"

  def compile do
    config = Mix.Project.config()
    Mix.shell().print_app()
    priv? = File.dir?("priv")
    Mix.Project.ensure_structure()
    build(config)

    # IF there was no priv before and now there is one, we assume
    # the user wants to copy it. If priv already existed and was
    # written to it, then it won't be copied if build_embedded is
    # set to true.
    if not priv? and File.dir?("priv") do
      Mix.Project.build_structure()
    end

    {:ok, []}
  end

  def clean do
    # Remove the zig cache
    Mix.Project.config()
    |> Mix.Project.build_path()
    |> cache_dir()
    |> File.rm_rf!()
  end

  def build(config) do
    downloaded_zig_install_dir =
      Keyword.get(config, :install_zig, true)
      |> zig_download_version()
      |> ensure_downloaded_zig!()

    downloaded_zig_exec = downloaded_zig_exec(downloaded_zig_install_dir)

    explicit_exec = Keyword.get(config, :zig_executable, :default)
    exec = exec(explicit_exec, downloaded_zig_exec)

    app_path = Mix.Project.app_path(config)
    mix_target = Mix.target()
    install_prefix = "#{app_path}/priv/#{mix_target}"
    build_path = Mix.Project.build_path(config)
    build_mode = Keyword.get(config, :zig_build_mode, :debug)
    target = Keyword.get(config, :zig_target, :host)
    cpu = Keyword.get(config, :zig_cpu, :native)
    args = build_args(install_prefix, build_path, build_mode, target, cpu)

    env =
      default_env(config)
      |> maybe_add_zig_install_dir(downloaded_zig_install_dir)

    case cmd(exec, args, env) do
      0 ->
        :ok

      exit_status ->
        raise_build_error(exec, exit_status)
    end
  end

  # Runs `zig build` and prints the stdout and stderr in real time,
  # as soon as `exec` prints them (using `IO.Stream`).
  defp cmd(exec, args, env) do
    opts = [
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true,
      env: env
    ]

    {%IO.Stream{}, status} = System.cmd(exec, args, opts)
    status
  end

  defp raise_build_error(exec, exit_status) do
    Mix.raise("Could not compile with #{exec} (exit status: #{exit_status}).\n")
  end

  defp zig_install_prefix do
    :code.priv_dir(:build_dot_zig) |> to_string()
  end

  defp zig_download_version(_install = false), do: nil
  defp zig_download_version(_install = true), do: @latest_stable_zig
  defp zig_download_version(version) when is_binary(version), do: version

  defp exec(explicit_exec, _downloaded_zig_exec) when is_binary(explicit_exec) do
    explicit_exec
    |> Path.expand()
    |> System.find_executable() ||
      Mix.raise("""
      "#{explicit_exec}" not found in the path. If you have set the :zig_executable \
      variable, please make sure it is correct.
      """)
  end

  defp exec(:default, :not_downloaded = _downloaded_zig_exec) do
    System.find_executable("zig") ||
      Mix.raise("""
      "zig not found in the path. If you set :install_zig to false, you have \
      to manully install zig in your system and add it to the PATH.
      """)
  end

  defp exec(:default, downloaded_zig_exec) when is_binary(downloaded_zig_exec) do
    downloaded_zig_exec
  end

  defp build_args(install_prefix, build_path, build_mode, target, cpu) do
    ["build"] ++
      install_prefix_args(install_prefix) ++
      cache_dir_args(build_path) ++
      build_mode_args(build_mode) ++ target_args(target) ++ cpu_args(cpu)
  end

  defp install_prefix_args(install_prefix) do
    ["-p", install_prefix]
  end

  defp cache_dir_args(build_path) do
    ["--cache-dir", cache_dir(build_path)]
  end

  defp build_mode_args(build_mode) do
    case build_mode do
      :debug ->
        []

      :release_safe ->
        ["-Drelease-safe"]

      :release_fast ->
        ["-Drelease-fast"]

      :release_small ->
        ["-Drelease-small"]

      other ->
        Mix.raise(
          "Invalid build mode #{inspect(other)} in :zig_build_mode. " <>
            "Should be one of: :debug, :release_safe, :release_fast, :release_small."
        )
    end
  end

  defp cache_dir(build_path) do
    Path.join(build_path, "zig-cache")
  end

  defp target_args(:host) do
    []
  end

  defp target_args(target) when is_binary(target) do
    ["-Dtarget=#{target}"]
  end

  defp cpu_args(:native) do
    []
  end

  defp cpu_args(cpu) when is_binary(cpu) do
    ["-Dcpu=#{cpu}"]
  end

  # Returns a map of default environment variables
  # Defaults may be overwritten.
  defp default_env(config) do
    root_dir = :code.root_dir()
    erl_interface_dir = Path.join(root_dir, "usr")
    erts_dir = Path.join(root_dir, "erts-#{:erlang.system_info(:version)}")
    erts_include_dir = Path.join(erts_dir, "include")
    erl_ei_lib_dir = Path.join(erl_interface_dir, "lib")
    erl_ei_include_dir = Path.join(erl_interface_dir, "include")

    %{
      # Don't use Mix.target/0 here for backwards compatibility
      "MIX_TARGET" => env("MIX_TARGET", "host"),
      "MIX_ENV" => to_string(Mix.env()),
      "MIX_BUILD_PATH" => Mix.Project.build_path(config),
      "MIX_APP_PATH" => Mix.Project.app_path(config),
      "MIX_COMPILE_PATH" => Mix.Project.compile_path(config),
      "MIX_CONSOLIDATION_PATH" => Mix.Project.consolidation_path(config),
      "MIX_DEPS_PATH" => Mix.Project.deps_path(config),
      "MIX_MANIFEST_PATH" => Mix.Project.manifest_path(config),

      # Rebar naming
      "ERL_EI_LIBDIR" => env("ERL_EI_LIBDIR", erl_ei_lib_dir),
      "ERL_EI_INCLUDE_DIR" => env("ERL_EI_INCLUDE_DIR", erl_ei_include_dir),

      # erlang.mk naming
      "ERTS_INCLUDE_DIR" => env("ERTS_INCLUDE_DIR", erts_include_dir),
      "ERL_INTERFACE_LIB_DIR" => env("ERL_INTERFACE_LIB_DIR", erl_ei_lib_dir),
      "ERL_INTERFACE_INCLUDE_DIR" => env("ERL_INTERFACE_INCLUDE_DIR", erl_ei_include_dir),

      # Disable default erlang values
      "BINDIR" => nil,
      "ROOTDIR" => nil,
      "PROGNAME" => nil,
      "EMU" => nil
    }
  end

  defp maybe_add_zig_install_dir(env, :not_downloaded), do: env

  defp maybe_add_zig_install_dir(env, install_dir) when is_binary(install_dir) do
    # Add an env variable that points to the downloaded Zig install dir
    Map.put(env, "ZIG_INSTALL_DIR", install_dir)
  end

  defp env(var, default) do
    System.get_env(var) || default
  end

  defp ensure_downloaded_zig!(nil = _zig_version) do
    # If zig_version is nil, we just return :not_downloaded as install dir
    :not_downloaded
  end

  defp ensure_downloaded_zig!(zig_version) when is_binary(zig_version) do
    prefix = zig_install_prefix()

    # Avoid that multiple applications looking to install the same Zig version stomp on each others
    # feet by using a version-scoped lock
    lock_id = {__MODULE__, zig_version}

    :global.set_lock(lock_id)

    if not ZigInstaller.installed?(prefix, zig_version) do
      ZigInstaller.install!(prefix, zig_version)
    end

    :global.del_lock(lock_id)

    ZigInstaller.install_dir(prefix, zig_version)
  end

  defp downloaded_zig_exec(:not_downloaded), do: :not_downloaded

  defp downloaded_zig_exec(downloaded_zig_install_dir) do
    Path.join(downloaded_zig_install_dir, "zig")
    |> System.find_executable() ||
      Mix.raise("zig executable not found in #{downloaded_zig_install_dir}")
  end
end
