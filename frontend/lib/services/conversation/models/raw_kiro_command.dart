import 'kiro_command.dart';

/// Generic command with explicit command id and args.
class RawKiroCommand implements KiroCommand {
  /// Creates a new [RawKiroCommand] with the given [command] identifier
  /// and optional [args].
  ///
  /// - [command] is the identifier of the Kiro or VS Code command to execute.
  /// - [args] is an optional list of arguments passed along with the command.
  RawKiroCommand(this._command, [List<Object?>? args]) : _args = args ?? const <Object?>[];

  /// The command identifier string (e.g. `'kiro.tools.readFile'`).
  final String _command;

  /// The arguments to be passed when executing the command.
  final List<Object?> _args;

  /// Returns the command identifier string.
  @override
  String get command => _command;

  /// Returns the list of arguments associated with this command.
  @override
  List<Object?> get args => _args;

  @override
  Map<String, Object?> toJson({String? workspacePath}) {
    return <String, Object?>{
      'command': _command,
      if (_args.isNotEmpty) 'args': _args,
      if (workspacePath != null) 'workspacePath': workspacePath,
    };
  }
}
