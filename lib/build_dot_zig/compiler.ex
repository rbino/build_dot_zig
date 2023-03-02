defmodule BuildDotZig.Compiler do
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
    exec = Keyword.get(config, :build_dot_zig_executable, :default) |> exec()

    app_path = Mix.Project.app_path(config)
    mix_target = Mix.target()
    install_prefix = "#{app_path}/priv/#{mix_target}"
    args = build_args(install_prefix)
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

  defp exec(:default) do
    "zig"
  end

  defp exec(path) when is_binary(path) do
    path
  end

  defp build_args(install_prefix) do
    ["build"] ++ install_prefix_args(install_prefix)
  end

  defp install_prefix_args(install_prefix) do
    ["-p", install_prefix]
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
end
