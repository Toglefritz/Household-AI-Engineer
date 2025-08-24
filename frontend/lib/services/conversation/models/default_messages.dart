import 'conversation_message.dart';
import 'message_action.dart';
import 'message_sender.dart';

/// Contains a collection of pre-written messages used to populate conversations with Kiro.
///
/// In some situations, it is useful to have some hard-coded, default messages that can be quickly displayed in
/// Kiro conversations without actually interacting with Kiro. For example, when the user initiates a conversation,
/// a default welcome message can be displayed.
class DefaultMessages {
  /// A message displayed when the user first initializes a conversation with Kiro to create a new application.
  ///
  /// @param messageId Unique identifier for this welcome message
  /// @returns ConversationMessage with welcome content and action suggestions
  static ConversationMessage getNewApplicationWelcomeMessage({
    required String messageId,
  }) {
    return ConversationMessage(
      id: messageId,
      sender: MessageSender.system,
      content:
          "Hi! I'll help you create a custom application for your household. What would you like to build?",
      timestamp: DateTime.now(),
      actions: [
        const MessageAction(
          id: 'welcome_action_001',
          label: 'Chore Tracker',
          value: 'I need a chore tracking app for my family',
        ),
        const MessageAction(
          id: 'welcome_action_002',
          label: 'Budget Planner',
          value: 'I want to track our household budget',
        ),
        const MessageAction(
          id: 'welcome_action_003',
          label: 'Recipe Organizer',
          value: 'Help me organize family recipes',
        ),
      ],
    );
  }

  /// A message displayed when the user first initializes a conversation with Kiro to modify an existing application.
  static ConversationMessage getModifyApplicationWelcomeMessage({
    required String messageId,
    required String applicationName,
  }) {
    return ConversationMessage(
      id: messageId,
      sender: MessageSender.system,
      content:
          'I can help you modify your $applicationName application. What changes would you like to make?',
      timestamp: DateTime.now(),
      actions: [
        const MessageAction(
          id: 'action_modify_001',
          label: 'Add Features',
          value: 'I want to add new features',
        ),
        const MessageAction(
          id: 'action_modify_002',
          label: 'Change Design',
          value: 'I want to change the design or layout',
        ),
        const MessageAction(
          id: 'action_modify_003',
          label: 'Fix Issues',
          value: 'There are some issues I want to fix',
        ),
      ],
    );
  }

  /// A system message that is added to messages by the user to help guide the Kiro IDE towards a mode of interaction
  /// with the user that allows a smooth user experience in this frontend application.
  static String getInteractionGuidanceInstructions() {
    return '''
    User Interaction Instructions: If the user's request is unclear, in the sense that ambiguity exists with regard
    to how the user's request should be fulfilled, ask the user for additional information. If such a request for
    additional information is necessary, the request should be phrased in simple and non-technical terms. Critically,
    any questions or clarification requiring input from the user must be added to the "developmentStatement" field in
    the manifest.json file for the project in order for the user to receive the question or request for clarification. 
    In all messages to the user, including those in the form of progress updates in manifest.json, avoid the use of 
    technical language. The user will interact with the applications and the overall system via a frontend UI so they 
    will not interact with the codebase directly.
    ''';
  }

  /// A system message that is added to messages by the user to help guide the Kiro IDE towards performing
  /// spec-driven updates rather than "vibe" requests when there is a task in the spec tasklist relevant to the user's
  /// query.
  static String getSpecGuidanceInstructions() {
    return '''
    System Instructions: If there is a task in the tasklist in the user-application-template spec, use it to 
    complete the request from the user. Also, regardless of whether a spec task is used for this request or not, be 
    sure to update the manifest.json file so it reflects the state of the user application after any updates are made.
    If a manifest.json file does not exist in the current directory, your first task should be to create one for the 
    current user application based on the example provided by manifest_example.json. The manifest.json file must
    conform to the schema in manifest_schema.json. After each task in the spec is completed, the manifest.json file 
    should be updated to allow consumers of this manifest file to stay update on development progress. Again, the
    updates to the manifest must conform to the schema in manifest_schema.json. The manifest.json file contains several
    timestamps. Always make sure to check the current time before updating these timestamps to make sure that the 
    information represented by the timestamps is accurate. Last, always attempt to complete the user's request without
    creating new specs because the user is unlikely to be able to write or confirm specs or tasks.
    
    Progress Communication: When updating the manifest.json file, always include a user-friendly "developmentStatement" 
    in the progress section. This statement should be written as a conversational message from you (Kiro IDE) to the 
    user, explaining what you're currently working on or what you've just completed. Keep it friendly, informative, 
    and encouraging. Examples: "I'm setting up the basic structure for your app now", "Great progress! I've just 
    finished the main interface and I'm now working on the data storage", "Almost there! Just putting the finishing 
    touches on your application". This statement will be displayed as a chat message to the user in the conversation 
    interface.
    ''';
  }

  /// A system message that guides Kiro to produce applications that are web-based and runnable locally
  /// with minimal or zero setup for non-technical users. Integrations with internal/external APIs must be
  /// simple and optional, with sensible fallbacks so the app still works offline.
  static String getAppTypeGuidanceInstructions() {
    return '''
    System Instructions: All user applications produced by this IDE must be web-based apps that can run locally
    (no servers required to try the app). Choose technologies appropriate to the problem (e.g., HTML/CSS/JS,
    Web Components, lightweight client frameworks, or Flutter Web), but ensure the resulting artifact can be opened
    locally in a browser or bundled as a desktop webview. Ideally, all applications will be able to run by simply
    opening an index.html file, without requiring any scripts or npm commands.

    Requirements:
    - Default to a self-contained client app runnable from local files.
    - Use simple, zero-setup integrations only. If the app needs data, prefer browser storage (LocalStorage/IndexedDB)
      or a single-call fetch to an internal/external API that requires **no user credentials or configuration**.
    - Do **not** require the user to install databases, CLIs, package managers, or cloud accounts to run the app.
    - If an API call is essential, provide stub/mock data fallbacks so the app still runs offline.
    - Keep configuration in plain JSON files within the app directory when possible.
    - Provide clear run instructions and generate any scaffolding files needed to run locally.

    Deliverables:
    - A minimal runnable web app (e.g., `index.html`, `styles.css`, `script.js`) or a Flutter Web build structure.
    - The user will launch the application from a frontend interface so no instructions need to be provided for starting
      the application.
    ''';
  }
}
