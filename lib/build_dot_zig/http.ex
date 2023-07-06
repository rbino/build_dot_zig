defmodule BuildDotZig.HTTP do
  def get!(url) do
    request_timeout = 15_000

    http_opts = build_http_opts(request_timeout)
    opts = [body_format: :binary]
    request = {url, []}

    :httpc.request(:get, request, http_opts, opts)
    |> handle_response()
  end

  defp build_http_opts(timeout) do
    [
      timeout: timeout,
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

  defp handle_response({:ok, {{_version, code, _reason}, _headers, body}})
       when code >= 200 and code < 300 do
    body
  end

  defp handle_response({:error, reason}) do
    Mix.raise("HTTP request failed: #{inspect(reason)}")
  end
end
