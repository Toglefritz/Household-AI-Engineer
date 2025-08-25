import 'dart:io';

/// Service for detecting Kiro IDE installation and availability.
///
/// This service provides methods to check if Kiro is installed on the system
/// by attempting to execute the `kiro --version` command. It handles platform-specific
/// command execution and provides structured results for the setup flow.
class KiroDetectionService {
  /// Checks if Kiro IDE is installed and accessible via command line.
  ///
  /// Attempts to execute `kiro --version` command and returns true if the command
  /// succeeds with a valid version output. This method handles various failure
  /// scenarios including command not found, permission issues, and invalid responses.
  ///
  /// Returns a [Future<bool>] that resolves to true if Kiro is detected,
  /// false otherwise. The method includes timeout handling to prevent hanging
  /// on unresponsive commands.
  ///
  /// Throws [KiroDetectionException] if there's an unexpected error during detection
  /// that isn't related to Kiro being unavailable.
  Future<bool> isKiroInstalled() async {
    try {
      // Execute kiro --version command with timeout
      final ProcessResult result =
          await Process.run(
            'kiro',
            ['--version'],
            runInShell: true,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw const TimeoutException(
              'Kiro version check timed out',
              Duration(seconds: 10),
            ),
          );

      // Check if command executed successfully and returned version info
      if (result.exitCode == 0) {
        final String output = result.stdout.toString().trim();

        // Validate that output contains version information
        if (output.isNotEmpty && _isValidVersionOutput(output)) {
          return true;
        }
      }

      return false;
    } on ProcessException catch (e) {
      // Command not found or execution failed
      if (e.errorCode == 2 || e.message.contains('command not found')) {
        return false;
      }

      // Unexpected process error
      throw KiroDetectionException(
        'Failed to check Kiro installation: ${e.message}',
        cause: e,
      );
    } on TimeoutException {
      // Command timed out - treat as not available
      return false;
    } catch (e) {
      // Unexpected error during detection
      throw KiroDetectionException(
        'Unexpected error during Kiro detection: $e',
        cause: e,
      );
    }
  }

  /// Retrieves the installed Kiro version if available.
  ///
  /// Executes `kiro --version` and parses the version string from the output.
  /// This method should only be called after confirming Kiro is installed
  /// using [isKiroInstalled].
  ///
  /// Returns a [Future<String?>] containing the version string if successful,
  /// or null if the version cannot be determined.
  ///
  /// Throws [KiroDetectionException] if there's an error retrieving the version.
  Future<String?> getKiroVersion() async {
    try {
      final ProcessResult result = await Process.run(
        'kiro',
        ['--version'],
        runInShell: true,
      ).timeout(const Duration(seconds: 10));

      if (result.exitCode == 0) {
        final String output = result.stdout.toString().trim();
        return _parseVersionFromOutput(output);
      }

      return null;
    } catch (e) {
      throw KiroDetectionException(
        'Failed to retrieve Kiro version: $e',
        cause: e,
      );
    }
  }

  /// Validates that the command output contains valid version information.
  ///
  /// Checks if the output string contains patterns typical of version commands,
  /// such as version numbers or the word "version". This helps distinguish
  /// between successful version commands and other command outputs.
  bool _isValidVersionOutput(String output) {
    final String lowerOutput = output.toLowerCase();

    // Check for common version patterns
    return lowerOutput.contains('version') || lowerOutput.contains(RegExp(r'\d+\.\d+')) || lowerOutput.contains('kiro');
  }

  /// Parses the version string from the command output.
  ///
  /// Extracts version information from the `kiro --version` output,
  /// handling various output formats that different versions might produce.
  String? _parseVersionFromOutput(String output) {
    // Try to extract version number pattern (e.g., "1.2.3", "v1.2.3")
    final RegExp versionPattern = RegExp(r'v?(\d+\.\d+(?:\.\d+)?)');
    final Match? match = versionPattern.firstMatch(output);

    if (match != null) {
      return match.group(1);
    }

    // If no specific version pattern found, return the full output
    return output.isNotEmpty ? output : null;
  }
}

/// Exception thrown when Kiro detection encounters an unexpected error.
///
/// This exception is used for errors that are not related to Kiro being
/// unavailable, such as system errors, permission issues, or unexpected
/// command behavior.
class KiroDetectionException implements Exception {
  /// Human-readable error message describing what went wrong.
  final String message;

  /// Optional underlying cause of this exception.
  final Object? cause;

  /// Creates a new Kiro detection exception.
  ///
  /// @param message Description of the error that occurred
  /// @param cause Optional underlying exception that caused this error
  const KiroDetectionException(this.message, {this.cause});

  @override
  String toString() => 'KiroDetectionException: $message';
}

/// Exception thrown when a Kiro detection operation times out.
///
/// This can occur when the `kiro --version` command hangs or takes
/// longer than expected to respond.
class TimeoutException implements Exception {
  /// Description of the operation that timed out.
  final String message;

  /// Duration after which the timeout occurred.
  final Duration timeout;

  /// Creates a new timeout exception.
  ///
  /// @param message Description of the timed out operation
  /// @param timeout Duration that was exceeded
  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
