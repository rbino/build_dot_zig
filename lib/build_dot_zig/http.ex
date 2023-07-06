defmodule BuildDotZig.HTTP do
  alias Mint.HTTP

  @zig_website_host "ziglang.org"

  def connect! do
    opts = [transport_opts: [cacertfile: CAStore.file_path()]]

    case HTTP.connect(:https, @zig_website_host, 443, opts) do
      {:ok, conn} -> conn
      {:error, reason} -> Mix.raise("Could not connect to Zig website: #{reason}")
    end
  end

  def close(conn) do
    {:ok, _conn} = HTTP.close(conn)

    :ok
  end

  def get!(conn, path, timeout \\ 5_000) do
    case HTTP.request(conn, "GET", path, [], nil) do
      {:ok, conn, ref} -> loop(conn, ref, "", timeout, false)
    end
  end

  defp loop(conn, _ref, body_acc, _timeout, true = _done) do
    {conn, body_acc}
  end

  defp loop(conn, ref, body_acc, timeout, done) do
    receive do
      msg ->
        case HTTP.stream(conn, msg) do
          {:ok, conn, responses} ->
            {body_acc, done} =
              Enum.reduce(responses, {body_acc, done}, &handle_response(ref, &1, &2))

            loop(conn, ref, body_acc, timeout, done)

          :unknown ->
            loop(conn, ref, body_acc, timeout, done)
        end
    after
      timeout -> Mix.raise("HTTP request timed out")
    end
  end

  defp handle_response(ref, {:data, ref, new_data}, {body_acc, false = done}) do
    {[body_acc | new_data], done}
  end

  defp handle_response(ref, {:done, ref}, {body_acc, false = _done}) do
    {body_acc, true}
  end

  defp handle_response(_ref, _other, acc) do
    acc
  end
end
