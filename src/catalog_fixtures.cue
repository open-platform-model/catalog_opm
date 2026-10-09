@if(fixtures)

package opm

import id "opmodel.dev/catalogs/opm/identity"

// opm defines provider-fulfilled contracts (backup@v1alpha1,
// backup-command@v1alpha1) and implements none (AGENTS.md: never a stub).
// Core derives provides; this requires it and pins it empty.
// A bare "incomplete" from task vet means core lost provides: run cue vet -c -t fixtures . in src/.
provides!: []

// Keeps this file under task vet:fixtures:tagged.
_testCatalogProvides: true

// sizing@v1beta1 and encryption@v1beta1 were removed: no transformer handled
// either, so attaching one rendered nothing. A non-empty list here means one
// is listed again: remove its clause only in the change that adds a transformer.
_testRemovedTraitsStayRemoved: [for k, _ in #traits if k == "\(id.kindPrefix.traits)/sizing@v1beta1" || k == "\(id.kindPrefix.traits)/encryption@v1beta1" {k}] & []
