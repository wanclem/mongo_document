import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

bool checkSameDomain(Uri uri, Uri checkUri) {
  var uriParts = uri.host.split('.');
  var checkParts = checkUri.host.split('.');
  if (uriParts.length < 2) {
    throw MongoDartError('At list a domain is required, but got "${uri.host}"');
  }
  if (checkParts.length < 2) {
    throw MongoDartError(
        'At list a domain is required, but got "${checkUri.host}"');
  }
  return uriParts.last == checkParts.last &&
      uriParts[uriParts.length - 2] == checkParts[checkParts.length - 2];
}
