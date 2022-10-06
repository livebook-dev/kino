<h1><img src="https://github.com/elixir-nx/kino/raw/main/images/kino.png" alt="Kino" width="400"></h1>

[![Docs](https://img.shields.io/badge/hex.pm-docs-8e7ce6.svg)](https://hexdocs.pm/kino)
[![Actions Status](https://github.com/livebook-dev/kino/workflows/Test/badge.svg)](https://github.com/livebook-dev/kino/actions)

`Kino` is the library used by [Livebook](https://github.com/elixir-nx/livebook)
to render rich and interactive output directly from your Elixir code.

## Installation

To bring Kino to Livebook all you need to do is `Mix.install/2`:

```elixir
Mix.install([
  {:kino, "~> 0.7.0"}
])
```

Additionally, there are packages with components designed for a specific
use cases. The officially supported ones are:

  * [`kino_vega_lite`](https://github.com/livebook-dev/kino_vega_lite) - for data charting
  * [`kino_db`](https://github.com/livebook-dev/kino_db) - for database integrations
  * [`kino_benchee`](https://github.com/livebook-dev/kino_benchee) - for rendering [Benchee](https://github.com/bencheeorg/benchee) results

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
