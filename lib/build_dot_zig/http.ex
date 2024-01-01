defmodule BuildDotZig.HTTP do
  @moduledoc false

  # Extremely minimal HTTP client to download the Zig build index and compiler using :httpc
  def get(url) do
    request_connect_timeout = 30_000

    http_opts = build_http_opts(request_connect_timeout)
    opts = [body_format: :binary]
    request = {url, []}

    case :httpc.request(:get, request, http_opts, opts) do
      {:ok, {{_version, status, _reason}, headers, body}} ->
        {:ok, %{status: status, headers: headers, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_http_opts(connect_timeout) do
    [
      connect_timeout: connect_timeout,
      relaxed: true,
      ssl: build_ssl_opts()
    ]
  end

  defp build_ssl_opts do
    [
      verify: :verify_peer,
      depth: 4,
      cacertfile: CAStore.file_path(),
      secure_renegotiate: true,
      reuse_sessions: true,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end
end
