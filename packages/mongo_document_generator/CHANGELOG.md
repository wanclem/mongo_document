## 1.3.6

### Fixed

Bug fixes in sort, limit and skip stages within aggregation pipelines

## 1.3.5

### Fixed

Bug fixes in cruds with enums

## 1.3.4

### Fixed

Bug fixes and Improvements in update functions

## \[1.3.3]

### Fixed

Fixed an issue where saveMany saved plain object references

## \[1.3.2] - 2025-05-13

### Fixed

Aggregation Pipelines shouldn't lookup collections that aren't projected

## \[1.3.1] - 2025-05-13

### Added

Added support for optional db parameter across all crud functions -- Useful mostly in isolates

## \[1.3.0] - 2025-05-12

### Fixed

Bug fixes and Improvements around saves and updates

## \[1.2.9] - 2025-05-12

### Fixed

Crud typos

## \[1.2.8] - 2025-05-12

### Fixed

Save and Save Many timing outs

## \[1.2.7] - 2025-05-12

### Added

Update Docs and Metadata

## \[1.2.6] - 2025-05-12

### Fixed

Update functions should now properly populate object references after the update

## \[1.2.5] - 2025-05-12

### Added

Add more operators

## \[1.2.4] - 2025-05-12

### Fixed

Bug fixes in ObjectId mapping amongst arbitrary set of values

## \[1.2.3] - 2025-05-11

### Fixed

Bug fixes in Projection Classes

## \[1.2.2] - 2025-05-11

### Fixed

Bug fixes in map transformers

## \[1.2.1] - 2025-05-11

### Fixed

Bug fixes in map transformers

## \[1.2.0] - 2025-05-11

### Fixed

Bug fixes in map transformers

## \[1.1.9] - 2025-05-11

### Fixed

Aggregation Pipelines should be able to infer lookups from projections

## \[1.1.8] - 2025-05-11

### Fixed

Fixed a bug in projection-classes code generation where the typecheckers ignored the JsonKey names
of nested collections, and also within the `nestedCollectionMap` literals

## \[1.1.7] - 2025-05-11

### Fixed

Prevent unnecessary MongoDB reconnections by reusing single instance

## \[1.1.6] - 2025-05-10

### Fixed

Bug fixes

## \[1.1.5] - 2025-05-10

### Fixed

Documentation and metadata

## \[1.1.4] - 2025-05-10

### Fixed

fix(delete): ensure nested object references use IDs in deleteByNamed variants

Previously, deletes like `deleteOneByNamed` assigned entire objects (e.g.,
`selector['author'] = author`),
causing incorrect filtering. This fix updates all `deleteOneByNamed` and `deleteManyByNamed`
functions
to reference the object ID instead (e.g., `selector['author'] = author.id`).

## \[1.1.3] - 2025-05-10

### Fixed

fix(query): ensure nested object references use IDs in findByNamed variants

Previously, queries like `findByNamed` assigned entire objects (e.g.,
`selector['author'] = author`),
causing incorrect filtering. This fix updates all `findByOneNamed` and `findByManyNamed` functions
to reference the object ID instead (e.g., `selector['author'] = author.id`).

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

- Full support for multi‑level nested queries using MongoDB document references, enabling retrieval
  of deeply nested data in a single call.
- Validation logic to ensure referenced documents exist before executing nested lookups.
- Examples and recipe in documentation for querying nested sub‑documents via object references.

### Fixed

- Resolved edge case where empty arrays of references would cause query failures.

## \[1.0.3] - 2025-04-01

### Added

- Support for two‑level nested queries (e.g., `author.book.publisher` references).
- Option to specify projection fields on nested referenced documents.

### Changed

- Improved performance of single‑level nested lookups by caching reference resolution.

### Fixed

- Fixed bug where circular references caused infinite loops during population.

## \[1.0.2] - 2025-03-01

### Added

- Initial implementation of nested query support for single‑level MongoDB document references.
- `Projection*` helper classes to simplify querying referenced documents.

### Changed

- Refactored core query builder to accept an array of reference paths.

### Fixed

- Corrected error handling when reference path is invalid or missing.

## \[1.0.1] - 2025-02-01

### Added

- Basic support for querying top‑level referenced documents via object IDs.
- `findById()` method to include referenced documents in query results.

### Fixed

- Fixed missing imports in generated query helper code.

## \[1.0.0] - 2025-01-01

- Initial version.
