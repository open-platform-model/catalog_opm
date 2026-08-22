# Changelog

## [1.0.0-alpha.1](https://github.com/open-platform-model/catalog_opm/compare/k8s-v1.0.0-alpha.0...k8s-v1.0.0-alpha.1) (2026-08-22)


### ⚠ BREAKING CHANGES

* every raw contract key moves, because the key is built from the catalog's own RegistryPath. Nothing in the workspace demanded a k8s- contract and nothing imported resources/v1 or resources/v2, so the break is priced at zero today. Published opm 2.0.0-alpha.x builds keep carrying the old keys and stay resolvable.

### Features

* **resources:** allow a container to claim several GPUs ([241b740](https://github.com/open-platform-model/catalog_opm/commit/241b7401421f3de9c4fcc6a151b56e4ba97106da))
* split the raw Kubernetes family into its own catalog module ([#45](https://github.com/open-platform-model/catalog_opm/issues/45)) ([e92248f](https://github.com/open-platform-model/catalog_opm/commit/e92248fd6bde8483244339a752e69bb66ff3cdf2))
