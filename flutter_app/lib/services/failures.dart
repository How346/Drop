/// User-facing error taxonomy. Raw exceptions never reach the UI.
enum TransferFailure {
  invalidCode,
  expiredCode,
  deviceNotFound,
  rejected,
  connectionLost,
  wifiUnavailable,
  permissionDenied,
  insufficientStorage,
  fileAccessDenied,
  unsupportedFile,
  interrupted,
  checksumMismatch,
  destinationMissing,
  duplicateFile,
  cancelled,
  noFilesSelected,
  unknown,
}

extension TransferFailureMessage on TransferFailure {
  String get message {
    switch (this) {
      case TransferFailure.invalidCode:
        return "That code isn't right. Check the six digits.";
      case TransferFailure.expiredCode:
        return 'This code expired. Ask for a new one.';
      case TransferFailure.deviceNotFound:
        return "We couldn't find that device on this network.";
      case TransferFailure.rejected:
        return 'The other device declined the connection.';
      case TransferFailure.connectionLost:
        return 'Connection lost. The other device went offline.';
      case TransferFailure.wifiUnavailable:
        return 'Wi-Fi is off. Turn it on or start a hotspot.';
      case TransferFailure.permissionDenied:
        return 'HyperDrop needs local network access.';
      case TransferFailure.insufficientStorage:
        return 'Not enough space to receive these files.';
      case TransferFailure.fileAccessDenied:
        return "That file couldn't be read.";
      case TransferFailure.unsupportedFile:
        return "This file type can't be sent.";
      case TransferFailure.interrupted:
        return 'Transfer paused. Resume when reconnected.';
      case TransferFailure.checksumMismatch:
        return 'A file arrived damaged. Retry that file.';
      case TransferFailure.destinationMissing:
        return 'The save folder is unavailable.';
      case TransferFailure.duplicateFile:
        return 'A file with this name already exists.';
      case TransferFailure.cancelled:
        return 'Transfer cancelled. Partial files removed.';
      case TransferFailure.noFilesSelected:
        return 'Pick at least one file to send.';
      case TransferFailure.unknown:
        return 'Something went wrong. Try again.';
    }
  }
}

class HyperDropException implements Exception {
  HyperDropException(this.failure, [this.detail]);
  final TransferFailure failure;
  final String? detail;

  @override
  String toString() => 'HyperDropException(${failure.name}: ${detail ?? ''})';
}
