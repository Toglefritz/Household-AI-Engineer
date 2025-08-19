import '../../conversation/models/kiro_command.dart';

/// Command to delete an application through the Kiro Bridge.
///
/// This command removes an application from the system and cleans up
/// associated resources. This operation cannot be undone.
class DeleteApplicationCommand implements KiroCommand {
  /// Creates a new delete application command.
  ///
  /// * [applicationId] - ID of the application to delete
  const DeleteApplicationCommand({
    required this.applicationId,
  });

  /// ID of the application to delete.
  final String applicationId;

  @override
  String get command => 'kiro.deleteApplication';

  @override
  List<Object?> get args => [applicationId];

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return {
      'command': 'kiro.deleteApplication',
      'args': [applicationId],
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
