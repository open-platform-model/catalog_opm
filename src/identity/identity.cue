// Package identity is the single source of the catalog's module path and
// version. It sits at the bottom of the catalog's import graph (it imports
// nothing within the module) so transformer/resource/trait/blueprint
// subpackages can source `ModulePath`/`Version` without a circular import,
// and the root `catalog.cue` can stamp transformer metadata in lockstep.
//
// Committed with the REAL values (enhancement 0010 D5): a checkout and a
// published artifact compute the same FQNs — the `0.0.0-dev` sentinel is
// gone. `Version` stays a CUE *default* so the publish task's transient
// `version_override.cue` can still stamp `-dev.*` branch builds; release
// publishes stamp the same value the tree already carries. release-please
// owns the committed value via the x-release-please-version annotation.
package identity

// #VersionType mirrors core.#VersionType (SemVer 2.0). Duplicated here so the
// identity package stays import-free at the bottom of the graph, matching the
// mirror convention used by schemas/common.cue for #NameType.
#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// ModulePath is the catalog's complete CUE module path, major suffix included
// — byte-identical to cue.mod's `module:` field (enhancement 0010 D1).
ModulePath: "opmodel.dev/catalogs/opm@v2"

// Version is the catalog's bare SemVer — the build every implementation key
// interpolates. The default is the current release line's version; the major
// MUST agree with ModulePath's (asserted by core's #IdentityPackage at
// publish once 0011's publish gates land).
Version: #VersionType | *"2.0.0-alpha.3" // x-release-please-version

// RegistryPath is the major-free OCI repository path.
RegistryPath: "opmodel.dev/catalogs/opm"

// kindPrefix mirrors core's #IdentityPackage.kindPrefix — one BASE prefix per
// kind (enhancement 0010 D42 as amended by D49). Contract members file exactly
// one segment beneath it, under their own apiVersion — a segment derived from
// the member's key, so filing and key cannot drift — while transformers file
// at the prefix itself. Every member's metadata.modulePath carries the
// versioned path; authored fqns still derive from the base prefix, so the key
// space stays flat.
kindPrefix: {
	resources:    RegistryPath + "/resources"
	traits:       RegistryPath + "/traits"
	blueprints:   RegistryPath + "/blueprints"
	transformers: RegistryPath + "/transformers"
}
