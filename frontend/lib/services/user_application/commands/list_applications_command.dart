import '../../conversation/models/kiro_command.dart';

/// Command to list all applications from the Kiro Bridge.
///
/// This command retrieves the current list of applications managed by the
/// Kiro system, including their status, progress, and metadata.
class ListApplicationsCommand implements KiroCommand {
  /// Creates a new list applications command.
  const ListApplicationsCommand();

  @override
  String get command => 'kiro.listApplications';

  @override
  List<Object?> get args => [];

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return {
      'command': command,
      'args': args,
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
