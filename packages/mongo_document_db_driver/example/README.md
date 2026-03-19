# mongo_document_db_driver examples

This folder contains small direct-driver examples.

Useful entry points:

- `example.dart`: simple connection and CRUD flow
- `queries.dart`: query examples
- `updates.dart`: update examples
- `aggregation.dart`: aggregation usage
- `concurrent_queries.dart`: concurrency probing
- `raw_queries.dart`: lower-level query examples
- `manual/db_connection.dart`: lower-level connection example

For most apps in this repository, prefer the higher-level generated CRUD from `mongo_document` and the shared startup flow from `mongo_document_annotation`.
