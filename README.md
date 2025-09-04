<h1><img src="https://github.com/elixir-nx/kino/raw/main/images/kino.png" alt="Kino" width="400"></h1>

[![Docs](https://img.shields.io/badge/hex.pm-docs-8e7ce6.svg)](https://hexdocs.pm/kino)
[![Actions Status](https://github.com/livebook-dev/kino/workflows/Test/badge.svg)](https://github.com/livebook-dev/kino/actions)

`Kino` is the library used by [Livebook](https://github.com/elixir-nx/livebook)
to render rich and interactive output directly from your Elixir code. You can learn
more about Kino by [installing Livebook](https://livebook.dev/) and heading into
the "Learn" section of your sidebar.

## Installation

To bring Kino to Livebook all you need to do is `Mix.install/2`:

```elixir
Mix.install([
  {:kino, "~> 0.17.0"}
])
```

Additionally, there are packages with components designed for a specific
use cases. The officially supported ones are:

  * [`kino_bumblebee`](https://github.com/livebook-dev/kino_bumblebee) - for [Bumblebee](https://github.com/elixir-nx/bumblebee) integration
  * [`kino_db`](https://github.com/livebook-dev/kino_db) - for database integrations
  * [`kino_explorer`](https://github.com/livebook-dev/kino_explorer) - for [Explorer](https://github.com/elixir-nx/explorer) integration
  * [`kino_maplibre`](https://github.com/livebook-dev/kino_maplibre) - for map plotting
  * [`kino_slack`](https://github.com/livebook-dev/kino_slack) - for Slack integration
  * [`kino_vega_lite`](https://github.com/livebook-dev/kino_vega_lite) - for data charting
  * [`kino_benchee`](https://github.com/livebook-dev/kino_benchee/tree/main) - for rendering Benchee test results

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
