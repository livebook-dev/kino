# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.3.1](https://github.com/livebook-dev/kino/tree/v0.3.1) (2021-11-10)

### Added

* Added `Kino.Frame` and `Kino.animate/3` for animating static outputs ([#39](https://github.com/livebook-dev/kino/issues/39))

## [v0.3.0](https://github.com/livebook-dev/kino/tree/v0.3.0) (2021-07-28)

### Changed

* **(Breaking)** Changed `Kino.render/1` to return hidden value ([#38](https://github.com/livebook-dev/kino/issues/38))

## [v0.2.3](https://github.com/livebook-dev/kino/tree/v0.2.3) (2021-07-25)

### Fixed

* Fixed compilation without Ecto installed ([#35](https://github.com/livebook-dev/kino/issues/35))

## [v0.2.2](https://github.com/livebook-dev/kino/tree/v0.2.2) (2021-07-23)

### Added

* Added support for structs in DataTable ([#33](https://github.com/elixir-nx/kino/pull/33))
* Added table widget for Ecto queries ([#34](https://github.com/elixir-nx/kino/pull/34))

## [v0.2.1](https://github.com/livebook-dev/kino/tree/v0.2.1) (2021-06-26)

### Added

* Made inspect options globally configurable ([#26](https://github.com/elixir-nx/kino/pull/26))
* Added markdown output and `Kino.Markdown` ([#28](https://github.com/elixir-nx/kino/pull/28))

## [v0.2.0](https://github.com/livebook-dev/kino/tree/v0.2.0) (2021-06-24)

### Added

* Added image output and `Kino.Image` ([#24](https://github.com/elixir-nx/kino/pull/24))

### Changed

* **(Breaking)** Start dynamic widgets with new for consistency ([#25](https://github.com/elixir-nx/kino/pull/25))

## [v0.1.3](https://github.com/livebook-dev/kino/tree/v0.1.3) (2021-06-21)

### Added

* Added `Kino.DataTable` ([#22](https://github.com/elixir-nx/kino/pull/22))

### Changed

* Disable sorting for ETS tables ([#23](https://github.com/elixir-nx/kino/pull/23))

### Fixed

* Handle ETS tables with mixed number of columns ([#21](https://github.com/elixir-nx/kino/pull/21))

## [v0.1.2](https://github.com/livebook-dev/kino/tree/v0.1.2) (2021-06-17)

### Added

* Add dynamic table output and ETS table widget ([#12](https://github.com/elixir-nx/kino/pull/12))
* Validate VegaLite data points and automatically convert to map ([#13](https://github.com/elixir-nx/kino/pull/13))

## [v0.1.1](https://github.com/livebook-dev/kino/tree/v0.1.1) (2021-06-11)

### Added

* Add support for periodical callbacks in the VegaLite widget ([#3](https://github.com/elixir-nx/kino/pull/3))

## [v0.1.0](https://github.com/livebook-dev/kino/tree/v0.1.0) (2021-06-01)

Initial release
