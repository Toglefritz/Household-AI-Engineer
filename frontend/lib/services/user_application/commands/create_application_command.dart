import '../../conversation/models/kiro_command.dart';

/// Command to create a new application through the Kiro Bridge.
///
/// This command initiates the creation of a new household application
/// based on the user's natural language description.
class CreateApplicationCommand implements KiroCommand {
  /// Creates a new create application command.
  ///
  /// * [description] - Natural language description of the desired application
  /// * [conversationId] - Optional conversation context ID
  /// * [priority] - Priority level for the development job ('low', 'normal', 'high')
  const CreateApplicationCommand({
    required this.description,
    this.conversationId,
    this.priority = 'normal',
  });

  /// Natural language description of the desired application.
  final String description;

  /// Optional conversation context ID for continuing an existing conversation.
  final String? conversationId;

  /// Priority level for the development job.
  final String priority;

  @override
  String get command => 'kiro.createApplication';

  @override
  List<Object?> get args => [
    {
      'description': description,
      if (conversationId != null) 'conversationId': conversationId,
      'priority': priority,
    },
  ];

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return {
      'command': 'kiro.createApplication',
      'args': [
        {
          'description': description,
          if (conversationId != null) 'conversationId': conversationId,
          'priority': priority,
        },
      ],
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
