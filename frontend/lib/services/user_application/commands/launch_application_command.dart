import '../../conversation/models/kiro_command.dart';

/// Command to launch an application through the Kiro Bridge.
///
/// This command starts a ready application and makes it available for use.
/// The application must be in a ready state to be launched successfully.
class LaunchApplicationCommand implements KiroCommand {
  /// Creates a new launch application command.
  ///
  /// * [applicationId] - ID of the application to launch
  const LaunchApplicationCommand({
    required this.applicationId,
  });

  /// ID of the application to launch.
  final String applicationId;

  @override
  String get command => 'kiro.launchApplication';

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
