/// Represents the context and metadata for a conversation thread.
///
/// Contains information about the conversation's purpose, current state,
/// and any relevant context that should be preserved across messages.
class ConversationContext {
  /// Creates a new conversation context.
  ///
  /// @param purpose The purpose or goal of this conversation
  /// @param metadata Additional context information
  /// @param applicationId Optional ID of the application being created/modified
  const ConversationContext({
    required this.purpose,
    this.metadata = const {},
    this.applicationId,
  });

  /// The purpose or goal of this conversation.
  ///
  /// Describes what the conversation is trying to accomplish,
  /// such as "create_application" or "modify_application".
  final String purpose;

  /// Additional context information as key-value pairs.
  ///
  /// Can contain any relevant information that should be preserved
  /// across the conversation, such as user preferences, previous
  /// responses, or application requirements.
  final Map<String, dynamic> metadata;

  /// Optional ID of the application being created or modified.
  ///
  /// Set when the conversation is about modifying an existing
  /// application rather than creating a new one.
  final String? applicationId;

  /// Creates a ConversationContext from JSON data.
  ///
  /// @param json Map containing the context data
  /// @returns ConversationContext instance
  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      purpose: json['purpose'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>? ?? {}),
      applicationId: json['applicationId'] as String?,
    );
  }

  /// Converts this context to JSON format.
  ///
  /// @returns Map containing the context data
  Map<String, dynamic> toJson() {
    return {
      'purpose': purpose,
      'metadata': metadata,
      'applicationId': applicationId,
    };
  }

  /// Creates a copy of this context with updated fields.
  ///
  /// @param purpose Optional new purpose
  /// @param metadata Optional new metadata
  /// @param applicationId Optional new application ID
  /// @returns New ConversationContext with updated fields
  ConversationContext copyWith({
    String? purpose,
    Map<String, dynamic>? metadata,
    String? applicationId,
  }) {
    return ConversationContext(
      purpose: purpose ?? this.purpose,
      metadata: metadata ?? this.metadata,
      applicationId: applicationId ?? this.applicationId,
    );
  }

  /// Returns true if this conversation is about creating a new application.
  ///
  /// Convenience method for checking conversation purpose.
  bool get isCreatingApplication => purpose == 'create_application';

  /// Returns true if this conversation is about modifying an existing application.
  ///
  /// Convenience method for checking conversation purpose.
  bool get isModifyingApplication => purpose == 'modify_application' && applicationId != null;

  /// Gets a metadata value by key with optional type casting.
  ///
  /// @param key The metadata key to retrieve
  /// @returns The metadata value or null if not found
  T? getMetadata<T>(String key) {
    final dynamic value = metadata[key];
    return value is T ? value : null;
  }

  /// Sets a metadata value by key.
  ///
  /// @param key The metadata key to set
  /// @param value The value to set
  /// @returns New ConversationContext with updated metadata
  ConversationContext setMetadata(String key, dynamic value) {
    final Map<String, dynamic> newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Removes a metadata value by key.
  ///
  /// @param key The metadata key to remove
  /// @returns New ConversationContext with updated metadata
  ConversationContext removeMetadata(String key) {
    final Map<String, dynamic> newMetadata = Map<String, dynamic>.from(metadata)
    ..remove(key);
    return copyWith(metadata: newMetadata);
  }
}
