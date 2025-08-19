/// Represents the current connection status to backend services.
///
/// Used by the status bar to display appropriate indicators and
/// provide users with feedback about system availability.
enum ConnectionStatus {
  /// All services are connected and functioning normally.
  ///
  /// Displays green indicators and allows full functionality.
  connected,

  /// Some services are experiencing issues or delays.
  ///
  /// Displays yellow indicators and may show degraded functionality warnings.
  degraded,

  /// Services are disconnected or unavailable.
  ///
  /// Displays red indicators and shows offline mode or error messages.
  disconnected,

  /// Currently attempting to establish or restore connection.
  ///
  /// Displays animated indicators to show connection attempts in progress.
  connecting,

  /// An error occurred during the process of establishing a connection to the Kiro IDE.
  error,
}
