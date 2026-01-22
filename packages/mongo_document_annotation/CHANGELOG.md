## 1.7.6

Ensure atomic reconnections

## 1.7.5

### Fixed

Removed awaited collection name calls

## 1.7.4

### Fixed

InterfaceType checks and conditional .toJson() invocation on supported types

## 1.7.3

### Fixed

Reduce ping heartbeat to 15s for some environments

## 1.7.2

### Fixed

Handle disconnections more proactively

## 1.7.1

### Fixed

Revise connector

## 1.7.0

### Fixed

Properly pluralize classes

## 1.6.9

### Fixed

Properly pluralize classes

## 1.6.8

### Fixed

Preserve nulls in singe lookups

## 1.6.7

### Added

Add support for nested lookups

## 1.6.6

### Fixed

Add support for collision free projections

## 1.6.5

### Fixed

Updated analyzer and migrated ParamElems to FormalParams

## 1.6.4

### Upgrade

Updated analyzer and migrated ParamElems to FormalParams

## 1.6.3

### Added

Added support for type safe advanced lookups

## 1.6.2

### Fixed

Add automatic reconnection with retry logic for connection failures

## 1.6.1

### Fixed

Bug fixes around base projection checks when projections are empty in aggregation pipelines

## 1.6.0

### Added

Added support for deep inner collection emptiness checks

## 1.5.9

### Added

Added support for deep search within collections

## 1.5.8

### Fixed

Bug fixes around projections

## 1.5.7

### Fixed

Bug fixes around Date times

## 1.5.6

### Fixed

Bug fixes around updateOneFromMap

## 1.5.5

### Fixed

Bug fixes around bulk updates

## 1.5.4

### Fixed

Bug fixes around bulk updates

## 1.5.4

### Added

Array Query Enhancements: Added isNotEmpty() and isEmpty() methods to the QList query builder class,
enabling efficient filtering of documents based on whether array fields contain elements or are
empty.

## 1.5.3

### Feat

**Nested Field Querying**: Query builder now supports deep field access on nested objects, allowing
queries on properties of embedded classes (e.g., `user.profile.settings.theme.eq('dark')`)

## 1.5.2

### Fixed

Bug fixes around datetime converters

## 1.5.1

### Fixed

Bug fixes around projection classes

## 1.5.0

### Fixed

Bug fixes around saveMany

## 1.4.9

### Fixed

Bug fixes around Base Projections

## 1.4.8

### Added

Added support for chaining queries beyond the recommended DSL patterns, allowing shorthand syntaxes.
Use with caution, as type checking is not enforced at compile time

## 1.4.7

### Fixed

Preserve nulls when updating documents

## 1.4.6

### Fixed

Removed transitive updates

## 1.4.5

### Fixed

Update packages

## 1.4.4

### Fixed

Update packages

## 1.4.3

### Fixed

Cosmetic changes

## 1.4.2

### Fixed

Fixed a bug where saveMany wasn't auto creating time stamps

## 1.4.1

### Removed

Removed sort option until fixed

## 1.4.0

### Fixes

Bug fixes

## 1.3.9

### Fixes

Bug fixes

## 1.3.8

### Fixes

Peg Dart SDK at 3.7.0

## 1.3.7

### Fixes

Peg Dart SDK at 3.7.0

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
