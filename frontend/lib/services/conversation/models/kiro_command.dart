/// Abstraction for a command sent to the Kiro IDE Bridge.
abstract class KiroCommand {
  /// VS Code / Kiro command identifier, e.g. 'kiro.tools.userInput' or 'kiro.tools.readFile'.
  String get command;

  /// Arguments array passed to the command.
  List<Object?> get args;

  /// Serialize to JSON body for /api/kiro/execute
  Map<String, Object?> toJson({String? workspacePath}) => <String, Object?>{
    'command': command,
    if (workspacePath != null) 'workspacePath': workspacePath,
    if (args.isNotEmpty) 'args': args,
  };
}
