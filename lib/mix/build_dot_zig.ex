defmodule Mix.BuildDotZig do
  @moduledoc false

  def otp_app do
    Mix.Project.config() |> Keyword.fetch!(:app)
  end

  def app_base(app) do
    case Application.get_env(app, :namespace, app) do
      ^app -> app |> to_string() |> Macro.camelize()
      mod -> mod |> inspect()
    end
  end

  def lib_path(rel_path) do
    Path.join(["lib", rel_path])
  end

  def src_path(rel_path) do
    Path.join(["src", rel_path])
  end

  def render_parameter_placeholders(0 = _arity) do
    nil
  end

  def render_parameter_placeholders(arity) do
    placeholders =
      Stream.repeatedly(fn -> "_" end)
      |> Enum.take(arity)
      |> Enum.join(", ")

    ["(", placeholders, ")"]
  end
end
