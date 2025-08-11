/// Context information for a conversation thread.
///
/// Provides additional metadata and context that influences
/// conversation behavior and system responses.
class ConversationContext {
  /// Creates a new conversation context.
  ///
  /// All parameters are optional and provide additional context
  /// for more intelligent conversation handling.
  const ConversationContext({this.applicationId, this.userId, this.sessionId, this.metadata});

  /// ID of the application being created or modified.
  ///
  /// Null for new application conversations. Set when modifying
  /// existing applications to provide context about current features.
  final String? applicationId;

  /// ID of the user participating in this conversation.
  ///
  /// Used for personalization, quota checking, and conversation
  /// history management across multiple sessions.
  final String? userId;

  /// Unique session identifier for this conversation.
  ///
  /// Used for tracking conversation sessions and correlating
  /// with backend processing and logging systems.
  final String? sessionId;

  /// Additional metadata for conversation context.
  ///
  /// Flexible key-value storage for conversation-specific
  /// information that may influence system behavior.
  final Map<String, dynamic>? metadata;

  /// Creates a ConversationContext from JSON data.
  ///
  /// Parses context data and creates a properly typed context object.
  /// All fields are optional and will be null if not provided.
  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      applicationId: json['applicationId'] as String?,
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts this context to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage. Null fields are omitted from the output.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (applicationId != null) json['applicationId'] = applicationId;
    if (userId != null) json['userId'] = userId;
    if (sessionId != null) json['sessionId'] = sessionId;
    if (metadata != null) json['metadata'] = metadata;

    return json;
  }

  /// Creates a copy of this context with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when conversation context evolves during the session.
  ConversationContext copyWith({
    String? applicationId,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationContext(
      applicationId: applicationId ?? this.applicationId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
    );
  }
}
