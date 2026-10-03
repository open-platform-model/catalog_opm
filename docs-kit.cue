bundles: {
	"catalog-opm": {
		placement: {kind: "tab", root: "/catalogs/opm/"}
		version: {from: "tag", prefix: "opm-v"}
		sources: [
			{kind: "cue-catalog", module: "./src"},
			{kind: "markdown", dir: "docs/catalogs/opm"},
		]
	}
}
