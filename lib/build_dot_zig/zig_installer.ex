defmodule BuildDotZig.ZigInstaller do
  require Logger

  alias BuildDotZig.HTTP

  def fetch_zig!(priv_dir, zig_version) do
    zig_target = zig_target()

    info =
      HTTP.get!("https://ziglang.org/download/index.json")
      |> Jason.decode!()

    actual_version = actual_version(info, zig_version)

    Logger.info("Downloading zig #{actual_version}...")

    tarball_url = tarball_url(info, zig_version, zig_target)

    download_and_extract(priv_dir, tarball_url)
  end

  defp download_and_extract(priv_dir, tarball_url) do
    tarball = HTTP.get!(tarball_url)

    tarball_filename = Path.join(priv_dir, Path.basename(tarball_url))
    tarball_directory = Path.join(priv_dir, Path.basename(tarball_url, ".tar.xz"))

    File.write!(tarball_filename, tarball)

    {_, 0} = System.cmd("tar", ["-xf", tarball_filename, "-C", priv_dir])

    File.rm!(tarball_filename)

    File.rename!(tarball_directory, Path.join(priv_dir, "zig"))
  end

  defp actual_version(info, "master") do
    info
    |> Map.fetch!("master")
    |> Map.fetch!("version")
  end

  defp actual_version(_info, zig_version) do
    zig_version
  end

  defp tarball_url(info, zig_version, zig_target) do
    version_map =
      Map.get(info, zig_version) ||
        Mix.raise("Version #{zig_version} not found in Zig build index")

    target_map =
      Map.get(version_map, zig_target) ||
        Mix.raise("Target #{zig_target} not found in Zig build index for version #{zig_version}")

    Map.fetch!(target_map, "tarball")
  end

  defp zig_target do
    architecture =
      :erlang.system_info(:system_architecture)
      |> to_string()

    arch = arch(architecture)
    os = os(architecture)

    "#{arch}-#{os}"
  end

  defp os(architecture) do
    cond do
      architecture =~ "linux" -> "linux"
      architecture =~ "apple" -> "macos"
      true -> Mix.raise("Cannot determine os: #{architecture}")
    end
  end

  defp arch(architecture) do
    cond do
      architecture =~ "x86_64" -> "x86_64"
      architecture =~ "aarch64" -> "aarch64"
      true -> Mix.raise("Cannot determine architecture: #{architecture}")
    end
  end
end
