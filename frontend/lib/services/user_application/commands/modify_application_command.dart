import '../../conversation/models/kiro_command.dart';

/// Command to modify an existing application through the Kiro Bridge.
///
/// This command initiates modifications to an existing household application
/// based on the user's natural language description of desired changes.
class ModifyApplicationCommand implements KiroCommand {
  /// Creates a new modify application command.
  ///
  /// * [applicationId] - ID of the application to modify
  /// * [modifications] - Natural language description of desired modifications
  /// * [conversationId] - Optional conversation context ID
  const ModifyApplicationCommand({
    required this.applicationId,
    required this.modifications,
    this.conversationId,
  });

  /// ID of the application to modify.
  final String applicationId;

  /// Natural language description of desired modifications.
  final String modifications;

  /// Optional conversation context ID for continuing an existing conversation.
  final String? conversationId;

  @override
  String get command => 'kiro.modifyApplication';

  @override
  List<Object?> get args => [
        {
          'applicationId': applicationId,
          'modifications': modifications,
          if (conversationId != null) 'conversationId': conversationId,
        },
      ];

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return {
      'command': command,
      'args': args,
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
