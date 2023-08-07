# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - Unreleased

### Added

- Add `zig_target` option.
- Add `zig_cpu` option.

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
