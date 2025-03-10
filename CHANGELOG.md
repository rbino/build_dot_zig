# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.1] - 2025-03-10

- Update deps.
- Clarify docs on supported Zig versions.

## [0.6.0] - 2025-03-10

- Bump default Zig version to `0.14.0`.

## [0.5.0] - 2024-07-26

- Bump default Zig version to `0.13.0` and make the generated `build.zig` compatible with it.

## [0.4.2] - 2023-12-13

### Fixed

- Add missing include in generated library to make it work on Windows

## [0.4.1] - 2023-12-13

### Fixed

- Fix the generated `build.zig` to make it work on Windows.

## [0.4.0] - 2023-12-11

### Added

- Add `mix build_dot_zig.gen.c_nif` Mix generator.
- Allow passing project-specific options with `zig_extra_options`.

### Changed

- Use `:release_safe` build mode by default in `:prod` env. Leave `:debug` as default in all other
  cases.

### Fixed

- Fix arch detection on Windows.

## [0.3.1] - 2023-08-22

### Fixed

- Pass the correct option for optimize modes.

### Changed

- Due to the different options for the optimize modes, `:build_dot_zig` is currently only
compatible with Zig version `0.11.0`.

## [0.3.0] - 2023-08-08

### Added

- Add `zig_target` option.
- Add `zig_cpu` option.

### Changed

- Bump latest stable `zig` to `0.11.0`.

## [0.2.0] - 2023-07-10

### Added

- Clean Zig cache on `mix.clean`.
- Add functionality to automatically download the `zig` toolchain, also with a specific version.
- Allow defining the build mode from the Mix configuration.

### Changed

- BREAKING: rename `:build_dot_zig_executable` option to `:zig_executable`.

## [0.1.1] - 2023-03-03

### Fixed

- Handle `:default` in the `:build_dot_zig_executable` option.

### Changed

- Put `zig-cache` in the `_build` folder with all other build artifacts.

## [0.1.0] - 2023-02-26

### Added

- Initial release.
