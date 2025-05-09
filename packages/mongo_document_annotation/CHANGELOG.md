## \[1.1.2] - 2025-05-09

### Documentation
metadata, bug fixes, documentation

## \[1.1.1] - 2025-05-09

### Fixed

Bug fixes

## \[1.0.5] - 2025-05-09

### Fixed

Bug where query via nested object references returns null

## \[1.0.4] - 2025-05-09

### Added

* Full support for multi‑level nested queries using MongoDB document references, enabling retrieval of deeply nested data in a single call.
* Validation logic to ensure referenced documents exist before executing nested lookups.
* Examples and recipe in documentation for querying nested sub‑documents via object references.

### Fixed

* Resolved edge case where empty arrays of references would cause query failures.

## \[1.0.3] - 2025-04-01

### Added

* Support for two‑level nested queries (e.g., `author.book.publisher` references).
* Option to specify projection fields on nested referenced documents.

### Changed

* Improved performance of single‑level nested lookups by caching reference resolution.

### Fixed

* Fixed bug where circular references caused infinite loops during population.

## \[1.0.2] - 2025-03-01

### Added

* Initial implementation of nested query support for single‑level MongoDB document references.
* `Projection*` helper classes to simplify querying referenced documents.

### Changed

* Refactored core query builder to accept an array of reference paths.

### Fixed

* Corrected error handling when reference path is invalid or missing.

## \[1.0.1] - 2025-02-01

### Added

* Basic support for querying top‑level referenced documents via object IDs.
* `findById()` method to include referenced documents in query results.

### Fixed

* Fixed missing imports in generated query helper code.

## \[1.0.0] - 2025-01-01

* Initial version.
