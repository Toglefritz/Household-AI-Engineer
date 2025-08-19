import '../../conversation/models/kiro_command.dart';

/// Command to stop a running application through the Kiro Bridge.
///
/// This command gracefully stops a running application and updates its status.
/// The application can be launched again later if needed.
class StopApplicationCommand implements KiroCommand {
  /// Creates a new stop application command.
  ///
  /// * [applicationId] - ID of the application to stop
  const StopApplicationCommand({
    required this.applicationId,
  });

  /// ID of the application to stop.
  final String applicationId;

  @override
  String get command => 'kiro.stopApplication';

  @override
  List<Object?> get args => [applicationId];

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return {
      'command': command,
      'args': args,
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
