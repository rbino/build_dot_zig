defmodule Mix.Tasks.Compile.BuildDotZig do
  @moduledoc """
  Runs `zig build` using the `build.zig` file in the current project.

  This task runs `zig build` in the current project; any output coming from `zig build` is printed
  in real-time on stdout.

  ## Configuration

  This compiler can be configured through the return value of the `project/0` function in
  `mix.exs`; for example:

      def project() do
        [app: :myapp,
         build_dot_zig_executable: "zig",
         compilers: [:build_dot_zig] ++ Mix.compilers,
         deps: deps()]
      end

  The following options are available:

    * `:build_dot_zig_executable` - (binary or `:default`) it's the executable to use as the `zig`
    program. If not provided or if `:default`, it defaults to `"zig"`.

  ## Default environment variables

  This compiler also sets deveral default environment variables which are accessible
  from `build.zig`:

  * `MIX_TARGET`
  * `MIX_ENV`
  * `MIX_BUILD_PATH` - same as `Mix.Project.build_path/0`
  * `MIX_APP_PATH` - same as `Mix.Project.app_path/0`
  * `MIX_COMPILE_PATH` - same as `Mix.Project.compile_path/0`
  * `MIX_CONSOLIDATION_PATH` - same as `Mix.Project.consolidation_path/0`
  * `MIX_DEPS_PATH` - same as `Mix.Project.deps_path/0`
  * `MIX_MANIFEST_PATH` - same as `Mix.Project.manifest_path/0`
  * `ERL_EI_LIBDIR`
  * `ERL_EI_INCLUDE_DIR`
  * `ERTS_INCLUDE_DIR`
  * `ERL_INTERFACE_LIB_DIR`
  * `ERL_INTERFACE_INCLUDE_DIR`

  ## Compilation artifacts and working with priv directories

  Generally speaking, compilation artifacts are written to the `priv` directory, as that the only
  directory, besides `ebin`, which are available to Erlang/OTP applications.

  However, note that Mix projects supports the `:build_embedded` configuration, which controls if
  assets in the `_build` directory are symlinked (when `false`, the default) or copied (`true`).
  In order to support both options for `:build_embedded`, it is important to follow the given
  guidelines:

  * The `"priv"` directory must not exist in the source code
  * If there are static assets, `build.zig` should copy them over from a directory at the project
  root (not named "priv")

  This compiler passes `$MIX_APP_PATH/priv/$MIX_TARGET` as install prefix to `zig build`, so the
  resulting artifacts can be found in `$PREFIX/lib` for libraries and `$PREFIX/bin` for binaries.
  Note that the default `$MIX_TARGET` is `:host`.
  """

  use Mix.Task.Compiler

  @doc false
  def run(_args) do
    BuildDotZig.Compiler.compile()
  end

  @doc false
  def clean do
    BuildDotZig.Compiler.clean()
  end
end
