<h1><img src="https://github.com/elixir-nx/kino/raw/main/images/kino.png" alt="Kino" width="400"></h1>

[![Actions Status](https://github.com/elixir-nx/kino/workflows/Test/badge.svg)](https://github.com/elixir-nx/kino/actions)
[![Docs](https://img.shields.io/badge/docs-gray.svg)](https://hexdocs.pm/kino)

`Kino` is the library used by [Livebook](https://github.com/elixir-nx/livebook)
to render rich and interactive output directly from your Elixir code.

[See the documentation](https://hexdocs.pm/kino).

## Installation

To bring Kino to Livebook all you need to do is `Mix.install/2`:

```elixir
Mix.install([
  {:kino, "~> 0.2.2"}
])
```

You may need other dependencies for specific widgets, like
[`:vega_lite`](https://github.com/elixir-nx/vega_lite) for dynamic plots.

## License

Copyright (C) 2021 Dashbit

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
