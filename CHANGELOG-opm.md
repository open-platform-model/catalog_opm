# Changelog

## [2.0.0-alpha.8](https://github.com/open-platform-model/catalog_opm/compare/opm-v2.0.0-alpha.7...opm-v2.0.0-alpha.8) (2026-08-28)


### Bug Fixes

* **opm:** keep a service-name fallback for components built against alpha.5 and earlier ([#67](https://github.com/open-platform-model/catalog_opm/issues/67)) ([7c45c73](https://github.com/open-platform-model/catalog_opm/commit/7c45c7348ade19b8d80e04556577b746a678c6b9))

## [2.0.0-alpha.7](https://github.com/open-platform-model/catalog_opm/compare/opm-v2.0.0-alpha.6...opm-v2.0.0-alpha.7) (2026-08-28)


### ⚠ BREAKING CHANGES

* **opm:** rendering the opm workload transformers now requires a kernel that fills #names (library >= v1.0.0-alpha.14).
* **opm:** a component carrying an http, grpc, tcp or tls route trait without #ExposeTrait no longer matches the route transformer.

### Features

* **opm:** routes and network policy read names from the component's #names ([#61](https://github.com/open-platform-model/catalog_opm/issues/61)) ([50ab86c](https://github.com/open-platform-model/catalog_opm/commit/50ab86c684a02ebf50f0cf85d3713d197b4352af))
* **opm:** workload transformers read names from the component's #names ([#64](https://github.com/open-platform-model/catalog_opm/issues/64)) ([a89d37a](https://github.com/open-platform-model/catalog_opm/commit/a89d37aa9ec2fd4ad3d97eb107d4d3226b7ec9ac))

## [2.0.0-alpha.6](https://github.com/open-platform-model/catalog_opm/compare/opm-v2.0.0-alpha.5...opm-v2.0.0-alpha.6) (2026-08-27)


### ⚠ BREAKING CHANGES

* **opm:** ExposeSchema.name is required and DNS-1035 typed (attach through the Expose wrapper or set it); a dotted namespace name refuses at vet.

### Features

* **opm:** declare name constraints and default the expose name ([#51](https://github.com/open-platform-model/catalog_opm/issues/51)) ([1ba119d](https://github.com/open-platform-model/catalog_opm/commit/1ba119de61c67dcc27dc536b96dbf68935483df7))

## [2.0.0-alpha.5](https://github.com/open-platform-model/catalog_opm/compare/opm-v2.0.0-alpha.4...opm-v2.0.0-alpha.5) (2026-08-22)


### ⚠ BREAKING CHANGES

* every raw contract key moves, because the key is built from the catalog's own RegistryPath. Nothing in the workspace demanded a k8s- contract and nothing imported resources/v1 or resources/v2, so the break is priced at zero today. Published opm 2.0.0-alpha.x builds keep carrying the old keys and stay resolvable.

### Features

* **resources:** allow a container to claim several GPUs ([241b740](https://github.com/open-platform-model/catalog_opm/commit/241b7401421f3de9c4fcc6a151b56e4ba97106da))
* split the raw Kubernetes family into its own catalog module ([#45](https://github.com/open-platform-model/catalog_opm/issues/45)) ([e92248f](https://github.com/open-platform-model/catalog_opm/commit/e92248fd6bde8483244339a752e69bb66ff3cdf2))

## [2.0.0-alpha.4](https://github.com/open-platform-model/catalog_opm/compare/v2.0.0-alpha.3...v2.0.0-alpha.4) (2026-08-18)


### ⚠ BREAKING CHANGES

* remove dead *Defaults definitions

### Features

* remove dead *Defaults definitions ([eab9b12](https://github.com/open-platform-model/catalog_opm/commit/eab9b12201258913e807c31bed309987b47ea945))

## [2.0.0-alpha.3](https://github.com/open-platform-model/catalog_opm/compare/v2.0.0-alpha.2...v2.0.0-alpha.3) (2026-08-11)


### Bug Fixes

* **transformers:** updateStrategy guards — daemonset emission and optional rollingUpdate ([#37](https://github.com/open-platform-model/catalog_opm/issues/37)) ([9ea5927](https://github.com/open-platform-model/catalog_opm/commit/9ea5927c7bbe85564f6504bcf6eca728e2b78a86))

## [2.0.0-alpha.2](https://github.com/open-platform-model/catalog_opm/compare/v2.0.0-alpha.1...v2.0.0-alpha.2) (2026-08-10)


### ⚠ BREAKING CHANGES

* consolidate the first-party catalogs and adopt versioned filing ([#34](https://github.com/open-platform-model/catalog_opm/issues/34))

### Features

* consolidate the first-party catalogs and adopt versioned filing ([#34](https://github.com/open-platform-model/catalog_opm/issues/34)) ([8a5c484](https://github.com/open-platform-model/catalog_opm/commit/8a5c484303e359466484f9c150133643aab9af0b))

## [2.0.0-alpha.1](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.9...v2.0.0-alpha.1) (2026-08-10)


### ⚠ BREAKING CHANGES

* author the catalog against core v2 on the module major v2 ([#30](https://github.com/open-platform-model/catalog_opm/issues/30))

### Features

* author the catalog against core v2 on the module major v2 ([#30](https://github.com/open-platform-model/catalog_opm/issues/30)) ([38ae2f1](https://github.com/open-platform-model/catalog_opm/commit/38ae2f19018f9537971c500db22114f601865bf4))

## [1.0.0-alpha.9](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.8...v1.0.0-alpha.9) (2026-08-08)


### Bug Fixes

* **transformers:** emit the declared updateStrategy ([#27](https://github.com/open-platform-model/catalog_opm/issues/27)) ([f74bbff](https://github.com/open-platform-model/catalog_opm/commit/f74bbff0846befa578db3554df5c616913ef26dd))

## [1.0.0-alpha.8](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.7...v1.0.0-alpha.8) (2026-08-07)


### Features

* **resources:** allow a container to claim several GPUs ([241b740](https://github.com/open-platform-model/catalog_opm/commit/241b7401421f3de9c4fcc6a151b56e4ba97106da))

## [1.0.0-alpha.7](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.6...v1.0.0-alpha.7) (2026-08-05)


### Features

* add the RuntimeClass trait ([ac40522](https://github.com/open-platform-model/catalog_opm/commit/ac40522bfba96b1c7b6a76decf69c63a64287094))

## [1.0.0-alpha.6](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.5...v1.0.0-alpha.6) (2026-07-28)


### Features

* port the NetworkPolicy trait from the experimental catalog ([#23](https://github.com/open-platform-model/catalog_opm/issues/23)) ([76fcca4](https://github.com/open-platform-model/catalog_opm/commit/76fcca4786c88466adf1b8e44dabd9584278f1b0))

## [1.0.0-alpha.5](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.4...v1.0.0-alpha.5) (2026-07-28)


### Features

* carry CRD annotations through to the emitted CustomResourceDefinition ([#21](https://github.com/open-platform-model/catalog_opm/issues/21)) ([72814e7](https://github.com/open-platform-model/catalog_opm/commit/72814e772665eaa5b7348ff27e2db0e9b365d091))

## [1.0.0-alpha.4](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.3...v1.0.0-alpha.4) (2026-07-28)


### Features

* workload fidelity — exact names, pod metadata/scheduling, mount propagation, HPA and PDB ([#19](https://github.com/open-platform-model/catalog_opm/issues/19)) ([64b376f](https://github.com/open-platform-model/catalog_opm/commit/64b376f3771dfd2ddd21b5988cc8a1cc4ed3858a))

## [1.0.0-alpha.3](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.2...v1.0.0-alpha.3) (2026-07-27)


### Bug Fixes

* emit exposedPort and non-TCP protocol on Services; carry CRD listKind + selectableFields ([#17](https://github.com/open-platform-model/catalog_opm/issues/17)) ([3c22f26](https://github.com/open-platform-model/catalog_opm/commit/3c22f26b2a42e77f47479536b5c1757f26e7c4bb))

## [1.0.0-alpha.2](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha.1...v1.0.0-alpha.2) (2026-07-27)


### Features

* exact-name ConfigMaps/Services and projected + external volume sources ([4e2c519](https://github.com/open-platform-model/catalog_opm/commit/4e2c51979584aa5159896d7cf304182e3dfa77fc))
* support resourceNames and nonResourceURLs in Role policy rules ([e46d110](https://github.com/open-platform-model/catalog_opm/commit/e46d1109228cba36bbcc635db9824ee807d161a3))

## [1.0.0-alpha.1](https://github.com/open-platform-model/catalog_opm/compare/v1.0.0-alpha...v1.0.0-alpha.1) (2026-07-06)


### Bug Fixes

* **blueprints:** hoist spec propagation guards to component level ([#13](https://github.com/open-platform-model/catalog_opm/issues/13)) ([81641e0](https://github.com/open-platform-model/catalog_opm/commit/81641e09ed81dfd45b7221319dcafbc895741af0))

## [1.0.0-alpha](https://github.com/open-platform-model/catalog_opm/compare/v0.6.0...v1.0.0-alpha) (2026-06-27)


### ⚠ BREAKING CHANGES

* **catalog-opm:** adopt core@v1 instance vocabulary, bump to @v1 ([#10](https://github.com/open-platform-model/catalog_opm/issues/10))

### Features

* **catalog-opm:** adopt core@v1 instance vocabulary, bump to [@v1](https://github.com/v1) ([#10](https://github.com/open-platform-model/catalog_opm/issues/10)) ([c0cd3ec](https://github.com/open-platform-model/catalog_opm/commit/c0cd3ecbb4aa92850f7d238a88a5c111c3d4d41a))

## [0.6.0](https://github.com/open-platform-model/catalog_opm/compare/v0.5.2...v0.6.0) (2026-06-17)


### Features

* support headless Services via expose clusterIP ([#8](https://github.com/open-platform-model/catalog_opm/issues/8)) ([0fee31e](https://github.com/open-platform-model/catalog_opm/commit/0fee31ecc9f02ccb4e9405607e4b4a0720831e42))

## [0.5.2](https://github.com/open-platform-model/catalog_opm/compare/v0.5.1...v0.5.2) (2026-06-17)


### Miscellaneous

* release 0.5.2 ([6dd070d](https://github.com/open-platform-model/catalog_opm/commit/6dd070df23fe15af5db8d5d5671e57ef6477e0b0))

## [0.5.1](https://github.com/open-platform-model/catalog_opm/compare/v0.5.0...v0.5.1) (2026-06-13)


### Bug Fixes

* **resources:** add resource concrete defaults ([#4](https://github.com/open-platform-model/catalog_opm/issues/4)) ([8bd9eb3](https://github.com/open-platform-model/catalog_opm/commit/8bd9eb38e80dff638963c9b84e37818ec0e74066))

## [0.5.0](https://github.com/open-platform-model/catalog_opm/compare/v0.4.0...v0.5.0) (2026-05-31)


### Features

* **cue:** require CUE language version v0.17 ([#2](https://github.com/open-platform-model/catalog_opm/issues/2)) ([52ba0ab](https://github.com/open-platform-model/catalog_opm/commit/52ba0ab570b5b5a9d9289c520abfae0e9ba23dd2))

## [0.4.0](https://github.com/open-platform-model/catalog_opm/compare/v0.3.0...v0.4.0) (2026-05-30)


### Features

* bootstrap catalog_opm with the OPM core catalog ([167887a](https://github.com/open-platform-model/catalog_opm/commit/167887a9787f77ddee36f0d2a0b748c9853eab53))
