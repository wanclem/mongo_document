## 2.0.4

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^2.0.4`
- `mongo_document_db_driver: ^2.0.4`

## 2.0.3

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^2.0.3`
- `mongo_document_db_driver: ^2.0.3`

## 2.0.2

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^2.0.2`
- `mongo_document_db_driver: ^2.0.2`

## 2.0.1

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^2.0.1`
- `mongo_document_db_driver: ^2.0.1`

Cleaned up analyzer findings in the generator templates.

## 2.0.0

### Changed

Aligned dependencies:
- `mongo_document_annotation: ^2.0.0`
- `mongo_document_db_driver: ^2.0.0`

## 1.7.30

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.30`
- `mongo_document_db_driver: ^1.7.30`

## 1.7.29

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.29`
- `mongo_document_db_driver: ^1.7.29`

## 1.7.28

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.28`
- `mongo_document_db_driver: ^1.7.28`

## 1.7.27

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.27`
- `mongo_document_db_driver: ^1.7.27`

## 1.7.26

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.26`
- `mongo_document_db_driver: ^1.7.26`

## 1.7.25

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.25`
- `mongo_document_db_driver: ^1.7.25`

## 1.7.24

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.24`
- `mongo_document_db_driver: ^1.7.24`

## 1.7.23

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.23`
- `mongo_document_db_driver: ^1.7.23`

## 1.7.22

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.22`
- `mongo_document_db_driver: ^1.7.22`

## 1.7.21

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.21`
- `mongo_document_db_driver: ^1.7.21`

## 1.7.20

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.20`
- `mongo_document_db_driver: ^1.7.20`

## 1.7.19

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.19`
- `mongo_document_db_driver: ^1.7.19`

## 1.7.18

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.18`
- `mongo_document_db_driver: ^1.7.18`

## 1.7.17

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.17`
- `mongo_document_db_driver: ^1.7.17`

## 1.7.16

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.16`
- `mongo_document_db_driver: ^0.10.12`

## 1.7.15

### Added

Added AI-oriented package documentation (`README.AI.md`) for coding-agent workflows.

### Fixed

Aligned dependencies:
- `mongo_document_annotation: ^1.7.15`
- `mongo_document_db_driver: ^0.10.11`

## 1.7.14

### Fixed

Align dependencies with the rewritten local driver stack:
- `mongo_document_annotation: ^1.7.14`
- `mongo_document_db_driver: ^0.10.9`

## 1.7.13

### Fixed

Use where.id for update follow-up lookup with null-safe id guard.

## 1.7.12

### Fixed

Handle nullable ids in update templates for newer mongo_document_db_driver signatures.

## 1.7.11

### Fixed

Remove unnecessary non-null assertion in update template type checks.

## 1.7.10

### Fixed

Remove unnecessary non-null assertion in update template.

## 1.7.9

### Fixed

Upgrade mongo_document_db_driver to 0.10.7.

## 1.7.8

Upgrade deps

## 1.7.7

Ensure atomic reconnections with atlas

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
