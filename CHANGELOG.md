# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.15.3](https://github.com/livebook-dev/kino/tree/v0.15.3) (2025-03-05)

### Fixed

* `Kino.HTML` to wait for external scripts to load before executing inline ones
* Fixed menu opening in table with summary
* Improved UX for initial table load ([#497](https://github.com/livebook-dev/kino/pull/497), [#499](https://github.com/livebook-dev/kino/pull/499))

## [v0.15.2](https://github.com/livebook-dev/kino/tree/v0.15.2) (2025-02-27)

### Fixed

* `Kino.JS.new/3` to ignore `:export_key`, instead of raising ([#495](https://github.com/livebook-dev/kino/pull/495))

## [v0.15.1](https://github.com/livebook-dev/kino/tree/v0.15.1) (2025-02-26)

### Fixed

* `Kino.JS.new/3` to ignore `:export_info_string`, instead of raising

## [v0.15.0](https://github.com/livebook-dev/kino/tree/v0.15.0) (2025-02-24)

### Added

* `:max_height` option to `Kino.Layout.grid/2` ([#479](https://github.com/livebook-dev/kino/pull/479))
* Support for getting node and cookie from variables in Remote execution cell ([#481](https://github.com/livebook-dev/kino/pull/481))
* `:style` option to `Kino.Text.new/2` ([#490](https://github.com/livebook-dev/kino/pull/490))
* Added `Kino.Screen` as an abstraction for building complex forms in apps ([#489](https://github.com/livebook-dev/kino/pull/489))

### Changed

* `Kino.Control.tagged_stream/1` to allow any term as tag ([#485](https://github.com/livebook-dev/kino/pull/485))

### Removed

* Removed the deprecated `:export_info_string` option from `Kino.JS.new/3`

### Fixed

* Entries now showing when updating empty data table via `Kino.DataTable.update/3`
* Mermaid output export crashing ([#492](https://github.com/livebook-dev/kino/pull/492))

## [v0.14.2](https://github.com/livebook-dev/kino/tree/v0.14.2) (2024-10-22)

### Added

* Support setting a custom number of rows in `Kino.DataTable` ([#476](https://github.com/livebook-dev/kino/pull/476))
* Added `:caption` and `:download` options to `Kino.Mermaid` ([#477](https://github.com/livebook-dev/kino/pull/477))

### Changed

* Update `Kino.Mermaid` to use Mermaid v11
* Increased the max column width in `Kino.DataTable`

## [v0.14.1](https://github.com/livebook-dev/kino/tree/v0.14.1) (2024-09-20)

### Added

* Added `Kino.Test.push_smart_cell_editor_source/2` to test editor changes ([#468](https://github.com/livebook-dev/kino/pull/468))

### Fixed

* `Kino.start_child/1` to unregister the process if evaluation terminates during process startup ([#470](https://github.com/livebook-dev/kino/pull/470))

## [v0.14.0](https://github.com/livebook-dev/kino/tree/v0.14.0) (2024-08-26)

### Added

* Added `Kino.Audio.play/1` and `Kino.Audio.pause/1` ([#458](https://github.com/livebook-dev/kino/pull/458))
* Support for specifying column ratios in `Kino.Layout.grid/2` ([#459](https://github.com/livebook-dev/kino/pull/459))
* Support for toggling Smart cell editor visibility ([#467](https://github.com/livebook-dev/kino/pull/467))

### Changed

* Remote smart cell to generate code with triple quote when content contains a quote ([#465](https://github.com/livebook-dev/kino/pull/465))

### Fixed

## [v0.13.2](https://github.com/livebook-dev/kino/tree/v0.13.2) (2024-07-05)

### Added

* Worker and supervisor ids in app supervision graph ([#449](https://github.com/livebook-dev/kino/pull/449))

### Changed

* Changed `Kino.Input.read/1` to raise an error when called in a background process ([#451](https://github.com/livebook-dev/kino/pull/451))

### Fixed

* Fixed the `dbg` pipeline UI crashing when result renders as `Kino.JS.Live` ([#453](https://github.com/livebook-dev/kino/pull/453))

## [v0.13.1](https://github.com/livebook-dev/kino/tree/v0.13.1) (2024-06-21)

### Added

* Support for module plugs in `Kino.Proxy.listen/1` ([#448](https://github.com/livebook-dev/kino/pull/448))

## [v0.13.0](https://github.com/livebook-dev/kino/tree/v0.13.0) (2024-06-17)

### Added

* Smart cell editor options `:intellisense_node` and `:source` ([#390](https://github.com/livebook-dev/kino/pull/390))
* Added `:entrypoint` option on `use Kino.JS` to specify custom entrypoint file ([#392](https://github.com/livebook-dev/kino/pull/392))
* Added `Kino.recompile/0` for recompiling path dependencies from `Mix.install/2` ([#399](https://github.com/livebook-dev/kino/pull/399))
* Added `:message_label` option to `Kino.Process.seq_trace/2` ([#411](https://github.com/livebook-dev/kino/pull/411))
* Added `Kino.Workspace.user_info/1` for getting information about the given client ([#412](https://github.com/livebook-dev/kino/pull/412))
* Support for column relocation in `Kino.Table` ([#419](https://github.com/livebook-dev/kino/pull/419))
* Added `:render_ets_tables` option to `Kino.Process.app_tree/2` ([#411](https://github.com/livebook-dev/kino/pull/411))
* Introduced `Kino.Proxy` for handling requests forwarded from Livebook ([#431](https://github.com/livebook-dev/kino/pull/431), [#433](https://github.com/livebook-dev/kino/pull/433))
* Added `Kino.beam_paths/0` ([#439](https://github.com/livebook-dev/kino/pull/439))
* Added `:formatter` option to `Kino.DataTable.new/2` ([#441](https://github.com/livebook-dev/kino/pull/441))
* Support for OTP 27 process labels in `Kino.Process.seq_trace/2` ([#442](https://github.com/livebook-dev/kino/pull/442))

### Changed

* Make the smart cell editor source explicitly managed ([#391](https://github.com/livebook-dev/kino/pull/391))
* Deprecated the smart cell editor `:attribute` and infavour of explicitly managing the source with `c:handle_editor_change/2`. See [this commit](https://github.com/livebook-dev/kino_db/commit/2b9ee6387217a732797e687b3fc12d6937932e6c) for an example of how to migrate to the new API ([#391](https://github.com/livebook-dev/kino/pull/391))
* `Kino.Tree` to automatically expand tuples of up to 6 elements ([#398](https://github.com/livebook-dev/kino/pull/398))
* Changed `c:Kino.Table.export_data/2` to accept extra argument with order information ([#418](https://github.com/livebook-dev/kino/pull/418))
* Renamed the `Kino.Hub` module to `Kino.Workspace` ([#434](https://github.com/livebook-dev/kino/pull/434))

### Fixed

* Fixed `Kino.DataTable` crashing with empty data ([#427](https://github.com/livebook-dev/kino/pull/427))
* Tables font changing on first hover in Firefox ([#435](https://github.com/livebook-dev/kino/pull/435))

## [v0.12.3](https://github.com/livebook-dev/kino/tree/v0.12.3) (2024-01-22)

### Added

* CellKind `:struct` for `Kino.DataTable` ([#383](https://github.com/livebook-dev/kino/pull/383))

## [v0.12.2](https://github.com/livebook-dev/kino/tree/v0.12.2) (2024-01-05)

### Fixed

* Correctly renders CellKind `:list` for `Kino.DataTable` ([#376](https://github.com/livebook-dev/kino/pull/376))

## [v0.12.1](https://github.com/livebook-dev/kino/tree/v0.12.1) (2024-01-02)

### Added

* CellKind `:list` for `Kino.DataTable` ([#373](https://github.com/livebook-dev/kino/pull/373))


## [v0.12.0](https://github.com/livebook-dev/kino/tree/v0.12.0) (2023-12-12)

### Added

* Support for S3 token in `Kino.FS.file_spec/1`, available on Livebook v0.12 onwards

### Changed

* `dbg` backend to fall back to the currently registered callback ([#369](https://github.com/livebook-dev/kino/pull/369))
* Changed charlists in `Kino.DataTable` to be formatted as strings only if ASCI-printable

### Fixed

* Fixed `Kino.DataTable` to handle integer lists that are not valid charlists ([#371](https://github.com/livebook-dev/kino/pull/371))

## [v0.11.3](https://github.com/livebook-dev/kino/tree/v0.11.3) (2023-11-15)

### Fixed

* Code with interpolation in remote execution smart cell ([#366](https://github.com/livebook-dev/kino/pull/366))

## [v0.11.2](https://github.com/livebook-dev/kino/tree/v0.11.2) (2023-11-09)

### Fixed

* Remote execution cell to work with different Elixir and OTP versions on the remote node ([#363](https://github.com/livebook-dev/kino/pull/363))

## [v0.11.1](https://github.com/livebook-dev/kino/tree/v0.11.1) (2023-10-31)

### Added

* Support for specifying node name as secret in Remote execution cell ([#358](https://github.com/livebook-dev/kino/pull/358))

### Changed

* Table pagination to go back to the first page on sorting ([#357](https://github.com/livebook-dev/kino/pull/357))

### Fixed

* Showing non-utf8 binaries in `Kino.DataTable` ([#362](https://github.com/livebook-dev/kino/pull/362))

## [v0.11.0](https://github.com/livebook-dev/kino/tree/v0.11.0) (2023-10-06)

Note that Kino v0.11.0 requires Livebook v0.11.0, so make sure to upgrade Livebook.

With this release of Livebook and Kino we changed the values for audio and image input. The `:data` key with inline binary has been removed in favour of `:file_ref`, which points to a file similarly to the file input. Note that this is not a Kino change per se, the value you get depends specifically on your Livebook version. Here's how you can access the whole binary with the new API:

```diff
image_input = Kino.Input.image("Image")
# ...
image = Kino.Input.read(image_input)

-image.data
+image.file_ref
+|> Kino.Input.file_path()
+|> File.read!()
```

### Added

* Added `Kino.Shorts`, a convenience module for building outputs and inputs ([#310](https://github.com/livebook-dev/kino/pull/310))
* Added `Kino.Audio` and `Kino.Video` for displaying multimedia data ([#311](https://github.com/livebook-dev/kino/pull/311))
* Option for `Kino.Control.keyboard/2` to not suppress default shortcuts ([#312](https://github.com/livebook-dev/kino/pull/312))
* Added `:terminal` option to `Kino.Text` to support ANSI codes and to mirror stdio style ([#314](https://github.com/livebook-dev/kino/pull/314))
* Support for remote processes in `Kino.Process` ([#317](https://github.com/livebook-dev/kino/pull/317))
* Support for chunked text and markdown outputs ([#318](https://github.com/livebook-dev/kino/pull/318))
* Added `Kino.FS` for accessing notebook files ([#319](https://github.com/livebook-dev/kino/pull/319))
* Support for `Kino.JS.Live` outputs to be exported ([#321](https://github.com/livebook-dev/kino/pull/321))
* Added `Kino.start_child!/1` ([#322](https://github.com/livebook-dev/kino/pull/322))
* Remote execution cell ([#328](https://github.com/livebook-dev/kino/pull/328), [#348](https://github.com/livebook-dev/kino/pull/348))
* `Kino.tmp_dir/0` to get a directory that is cleaned when the runtime terminates ([#344](https://github.com/livebook-dev/kino/pull/344))
* Enabled Kino.DataTable data to be exported in .livemd ([#346](https://github.com/livebook-dev/kino/pull/346))
* Added `:debounce` option to inputs ([#347](https://github.com/livebook-dev/kino/pull/347))
* Defined default rendering for `Nx.Heatmap` ([#349](https://github.com/livebook-dev/kino/pull/349))

### Changed

* `Kino.listen/{2,3}` to return PID of the started process ([#306](https://github.com/livebook-dev/kino/pull/306))
* **(Breaking)** Changed audio and image input values to include file rather than inline binary data

### Fixed

* Fixed date validation when allowed range is given ([#326](https://github.com/livebook-dev/kino/pull/326))

## [v0.10.0](https://github.com/livebook-dev/kino/tree/v0.10.0) (2023-07-10)

### Added

* Added `Kino.interrupt/2` ([#288](https://github.com/livebook-dev/kino/pull/288))
* CDN information to `Kino.JS` assets ([#289](https://github.com/livebook-dev/kino/pull/289))
* Support for `Kino.JS.Live` as event source ([#294](https://github.com/livebook-dev/kino/pull/294))
* Added datetime, time and date inputs ([#291](https://github.com/livebook-dev/kino/pull/291))
* Added an option to disable frame placeholder ([#297](https://github.com/livebook-dev/kino/pull/297))
* `Kino.Hub.app_info/0` for accessing app information ([#299](https://github.com/livebook-dev/kino/pull/299))

## [v0.9.4](https://github.com/livebook-dev/kino/tree/v0.9.4) (2023-05-12)

### Added

* Support for lazy tabular data ([#283](https://github.com/livebook-dev/kino/pull/283))
* Download option to tabular outputs ([#284](https://github.com/livebook-dev/kino/pull/284))

## [v0.9.3](https://github.com/livebook-dev/kino/tree/v0.9.3) (2023-04-27)

### Fixed

* Fixed `Kino.animate/2` blocking when used with interval ([#281](https://github.com/livebook-dev/kino/pull/281))

## [v0.9.2](https://github.com/livebook-dev/kino/tree/v0.9.2) (2023-04-16)

### Fixed

* Premature cleanup of kinos pushed to frame from `Kino.async_listen/2` ([#277](https://github.com/livebook-dev/kino/pull/277))

## [v0.9.1](https://github.com/livebook-dev/kino/tree/v0.9.1) (2023-04-06)

### Added

* Support for transient frame updates ([#272](https://github.com/livebook-dev/kino/pull/272))
* Support for deferred reply in `Kino.JS.Live.handle_call/3` ([#274](https://github.com/livebook-dev/kino/pull/274))
* More options for the number of table rows to show ([#275](https://github.com/livebook-dev/kino/pull/275))
* Added `Kino.terminate_child/1` ([#276](https://github.com/livebook-dev/kino/pull/276))

## [v0.9.0](https://github.com/livebook-dev/kino/tree/v0.9.0) (2023-03-17)

### Added

* Support for sending frame updates to a specific client ([#250](https://github.com/livebook-dev/kino/pull/250))
* Added `Kino.HTML` ([#259](https://github.com/livebook-dev/kino/pull/259))
* Made controls and inputs enumerable ([#262](https://github.com/livebook-dev/kino/pull/262))
* Automatic detection of image binary ([#264](https://github.com/livebook-dev/kino/pull/264))
* Added `Kino.Text` ([#265](https://github.com/livebook-dev/kino/pull/265))
* Introduced public `Kino.Table` behaviour ([#266](https://github.com/livebook-dev/kino/pull/266))
* Added `Kino.async_listen/2` ([#268](https://github.com/livebook-dev/kino/pull/268))

### Changed

* **(Breaking)** Changed API for accessing file input value ([#253](https://github.com/livebook-dev/kino/pull/253))
* Failures in listen and animate callback to be ignored ([#263](https://github.com/livebook-dev/kino/pull/263))

### Fixed

* Support for non-charlist list values in DataTable ([#252](https://github.com/livebook-dev/kino/pull/252))

## [v0.8.1](https://github.com/livebook-dev/kino/tree/v0.8.1) (2023-01-24)

### Added

* Added a `:monospace` option to `Kino.Input.textarea/2` ([#220](https://github.com/livebook-dev/kino/pull/220))
* Added `Kino.Input.audio/2` ([#239](https://github.com/livebook-dev/kino/pull/239))
* Added `Kino.Input.file/2` ([#241](https://github.com/livebook-dev/kino/pull/241))
* Added `Kino.JS.Live.monitor/1` ([#242](https://github.com/livebook-dev/kino/pull/242))


### Changed

* Improved table view ([#223](https://github.com/livebook-dev/kino/pull/223), [#235](https://github.com/livebook-dev/kino/pull/235), [#247](https://github.com/livebook-dev/kino/pull/247))
* `dbg` backend to fall back to the default `dbg` when called outside Livebook context ([#231](https://github.com/livebook-dev/kino/pull/231))

### Fixed

* `Kino.DataTable` not showing the last page ([#225](https://github.com/livebook-dev/kino/pull/225))

## [v0.8.0](https://github.com/livebook-dev/kino/tree/v0.8.0) (2022-12-05)

### Added

* Support for multi-chunk smart cell source ([#209](https://github.com/livebook-dev/kino/pull/209))
* Added `Kino.Input.image/2` for images ([#210](https://github.com/livebook-dev/kino/pull/210))
* Added `Kino.Tree` for structured term inspection ([#208](https://github.com/livebook-dev/kino/pull/208))
* Support for directly rendering tensors as image via `Kino.Image.new/1` ([#218](https://github.com/livebook-dev/kino/pull/218))

### Changed

* Updated `Kino.DataTable` to use Glide Data Grid for richer interactions ([#211](https://github.com/livebook-dev/kino/pull/211), [#213](https://github.com/livebook-dev/kino/pull/213), [#216](https://github.com/livebook-dev/kino/pull/216))

## [v0.7.0](https://github.com/livebook-dev/kino/tree/v0.7.0) (2022-10-07)

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
