defmodule Mix.Tasks.Compile.BuildDotZig do
  @moduledoc """
  Runs `zig build` using the `build.zig` file in the current project.

  This task runs `zig build` in the current project; any output coming from `zig build` is printed
  in real-time on stdout.

  ## Configuration

  This compiler can be configured through the return value of the `project/0` function in
  `mix.exs`; for example:

      def project() do
        [
          app: :myapp,
          install_zig: "0.10.1",
          compilers: [:build_dot_zig] ++ Mix.compilers,
          deps: deps()
        ]
      end

  The following options are available:

    * `:install_zig` - (binary or boolean) determines if a Zig installation should be automatically
    downloaded and installed locally in the build directory. If `false`, no Zig installation is
    downloaded. If `true` (default), the latest Zig stable version is downloaded. Otherwise, it's
    possible to pass a specific Zig version, e.g. `install_zig: "0.11.0"`.

    > ### Zig version support {: .warning }
    >
    > `:build_dot_zig` currently supports only Zig version `0.11.0` due to breaking changes
    > to the build options passed in the command line. As long as the command line interface
    > remains stable, it will be possible to support multiple future Zig versions.

    * `:zig_executable` - (binary or `:default`) it's the executable to use as the `zig`
    program. If not provided or if `:default`, it defaults to the downloaded `zig` binary if
    the `install_zig` was configured to download Zig, otherwise it defaults to `zig` (it assumes
    to find it in the `PATH`). Note that it's possible to both install a downloaded Zig installation
    _and_ pass a local `:zig_executable`. This is useful for use cases where the downloaded Zig
    installation must be called through some wrapper script.

    * `:zig_build_mode` - (atom) allows choosing the build mode. The supported build modes are
    `:debug` (default), `:release_safe`, `:release_fast` and `:release_small`.

    * `:zig_target` - (binary or `:host`) it's the target that will be passed with the
    `-Dtarget` flag to `zig`. This can be used to support cross-compilation. If not provided or if
    `:host` (which is the default returned by `Mix.target()`), the `-Dtarget` flag is not passed.

    * `:zig_cpu` - (binary or `:native`) the set of CPU features that will be passed with the
    `-Dcpu` flag to `zig`. If not provided or if `:native` the `-Dcpu` flag is not passed, which
    makes `zig` use _all_ the CPU features of the host. If you're not running the compiled code on
    the same machine where you're compiling, setting this to `"baseline"` is a good starting point.

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
  * `ZIG_INSTALL_DIR` - the directory where the Zig toolchain was downloaded, if it was.

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
