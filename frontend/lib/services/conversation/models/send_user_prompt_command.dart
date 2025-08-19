import 'kiro_command.dart';

/// Send a free‑form prompt/question to the Kiro agent via the bridge.
///
/// Uses `kiro.tools.userInput` as a transport so the agent can receive the text
/// and optionally correlate by a reason tag.
class SendUserPromptCommand implements KiroCommand {
  /// Creates a new [SendUserPromptCommand].
  ///
  /// - [prompt] is the user-provided text or question sent to the Kiro agent.
  /// - [reason] is an optional tag that explains the purpose of this prompt.
  SendUserPromptCommand({required this.prompt, this.reason = 'frontend-user-prompt'});

  /// The text or question provided by the user.
  final String prompt;

  /// A string describing the reason for the prompt, useful for correlation
  /// or tracing within the Kiro IDE.
  final String reason;

  /// Returns the command identifier used by the Kiro Bridge API.
  @override
  String get command => 'kiro.tools.userInput';

  /// Returns the list of arguments sent along with this command.
  ///
  /// Contains a single map with `question` and `reason` keys.
  @override
  List<Object?> get args => <Object?>[
        <String, Object?>{
          'question': prompt,
          'reason': reason,
        }
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
