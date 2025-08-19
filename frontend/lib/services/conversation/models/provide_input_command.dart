import 'kiro_command.dart';

/// Provide follow‑up input to a previously running execution flow.
class ProvideInputCommand implements KiroCommand {
  /// Creates a new [ProvideInputCommand].
  ///
  /// - [executionId] identifies the command execution instance to which
  ///   this input belongs.
  /// - [value] is the actual input content provided by the user.
  /// - [type] specifies the kind of input (e.g. 'text', 'confirmation').
  ProvideInputCommand({
    required this.executionId,
    required this.value,
    this.type = 'text',
  });

  /// The identifier of the execution instance awaiting this input.
  final String executionId;

  /// The input value being provided (e.g. user-entered text or confirmation).
  final String value;

  /// The type of the input, such as `'text'` or `'confirmation'`.
  final String type;

  /// Returns the command identifier string for providing input.
  @override
  String get command => 'kiro.tools.userInput';

  /// Returns the arguments list for this command, containing a map with
  /// `question`, `reason`, `executionId`, and `type` keys.
  @override
  List<Object?> get args => <Object?>[
    <String, Object?>{
      'question': value,
      'reason': 'followup',
      'executionId': executionId,
      'type': type,
    },
  ];

  /// Serializes this command to JSON for use with the Kiro Bridge API.
  ///
  /// Includes `command`, `args`, and optionally `workspacePath` if provided.
  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return <String, Object?>{
      'command': command,
      'args': args,
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
