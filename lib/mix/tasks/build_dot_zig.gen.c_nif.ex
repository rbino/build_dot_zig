defmodule Mix.Tasks.BuildDotZig.Gen.CNif do
  @shortdoc "Initializes a C NIF"

  @moduledoc """
  Initializes a C NIF with its build system based on `build.zig`.

      mix build_dot_zig.gen.c_nif Math math sum/2 multiply/2

  The first argument is the Elixir module that will expose the NIF, relative to the base namespace
  of your app. In this case the generated module will be in `lib/your_app/math.ex` and will be
  called `YourApp.Math`.

  The second argument is the name of the NIF library. In this case the generated C file will be
  `src/math.c`.

  The other arguments represent the functions exposed by the NIF with their arity. Empty stubs
  for each of the listed functions will be generated both on the Elixir and C side. By default
  the function stubs just raise a `:not_implemented` error.

  ## Functions

  The functions are given using `name/arity` syntax.

  It's possible to pass the same function with multiple arities (e.g. `sum/2`, `sum/3`), in
  that case on the C side there will still be only a single function and its implementation
  will have to distinguish between the different arities at runtime by looking at `argc`.
  """
  use Mix.Task

  alias Mix.BuildDotZig.CNif

  @doc false
  def run(args) do
    c_nif = build(args)

    create_files(c_nif, nif: c_nif)
    print_shell_instructions()
  end

  @doc false
  def build(args) do
    {_, parsed, _} = OptionParser.parse(args, switches: [])
    [module, library | functions] = validate_args!(parsed)

    CNif.new(module, library, functions)
  end

  @doc false
  def validate_args!([module, library | functions] = args) do
    if not valid_module?(module) do
      raise_with_help(
        "Expected the module argument, #{inspect(module)}, to be a valid module name"
      )
    end

    if not valid_library?(library) do
      raise_with_help(
        "Expected the NIF library argument, #{inspect(library)}, to be a valid library name (lowercase and underscore)"
      )
    end

    for function <- functions do
      if not valid_function?(function) do
        raise_with_help("Expected #{inspect(function)} to be in the form name/arity")
      end
    end

    args
  end

  def validate_args!(_) do
    raise_with_help("Invalid arguments")
  end

  defp valid_module?(module) do
    module =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  defp valid_library?(library) do
    # TODO: evaluate if this is ok or too strict/permissive
    library =~ ~r/^[a-z](_?[a-z]+)*[a-z]$/
  end

  defp valid_function?(function) do
    # TODO: evaluate if this is ok or too strict/permissive
    function =~ ~r|^[a-z](_?[a-z]+)*[a-z]/\d+$|
  end

  @doc false
  @spec raise_with_help(String.t()) :: no_return()
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix build_dot_zig.gen.c_nif expects a module name followed by
    a library name followed by one or more function name with arity

        mix build_dot_zig.gen.c_nif Math math sum/2 multiply/2
    """)
  end

  defp create_files(%CNif{} = c_nif, binding) do
    %CNif{
      module_file: module_file,
      library_file: library_file
    } = c_nif

    templates_dir = Application.app_dir(:build_dot_zig, "priv/templates/build_dot_zig.gen.c_nif")

    Mix.Generator.create_file(
      module_file,
      EEx.eval_file(Path.join(templates_dir, "module.ex.eex"), binding)
    )

    Mix.Generator.create_file(
      library_file,
      EEx.eval_file(Path.join(templates_dir, "library.c.eex"), binding)
    )

    Mix.Generator.create_file(
      "build.zig",
      EEx.eval_file(Path.join(templates_dir, "build.zig.eex"), binding)
    )

    c_nif
  end

  defp print_shell_instructions do
    Mix.shell().info("""

    Make sure you have :build_dot_zig in your list of compilers inside project/0 in mix.exs:
        def project do
          [
            # ...
            compilers: [:build_dot_zig] ++ Mix.compilers(),
            # ...
          ]
        end
    """)
  end
end
