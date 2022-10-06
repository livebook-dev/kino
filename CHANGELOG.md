# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.7.0](https://github.com/livebook-dev/kino/tree/v0.7.0) (2022-10-07)

Along with this release we introduce [`kino_benchee`](https://github.com/livebook-dev/kino_benchee)
for visualizing Benchee results.

### Added

* Added `Kino.Process.render_seq_trace/2` for visualizing inter-process communication ([#165](https://github.com/livebook-dev/kino/pull/165))
* Added `Kino.Layout` for building composite outputs, such as tabs and grid ([#179](https://github.com/livebook-dev/kino/pull/179))
* Added `send_event/4` to `Kino.JS.Live` components for messaging a specific client ([#183](https://github.com/livebook-dev/kino/pull/183))
* Added `Kino.Download` for downloading generated content on demand ([#174](https://github.com/livebook-dev/kino/pull/174))
* Tabbed output for pids and atoms ([#185](https://github.com/livebook-dev/kino/pull/185))
* Unified events consumption via `Kino.listen/{2,3}` and `Kino.animate/{2,3}` ([#186](https://github.com/livebook-dev/kino/pull/186))
* Custom backend for `Kernel.dbg/2` ([#191](https://github.com/livebook-dev/kino/pull/191))
* Added `Kino.Mermaid` ([#199](https://github.com/livebook-dev/kino/pull/199))

### Fixed

* Crashes when reevaluating a cell with finished tasks ([#181](https://github.com/livebook-dev/kino/pull/181))
* Ensured processes started with `Kino.start_child/2` get terminated before reevaluation ([#195](https://github.com/livebook-dev/kino/pull/195))

## [v0.6.2](https://github.com/livebook-dev/kino/tree/v0.6.2) (2022-06-29)

### Added

* Added `Kino.Process` with application/supervision tree visualization ([#158](https://github.com/livebook-dev/kino/pull/158))

### Changed

* Improved `Kino.DataTable` to lazily traverse the data ([#160](https://github.com/livebook-dev/kino/pull/160))

### Fixed

* Fixed `Kino.DataTable` to respect the `:keys` order ([#151](https://github.com/livebook-dev/kino/pull/151))

## [v0.6.1](https://github.com/livebook-dev/kino/tree/v0.6.1) (2022-05-03)

This release primarily introduces `Kino.SmartCell`, which allows for
creating custom cells in Livebook. Check out the module docs for more
information and see [this PR](https://github.com/livebook-dev/livebook/pull/1029)
for more context.

Along with this release we introduce two new packages, focusing on
specific integrations, namely [`kino_vega_lite`](https://github.com/livebook-dev/kino_vega_lite)
and [`kino_db`](https://github.com/livebook-dev/kino_db).

### Added

* Support for binary payloads in `Kino.JS` and `Kino.JS.Live` ([#88](https://github.com/livebook-dev/kino/pull/88))
* Support for defining smart cells ([#98](https://github.com/livebook-dev/kino/pull/98))
* Support for custom `:name` in `Kino.DataTable` ([#102](https://github.com/livebook-dev/kino/pull/102))
* Callback API for `Kino.Control` events ([#126](https://github.com/livebook-dev/kino/pull/126))

### Changed

* Changed `Kino.ETS` to render a single column of tuples ([#90](https://github.com/livebook-dev/kino/pull/90))
* Converted DataTable to accept any data compatible with `Table.Reader` ([#122](https://github.com/livebook-dev/kino/pull/122))

### Removed

* Removed `Kino.Ecto`
* Removed `VegaLite` integration in favour of the `kino_vega_lite` package

## [v0.5.2](https://github.com/livebook-dev/kino/tree/v0.5.2) (2022-02-03)

### Removed

* Removed Vega-Lite plot actions incompatible with Livebook ([#83](https://github.com/livebook-dev/kino/pull/83))

### Fixed

* Fixed `Kino.JS` to recompile modules when assets change ([#83](https://github.com/livebook-dev/kino/pull/83))

## [v0.5.1](https://github.com/livebook-dev/kino/tree/v0.5.1) (2022-01-25)

### Fixed

* Fixed `Kino.JS` assets archive path to resolve priv directory at runtime ([#82](https://github.com/livebook-dev/kino/pull/82))

## [v0.5.0](https://github.com/livebook-dev/kino/tree/v0.5.0) (2022-01-19)

This release primarily introduces `Kino.JS` and `Kino.JS.Live`, which
enable creating custom Livebook widgets with JavaScript. Other than a few
other additions, the APIs did not change significantly, but a lot of the
internals were reworked to align with Livebook changes, so make sure to
update Livebook to 0.5.0 or later.

### Added

* Added `Add Kino.Control.form/2` for aggregated input events ([#62](https://github.com/livebook-dev/kino/issues/62))
* Added support for defining custom JavaScript widgets ([#64](https://github.com/livebook-dev/kino/issues/64))
* Added type validations for default input value ([#77](https://github.com/livebook-dev/kino/issues/77))
* Added stream API for control and input events ([#76](https://github.com/livebook-dev/kino/issues/76) and [#78](https://github.com/livebook-dev/kino/issues/78))

### Changed

* Changed the internal implementation of most widgets to align with changes in Livebook 0.5.0 ([#68](https://github.com/livebook-dev/kino/issues/68), [#71](https://github.com/livebook-dev/kino/issues/71) and [#75](https://github.com/livebook-dev/kino/issues/75))

### Removed

* Removed the deprecated `start/*` widget functions ([#69](https://github.com/livebook-dev/kino/issues/69))
* Removed `Kino.Input.subscribe/1` and `Kino.Input.unsubscribe/1` in favour of `Kino.Control` counterparts ([#78](https://github.com/livebook-dev/kino/pull/78/files))

## [v0.4.1](https://github.com/livebook-dev/kino/tree/v0.4.1) (2021-12-05)

### Added

* Added `Kino.inspect/2` ([#60](https://github.com/livebook-dev/kino/issues/60))

### Changed

* Changed `Kino.render/1` to return the rendered value ([#60](https://github.com/livebook-dev/kino/issues/60))

## [v0.4.0](https://github.com/livebook-dev/kino/tree/v0.4.0) (2021-12-04)

### Added

* Introduced `Kino.Input` for user input ([#53](https://github.com/livebook-dev/kino/issues/53))
* Introduced `Kino.Control` for user events ([#50](https://github.com/livebook-dev/kino/issues/50))
* Added `Kino.start_child/1` for starting supervised processes ([#50](https://github.com/livebook-dev/kino/issues/50))

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
