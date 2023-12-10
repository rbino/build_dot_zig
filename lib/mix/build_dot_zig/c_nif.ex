defmodule Mix.BuildDotZig.CNif do
  @moduledoc false

  @enforce_keys [:otp_app, :module, :module_file, :library, :library_file, :functions]
  defstruct @enforce_keys

  alias Mix.BuildDotZig.CNif

  def new(module, library, functions) do
    otp_app = Mix.BuildDotZig.otp_app()

    base = Mix.BuildDotZig.app_base(otp_app)
    module = Module.concat([base, module])
    module_path = Macro.underscore(module)
    module_file = Mix.BuildDotZig.lib_path(module_path <> ".ex")

    library_file = Mix.BuildDotZig.src_path(library <> ".c")

    %CNif{
      otp_app: otp_app,
      module: module,
      module_file: module_file,
      library: library,
      library_file: library_file,
      functions: Enum.map(functions, &parse_function/1)
    }
  end

  defp parse_function(function) do
    [name, arity] = String.split(function, "/", parts: 2)

    int_arity =
      case Integer.parse(arity) do
        {int_arity, ""} ->
          int_arity

        _other ->
          Mix.raise("Invalid arity: `#{inspect(arity)}` given to generator. Expected an integer.")
      end

    {name, int_arity}
  end
end
