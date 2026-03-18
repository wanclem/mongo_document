import 'package:mongo_document_db_driver/src/database/utils/map_keys.dart'
    show keyCode, keyCodeName, keyErrmsg;

/// Classifies server errors that should trigger topology refresh and retry.
///
/// This centralizes legacy and modern MongoDB error variants so retry policy
/// remains stable across server versions and message wording differences.
class RecoverableErrorClassifier {
  static const Set<int> _retryableServerErrorCodes = <int>{
    6, // HostUnreachable
    7, // HostNotFound
    89, // NetworkTimeout
    91, // ShutdownInProgress
    189, // PrimarySteppedDown
    262, // ExceededTimeLimit
    9001, // SocketException
    10107, // NotWritablePrimary / NotMaster
    11600, // InterruptedAtShutdown
    11602, // InterruptedDueToReplStateChange
    13435, // NotPrimaryNoSecondaryOk
    13436, // NotPrimaryOrSecondary
  };

  static bool isRetryableServerErrorCode(int? code) =>
      code != null && _retryableServerErrorCodes.contains(code);

  static String _normalizeToken(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool isPrimaryRoutingFailureMessage(String message) {
    var normalized = message.toUpperCase();
    return normalized.contains('NOT WRITABLE PRIMARY') ||
        normalized.contains('NOTPRIMARY') ||
        normalized.contains('NOT PRIMARY') ||
        normalized.contains('NOT MASTER') ||
        normalized.contains('SLAVEOK=FALSE') ||
        normalized.contains('PRIMARY STEPPED DOWN') ||
        normalized.contains('NODE IS RECOVERING');
  }

  static bool isPrimaryRoutingFailureCodeName(String? codeName) {
    var normalizedCodeName = _normalizeToken(codeName ?? '');
    return normalizedCodeName.contains('NOTWRITABLEPRIMARY') ||
        normalizedCodeName.contains('NOTMASTER') ||
        normalizedCodeName.contains('NOTPRIMARY') ||
        normalizedCodeName.contains('PRIMARYSTEPPEDDOWN') ||
        normalizedCodeName.contains('NODEISRECOVERING');
  }

  static bool isConnectionLifecycleFailureMessage(String message) {
    var normalized = message.toUpperCase();
    return normalized.contains('CONNECTION CLOSED') ||
        normalized.contains('CONNECTIONEXCEPTION') ||
        normalized.contains('SOCKET');
  }

  static bool isCursorSessionMismatchMessage(String message) {
    var normalized = message.toUpperCase();
    return (normalized.contains('CURSOR SESSION ID') &&
            normalized.contains("OPERATION CONTEXT'S SESSION ID")) ||
        normalized.contains('CURSOR SESSION STATE WAS LOST') ||
        normalized.contains('CURSOR MUST BE RESUMED');
  }

  static bool isAuthenticationRequiredMessage(String message) {
    var normalized = message.toUpperCase();
    return normalized.contains('REQUIRES AUTHENTICATION') ||
        normalized.contains('AUTHENTICATION REQUIRED');
  }

  static bool isAuthenticationStateFailureDocument(Map<String, dynamic> error) {
    var code = (error[keyCode] as num?)?.toInt();
    var message = error[keyErrmsg]?.toString() ?? '';
    return code == 13 && isAuthenticationRequiredMessage(message);
  }

  static bool isRecoverableServerErrorDocument(Map<String, dynamic> error) {
    var code = (error[keyCode] as num?)?.toInt();
    if (isRetryableServerErrorCode(code)) {
      return true;
    }
    if (isPrimaryRoutingFailureCodeName(error[keyCodeName]?.toString())) {
      return true;
    }
    var message = error[keyErrmsg]?.toString() ?? '';
    return isAuthenticationStateFailureDocument(error) ||
        isCursorSessionMismatchMessage(message) ||
        isConnectionLifecycleFailureMessage(message) ||
        isPrimaryRoutingFailureMessage(message);
  }
}
