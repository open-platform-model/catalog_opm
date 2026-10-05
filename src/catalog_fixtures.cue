@if(fixtures)

package opm

// opm defines provider-fulfilled contracts (backup@v1alpha1,
// backup-command@v1alpha1) and implements none (AGENTS.md: never a stub).
// Core derives provides; this requires it and pins it empty.
// A bare "incomplete" from task vet means core lost provides: run cue vet -c -t fixtures . in src/.
provides!: []

// Keeps this file under task vet:fixtures:tagged.
_testCatalogProvides: true
