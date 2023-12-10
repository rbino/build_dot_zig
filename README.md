# A `build.zig` compiler for Mix

This package aims to be similar to [`elixir_make`](https://github.com/elixir-lang/elixir_make) (from
which it takes lots of inspiration) but for projects based on Zig as a build system, instead of
Make.

## Usage

The package can be installed by adding `build_dot_zig` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:build_dot_zig, "~> 0.3.0", runtime: false}
  ]
end
```

Still in your `mix.exs` file, you will need to add `:build_dot_zig` to your list of compilers in
`project/0`:

```
compilers: [:build_dot_zig] ++ Mix.compilers,
```

If you're starting a new C NIF from scratch, you can use the Mix generator to bootstrap it. Run:

```console
mix help build_dot_zig.gen.c_nif
```

to read the documentation of the generator. You can also use the output of the generator as
inspiration to replace an existing build system for a NIF with the Zig build system.

The appropriate `zig` binary will be automatically downloaded and used to run the `build.zig`
builder.

For more information about what you can do with the Zig build system, read the [Zig build system
guide](https://ziglang.org/learn/build-system).

## License

Copyright (c) 2023 Riccardo Binetti

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing permissions and limitations under the
License.
