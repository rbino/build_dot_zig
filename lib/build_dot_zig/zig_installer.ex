defmodule BuildDotZig.ZigInstaller do
  @moduledoc false

  require Logger

  alias BuildDotZig.HTTP

  def installed?(prefix, zig_version) do
    install_dir(prefix, zig_version)
    |> File.dir?()
  end

  def install!(prefix, zig_version) do
    zig_target = zig_target()

    case HTTP.get("https://ziglang.org/download/index.json") do
      {:ok, %{status: 200, body: body}} ->
        info = Jason.decode!(body)
        actual_version = actual_version(info, zig_version)

        Logger.info("Downloading zig #{actual_version}...")
        %{url: url, checksum: checksum} = tarball_url_and_checksum(info, zig_version, zig_target)

        install_dir = install_dir(prefix, zig_version, zig_target)

        download_and_extract!(url, checksum, install_dir)

      other ->
        raise_download_error!("Could not retrieve Zig download info", other)
    end
  end

  def install_dir(prefix, zig_version, zig_target \\ zig_target()) do
    Path.join(prefix, "zig-#{zig_target}-#{zig_version}")
    |> Path.expand()
  end

  defp download_and_extract!(tarball_url, checksum, install_dir) do
    case HTTP.get(tarball_url) do
      {:ok, %{status: 200, body: tarball}} ->
        verify_checksum!(tarball, checksum)

        tmp = System.tmp_dir!()
        tarball_filename = Path.join(tmp, Path.basename(tarball_url))
        tarball_directory = Path.join(tmp, Path.basename(tarball_url, ".tar.xz"))

        File.write!(tarball_filename, tarball)
        {_, 0} = System.cmd("tar", ["-xf", tarball_filename, "-C", tmp])
        File.rm!(tarball_filename)
        File.rename!(tarball_directory, install_dir)

      other ->
        raise_download_error!("Could not download Zig tarball", other)
    end
  end

  defp raise_download_error!(msg, {:ok, %{status: status, body: body}}) do
    Mix.raise("#{msg} (status #{status}, response #{body})")
  end

  defp raise_download_error!(msg, {:error, reason}) do
    Mix.raise("#{msg} (reason #{inspect(reason)})")
  end

  defp verify_checksum!(tarball, expected_checksum) do
    actual_checksum =
      :crypto.hash(:sha256, tarball)
      |> Base.encode16(case: :lower)

    if actual_checksum != expected_checksum do
      Mix.raise("Zig checksum mismatch: expected #{expected_checksum}, got #{actual_checksum}")
    end

    :ok
  end

  defp actual_version(info, "master") do
    info
    |> Map.fetch!("master")
    |> Map.fetch!("version")
  end

  defp actual_version(_info, zig_version) do
    zig_version
  end

  defp tarball_url_and_checksum(info, zig_version, zig_target) do
    version_map =
      Map.get(info, zig_version) ||
        Mix.raise("Version #{zig_version} not found in Zig build index")

    target_map =
      Map.get(version_map, zig_target) ||
        Mix.raise("Target #{zig_target} not found in Zig build index for version #{zig_version}")

    url = Map.fetch!(target_map, "tarball")
    checksum = Map.fetch!(target_map, "shasum")
    %{url: url, checksum: checksum}
  end

  defp zig_target do
    "#{arch()}-#{os()}"
  end

  defp os do
    case :erlang.system_info(:os_type) do
      {:unix, :linux} -> "linux"
      {:unix, :darwin} -> "macos"
      {:win32, _} -> "windows"
      other -> Mix.raise("Unsupported os type: #{inspect(other)}")
    end
  end

  defp arch do
    arch =
      :erlang.system_info(:system_architecture)
      |> to_string()

    cond do
      arch =~ "x86_64" -> "x86_64"
      arch =~ "aarch64" -> "aarch64"
      # Erlang just returns "win32" for Windows, assume it's x86_64
      # TODO: what happens for Windows on ARM?
      arch == "win32" -> "x86_64"
      true -> Mix.raise("Cannot determine architecture: #{arch}")
    end
  end
end
