# A `build.zig` compiler for Mix

This package aims to be similar to [`elixir_make`](https://github.com/elixir-lang/elixir_make) (from
which it takes lots of inspiration) but for projects based on Zig as a buildsystem, instead of Make.

## Usage

The package can be installed by adding `build_dot_zig` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:build_dot_zig, github: "rbino/build_dot_zig", runtime: false}
  ]
end
```

Still in your `mix.exs` file, you will need to add `:build_dot_zig` to your list of compilers in
`project/0`:

```
compilers: [:build_dot_zig] ++ Mix.compilers,
```

And that's it.

Note that for this to work you should have `zig` in your path, in the future it's possible this
library will also automatically download the `zig` compiler.

## License

Copyright (c) 2023 Riccardo Binetti

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at
https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing permissions and limitations under the
License.
