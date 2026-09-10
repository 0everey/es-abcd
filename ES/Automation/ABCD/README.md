# ABCD Generic Portable Core

This directory contains the project-neutral ABCD/ABCC execution core. It is safe to reuse across projects because it contains no gameplay, scene, asset, Knowledge, AIWarnings, provider, credential, or model-specific content.

Start with `es-abcd-generic-package.manifest.json`. After extraction, run `Restore-ESABCDGenericPackage.ps1` against the target project. Missing files are repaired; hash mismatches remain `review-required` unless `-ForceRepair` is explicitly authorized.

`idea-validated` and static contract acceptance never imply runtime acceptance. Runtime, PlayMode, Profiler, and release claims require fresh evidence from the target project.
