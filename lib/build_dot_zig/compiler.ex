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

  def build(config) do
    build_root = Keyword.get(config, :build_path, "_build")
    local? = Keyword.get(config, :build_dot_zig_use_local_zig, false)

    zig_version = Keyword.get(config, :build_dot_zig_force_zig_version, :default) |> zig_version()

    maybe_fetch_zig!(local?, build_root, zig_version)

    executable = Keyword.get(config, :build_dot_zig_executable, "zig")
    exec = exec(local?, executable, build_root)

    app_path = Mix.Project.app_path(config)
    mix_target = Mix.target()
    install_prefix = "#{app_path}/priv/#{mix_target}"
    build_path = Mix.Project.build_path(config)
    args = build_args(install_prefix, build_path)
    env = default_env(config)

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

  defp exec(_local = true, exec, _build_root) do
    System.find_executable(exec) ||
      Mix.raise("""
      "#{exec}" not found in the path. If you have set the :build_dot_zig_executable \
      variable, please make sure it is correct.
      """)
  end

  defp exec(_local = false, _exec, build_root) do
    downloaded_zig_exec_path(build_root)
  end

  defp build_args(install_prefix, build_path) do
    ["build"] ++ install_prefix_args(install_prefix) ++ cache_dir_args(build_path)
  end

  defp install_prefix_args(install_prefix) do
    ["-p", install_prefix]
  end

  defp cache_dir_args(build_path) do
    ["--cache-dir", cache_dir(build_path)]
  end

  defp cache_dir(build_path) do
    Path.join(build_path, "zig-cache")
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

  defp env(var, default) do
    System.get_env(var) || default
  end

  defp maybe_fetch_zig!(true = _local?, _build_root, _zig_version) do
    # Local Zig, no need to fetch
    :ok
  end

  defp maybe_fetch_zig!(false = _local?, build_root, zig_version) do
    if zig_already_downloaded?(build_root) do
      :ok
    else
      ZigInstaller.fetch_zig!(build_root, zig_version)
    end
  end

  defp zig_version(:default), do: @latest_stable_zig
  defp zig_version(other) when is_binary(other), do: other

  defp zig_already_downloaded?(build_root) do
    path =
      build_root
      |> downloaded_zig_exec_path()

    case System.find_executable(path) do
      nil -> false
      _ -> true
    end
  end

  defp downloaded_zig_exec_path(build_root) do
    Path.join([build_root, "zig", "zig"])
    |> Path.expand()
  end
end
