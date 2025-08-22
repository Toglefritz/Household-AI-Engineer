/// Represents the current status of the Kiro IDE connection.
///
/// Used to communicate the availability and operational state of the Kiro IDE
/// to other parts of the application that need to react to connectivity changes.
enum KiroStatus {
  /// Kiro Bridge is available and responsive.
  ///
  /// The bridge is running and accepting requests. Normal operations
  /// can proceed.
  available,

  /// Kiro Bridge is unavailable or not responding.
  ///
  /// The bridge may not be running, or there may be network connectivity
  /// issues preventing communication.
  unavailable,

  /// Kiro is currently processing a request.
  ///
  /// The IDE is busy handling a user request and may not be able to
  /// accept new requests immediately.
  processing,

  /// Kiro has encountered an error state.
  ///
  /// The IDE or bridge has reported an error condition that may require
  /// user intervention or system restart.
  error,
}
