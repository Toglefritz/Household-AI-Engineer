# Kiro Commands

This document presents a comprehensive list of commands related to Kiro from the Kiro IDE, as discovered and analyzed by the kiro-command-logger extension. The extension automatically scans the VS Code command registry to identify all Kiro-related commands, categorizes them by functionality, and monitors their usage patterns.

The data below includes both `kiroAgent` commands (the core AI assistant functionality) and other `kiro` commands (platform features like specs, steering, and subscription management), providing developers with a complete reference of available Kiro IDE capabilities.

---

2025-08-13T00:31:38.107Z: Kiro Command Logger extension activated
2025-08-13T00:31:38.107Z: Discovering Kiro commands and monitoring command execution...
2025-08-13T00:31:38.107Z: Starting command discovery...
2025-08-13T00:31:38.107Z: Command discovery and monitoring started
2025-08-13T00:31:38.107Z: Extension will periodically scan for new Kiro commands
2025-08-13T00:31:38.122Z: Found 2713 total registered commands

2025-08-13T00:31:38.123Z: Found 131 kiroAgent commands:

2025-08-13T00:31:38.123Z:   1. kiroAgent.onboarding.resetOnboardingCompleteStatus
2025-08-13T00:31:38.123Z:   2. kiroAgent.views.hooksStatus.focus
2025-08-13T00:31:38.123Z:   3. kiroAgent.views.hooksStatus.resetViewLocation
2025-08-13T00:31:38.123Z:   4. kiroAgent.views.steeringExplorer.focus
2025-08-13T00:31:38.123Z:   5. kiroAgent.views.steeringExplorer.resetViewLocation
2025-08-13T00:31:38.123Z:   6. kiroAgent.views.mcpServerStatus.focus
2025-08-13T00:31:38.123Z:   7. kiroAgent.views.mcpServerStatus.resetViewLocation
2025-08-13T00:31:38.123Z:   8. kiroAgent.continueGUIView.focus
2025-08-13T00:31:38.123Z:   9. kiroAgent.continueGUIView.resetViewLocation
2025-08-13T00:31:38.123Z:   10. kiroAgent.continueGUIView.toggleVisibility
2025-08-13T00:31:38.123Z:   11. kiroAgent.continueGUIView.removeView
2025-08-13T00:31:38.123Z:   12. kiroAgent.views.hooksStatus.toggleVisibility
2025-08-13T00:31:38.123Z:   13. kiroAgent.views.hooksStatus.removeView
2025-08-13T00:31:38.123Z:   14. kiroAgent.views.steeringExplorer.toggleVisibility
2025-08-13T00:31:38.123Z:   15. kiroAgent.views.steeringExplorer.removeView
2025-08-13T00:31:38.123Z:   16. kiroAgent.views.mcpServerStatus.toggleVisibility
2025-08-13T00:31:38.123Z:   17. kiroAgent.views.mcpServerStatus.removeView
2025-08-13T00:31:38.123Z:   18. kiroAgent.debug.openMetadata
2025-08-13T00:31:38.123Z:   19. kiroAgent.debug.purgeMetadata
2025-08-13T00:31:38.123Z:   20. kiroAgent.hooks.create
2025-08-13T00:31:38.123Z:   21. kiroAgent.hooks.delete
2025-08-13T00:31:38.123Z:   22. kiroAgent.hooks.read
2025-08-13T00:31:38.123Z:   23. kiroAgent.hooks.setEnabled
2025-08-13T00:31:38.123Z:   24. kiroAgent.hooks.getEnabled
2025-08-13T00:31:38.123Z:   25. kiroAgent.hooks.trigger
2025-08-13T00:31:38.123Z:   26. kiroAgent.hooks.syncRunningState
2025-08-13T00:31:38.123Z:   27. kiroAgent.onboarding.checkSteps
2025-08-13T00:31:38.123Z:   28. kiroAgent.onboarding.checkStep
2025-08-13T00:31:38.123Z:   29. kiroAgent.onboarding.executeStep
2025-08-13T00:31:38.123Z:   30. kiroAgent.configuration.completeOnboarding
2025-08-13T00:31:38.123Z:   31. kiroAgent.configuration.startOnboarding
2025-08-13T00:31:38.123Z:   32. kiroAgent.debug.captureLog
2025-08-13T00:31:38.123Z:   33. kiroAgent.debug.captureLLMLog
2025-08-13T00:31:38.123Z:   34. kiroAgent.deleteAccount
2025-08-13T00:31:38.123Z:   35. kiroAgent.enableShellIntegration
2025-08-13T00:31:38.123Z:   36. kiroAgent.revealFile
2025-08-13T00:31:38.123Z:   37. kiroAgent.fileFeedback
2025-08-13T00:31:38.123Z:   38. kiroAgent.createDebugLogZip
2025-08-13T00:31:38.123Z:   39. kiroAgent.initiateSpecCreation
2025-08-13T00:31:38.123Z:   40. kiroAgent.openExecutionLogView
2025-08-13T00:31:38.123Z:   41. kiroAgent.agent.promptAgent
2025-08-13T00:31:38.123Z:   42. kiroAgent.agent.askAgent
2025-08-13T00:31:38.123Z:   43. kiroAgent.agent.chatAgent
2025-08-13T00:31:38.123Z:   44. kiroAgent.executions.retryAgent
2025-08-13T00:31:38.123Z:   45. kiroAgent.executions.compactAgent
2025-08-13T00:31:38.123Z:   46. kiroAgent.getTokenUsage
2025-08-13T00:31:38.123Z:   47. kiroAgent.recordReferences
2025-08-13T00:31:38.123Z:   48. kiroAgent.executions.getExecutionHistory
2025-08-13T00:31:38.123Z:   49. kiroAgent.executions.getQueuedExecutions
2025-08-13T00:31:38.123Z:   50. kiroAgent.executions.getExecutionById
2025-08-13T00:31:38.123Z:   51. kiroAgent.executions.getExecutions
2025-08-13T00:31:38.123Z:   52. kiroAgent.executions.extractLastExecutionPaths
2025-08-13T00:31:38.123Z:   53. kiroAgent.executions.abortActiveAgent
2025-08-13T00:31:38.123Z:   54. kiroAgent.executions.triggerAgent
2025-08-13T00:31:38.123Z:   55. kiroAgent.executions.addToExecution
2025-08-13T00:31:38.123Z:   56. kiroAgent.execution.viewExecutionChanges
2025-08-13T00:31:38.123Z:   57. kiroAgent.execution.getExecutionChanges
2025-08-13T00:31:38.123Z:   58. kiroAgent.execution.applyPendingChanges
2025-08-13T00:31:38.123Z:   59. kiroAgent.execution.restorePendingChanges
2025-08-13T00:31:38.123Z:   60. kiroAgent.execution.restoreAllChanges
2025-08-13T00:31:38.123Z:   61. kiroAgent.checkpoint.acceptDiff
2025-08-13T00:31:38.123Z:   62. kiroAgent.executions.acceptUserResponse
2025-08-13T00:31:38.123Z:   63. kiroAgent.executions.uiControl
2025-08-13T00:31:38.123Z:   64. kiroAgent.mcp.showLogs
2025-08-13T00:31:38.123Z:   65. kiroAgent.mcp.debugServer
2025-08-13T00:31:38.123Z:   66. kiroAgent.mcp.testTool
2025-08-13T00:31:38.123Z:   67. kiroAgent.mcp.enable
2025-08-13T00:31:38.123Z:   68. kiroAgent.views.mcpServerStatus.refresh
2025-08-13T00:31:38.123Z:   69. kiroAgent.mcp.resetConnection
2025-08-13T00:31:38.123Z:   70. kiroAgent.hooks.updateUI
2025-08-13T00:31:38.123Z:   71. kiroAgent.hooks.handleRetryGenerate
2025-08-13T00:31:38.123Z:   72. kiroAgent.hooks.setLoading
2025-08-13T00:31:38.123Z:   73. kiroAgent.hooks.setRunning
2025-08-13T00:31:38.123Z:   74. kiroAgent.hooks.openUI
2025-08-13T00:31:38.123Z:   75. kiroAgent.hooks.upgrade
2025-08-13T00:31:38.123Z:   76. kiroAgent.hooks.createNew
2025-08-13T00:31:38.123Z:   77. kiroAgent.hooks.openHookFile
2025-08-13T00:31:38.123Z:   78. kiroAgent.steering.getSteering
2025-08-13T00:31:38.123Z:   79. kiroAgent.context.pickProviderSubmenu
2025-08-13T00:31:38.123Z:   80. kiroAgent.inlineChat.start
2025-08-13T00:31:38.123Z:   81. kiroAgent.acceptDiff
2025-08-13T00:31:38.123Z:   82. kiroAgent.rejectDiff
2025-08-13T00:31:38.123Z:   83. kiroAgent.acceptVerticalDiffBlock
2025-08-13T00:31:38.123Z:   84. kiroAgent.rejectVerticalDiffBlock
2025-08-13T00:31:38.123Z:   85. kiroAgent.quickFix
2025-08-13T00:31:38.123Z:   86. kiroAgent.defaultQuickAction
2025-08-13T00:31:38.123Z:   87. kiroAgent.customQuickActionSendToChat
2025-08-13T00:31:38.123Z:   88. kiroAgent.customQuickActionStreamInlineEdit
2025-08-13T00:31:38.123Z:   89. kiroAgent.codebaseForceReIndex
2025-08-13T00:31:38.123Z:   90. kiroAgent.rebuildCodebaseIndex
2025-08-13T00:31:38.123Z:   91. kiroAgent.docsIndex
2025-08-13T00:31:38.123Z:   92. kiroAgent.docsReIndex
2025-08-13T00:31:38.123Z:   93. kiroAgent.userInputFocusNoSubmit
2025-08-13T00:31:38.123Z:   94. kiroAgent.focusContinueInput
2025-08-13T00:31:38.123Z:   95. kiroAgent.focusContinueInputWithoutClear
2025-08-13T00:31:38.123Z:   96. kiroAgent.quickEdit
2025-08-13T00:31:38.123Z:   97. kiroAgent.writeCommentsForCode
2025-08-13T00:31:38.123Z:   98. kiroAgent.writeDocstringForCode
2025-08-13T00:31:38.123Z:   99. kiroAgent.fixCode
2025-08-13T00:31:38.123Z:   100. kiroAgent.optimizeCode
2025-08-13T00:31:38.123Z:   101. kiroAgent.fixGrammar
2025-08-13T00:31:38.123Z:   102. kiroAgent.viewLogs
2025-08-13T00:31:38.123Z:   103. kiroAgent.debugTerminal
2025-08-13T00:31:38.123Z:   104. kiroAgent.hideInlineTip
2025-08-13T00:31:38.123Z:   105. kiroAgent.addModel
2025-08-13T00:31:38.123Z:   106. kiroAgent.openSettingsUI
2025-08-13T00:31:38.123Z:   107. kiroAgent.sendMainUserInput
2025-08-13T00:31:38.123Z:   108. kiroAgent.selectRange
2025-08-13T00:31:38.123Z:   109. kiroAgent.foldAndUnfold
2025-08-13T00:31:38.123Z:   110. kiroAgent.sendToTerminal
2025-08-13T00:31:38.123Z:   111. kiroAgent.newSession
2025-08-13T00:31:38.123Z:   112. kiroAgent.showExecutionInChatTab
2025-08-13T00:31:38.123Z:   113. kiroAgent.viewHistoryChats
2025-08-13T00:31:38.123Z:   114. kiroAgent.viewLetsBuild
2025-08-13T00:31:38.123Z:   115. kiroAgent.viewHome
2025-08-13T00:31:38.123Z:   116. kiroAgent.openConfigJson
2025-08-13T00:31:38.123Z:   117. kiroAgent.selectFilesAsContext
2025-08-13T00:31:38.123Z:   118. kiroAgent.logAutocompleteOutcome
2025-08-13T00:31:38.123Z:   119. kiroAgent.toggleTabAutocompleteEnabled
2025-08-13T00:31:38.123Z:   120. kiroAgent.openTabAutocompleteConfigMenu
2025-08-13T00:31:38.123Z:   121. kiroAgent.loadContextProviderItems
2025-08-13T00:31:38.123Z:   122. kiroAgent.provideContext
2025-08-13T00:31:38.123Z:   123. kiroAgent.workspaceIndex.status
2025-08-13T00:31:38.123Z:   124. kiroAgent.workspaceIndex.provideContext
2025-08-13T00:31:38.123Z:   125. kiroAgent.getAutonomyMode
2025-08-13T00:31:38.123Z:   126. kiroAgent.setAutonomyMode
2025-08-13T00:31:38.123Z:   127. kiroAgent.openWorkspaceMcpConfig
2025-08-13T00:31:38.123Z:   128. kiroAgent.openUserMcpConfig
2025-08-13T00:31:38.123Z:   129. kiroAgent.openActiveMcpConfig
2025-08-13T00:31:38.123Z:   130. kiroAgent.openMcpConfigForServerName
2025-08-13T00:31:38.123Z:   131. kiroAgent.updateCoachingStatus

2025-08-13T00:31:38.123Z: === KIRO AGENT COMMAND ANALYSIS ===

2025-08-13T00:31:38.123Z: Total kiroAgent commands: 131

2025-08-13T00:31:38.123Z: Commands by functionality:
2025-08-13T00:31:38.123Z:   CHAT: 5 commands
2025-08-13T00:31:38.123Z:     - agent.chatAgent (kiroAgent.agent.chatAgent)
2025-08-13T00:31:38.123Z:     - inlineChat.start (kiroAgent.inlineChat.start)
2025-08-13T00:31:38.123Z:     - customQuickActionSendToChat (kiroAgent.customQuickActionSendToChat)
2025-08-13T00:31:38.123Z:     - showExecutionInChatTab (kiroAgent.showExecutionInChatTab)
2025-08-13T00:31:38.123Z:     - viewHistoryChats (kiroAgent.viewHistoryChats)
2025-08-13T00:31:38.123Z:   FILE: 4 commands
2025-08-13T00:31:38.123Z:     - revealFile (kiroAgent.revealFile)
2025-08-13T00:31:38.123Z:     - fileFeedback (kiroAgent.fileFeedback)
2025-08-13T00:31:38.123Z:     - hooks.openHookFile (kiroAgent.hooks.openHookFile)
2025-08-13T00:31:38.123Z:     - selectFilesAsContext (kiroAgent.selectFilesAsContext)
2025-08-13T00:31:38.123Z:   EDITOR: 4 commands
2025-08-13T00:31:38.123Z:     - context.pickProviderSubmenu (kiroAgent.context.pickProviderSubmenu)
2025-08-13T00:31:38.123Z:     - loadContextProviderItems (kiroAgent.loadContextProviderItems)
2025-08-13T00:31:38.123Z:     - provideContext (kiroAgent.provideContext)
2025-08-13T00:31:38.123Z:     - workspaceIndex.provideContext (kiroAgent.workspaceIndex.provideContext)
2025-08-13T00:31:38.123Z:   WORKSPACE: 2 commands
2025-08-13T00:31:38.123Z:     - workspaceIndex.status (kiroAgent.workspaceIndex.status)
2025-08-13T00:31:38.123Z:     - openWorkspaceMcpConfig (kiroAgent.openWorkspaceMcpConfig)
2025-08-13T00:31:38.123Z:   UI: 31 commands
2025-08-13T00:31:38.123Z:     - views.hooksStatus.focus (kiroAgent.views.hooksStatus.focus)
2025-08-13T00:31:38.123Z:     - views.hooksStatus.resetViewLocation (kiroAgent.views.hooksStatus.resetViewLocation)
2025-08-13T00:31:38.123Z:     - views.steeringExplorer.focus (kiroAgent.views.steeringExplorer.focus)
2025-08-13T00:31:38.123Z:     - views.steeringExplorer.resetViewLocation (kiroAgent.views.steeringExplorer.resetViewLocation)
2025-08-13T00:31:38.123Z:     - views.mcpServerStatus.focus (kiroAgent.views.mcpServerStatus.focus)
2025-08-13T00:31:38.123Z:     - views.mcpServerStatus.resetViewLocation (kiroAgent.views.mcpServerStatus.resetViewLocation)
2025-08-13T00:31:38.123Z:     - continueGUIView.focus (kiroAgent.continueGUIView.focus)
2025-08-13T00:31:38.123Z:     - continueGUIView.resetViewLocation (kiroAgent.continueGUIView.resetViewLocation)
2025-08-13T00:31:38.123Z:     - continueGUIView.toggleVisibility (kiroAgent.continueGUIView.toggleVisibility)
2025-08-13T00:31:38.123Z:     - continueGUIView.removeView (kiroAgent.continueGUIView.removeView)
2025-08-13T00:31:38.123Z:     - views.hooksStatus.toggleVisibility (kiroAgent.views.hooksStatus.toggleVisibility)
2025-08-13T00:31:38.123Z:     - views.hooksStatus.removeView (kiroAgent.views.hooksStatus.removeView)
2025-08-13T00:31:38.123Z:     - views.steeringExplorer.toggleVisibility (kiroAgent.views.steeringExplorer.toggleVisibility)
2025-08-13T00:31:38.123Z:     - views.steeringExplorer.removeView (kiroAgent.views.steeringExplorer.removeView)
2025-08-13T00:31:38.123Z:     - views.mcpServerStatus.toggleVisibility (kiroAgent.views.mcpServerStatus.toggleVisibility)
2025-08-13T00:31:38.123Z:     - views.mcpServerStatus.removeView (kiroAgent.views.mcpServerStatus.removeView)
2025-08-13T00:31:38.123Z:     - openExecutionLogView (kiroAgent.openExecutionLogView)
2025-08-13T00:31:38.123Z:     - execution.viewExecutionChanges (kiroAgent.execution.viewExecutionChanges)
2025-08-13T00:31:38.123Z:     - executions.uiControl (kiroAgent.executions.uiControl)
2025-08-13T00:31:38.123Z:     - views.mcpServerStatus.refresh (kiroAgent.views.mcpServerStatus.refresh)
2025-08-13T00:31:38.123Z:     - hooks.updateUI (kiroAgent.hooks.updateUI)
2025-08-13T00:31:38.123Z:     - hooks.openUI (kiroAgent.hooks.openUI)
2025-08-13T00:31:38.123Z:     - quickFix (kiroAgent.quickFix)
2025-08-13T00:31:38.123Z:     - defaultQuickAction (kiroAgent.defaultQuickAction)
2025-08-13T00:31:38.123Z:     - customQuickActionStreamInlineEdit (kiroAgent.customQuickActionStreamInlineEdit)
2025-08-13T00:31:38.123Z:     - rebuildCodebaseIndex (kiroAgent.rebuildCodebaseIndex)
2025-08-13T00:31:38.123Z:     - quickEdit (kiroAgent.quickEdit)
2025-08-13T00:31:38.123Z:     - viewLogs (kiroAgent.viewLogs)
2025-08-13T00:31:38.123Z:     - openSettingsUI (kiroAgent.openSettingsUI)
2025-08-13T00:31:38.123Z:     - viewLetsBuild (kiroAgent.viewLetsBuild)
2025-08-13T00:31:38.123Z:     - viewHome (kiroAgent.viewHome)
2025-08-13T00:31:38.123Z:   SETTINGS: 7 commands
2025-08-13T00:31:38.123Z:     - configuration.completeOnboarding (kiroAgent.configuration.completeOnboarding)
2025-08-13T00:31:38.123Z:     - configuration.startOnboarding (kiroAgent.configuration.startOnboarding)
2025-08-13T00:31:38.123Z:     - openConfigJson (kiroAgent.openConfigJson)
2025-08-13T00:31:38.123Z:     - openTabAutocompleteConfigMenu (kiroAgent.openTabAutocompleteConfigMenu)
2025-08-13T00:31:38.123Z:     - openUserMcpConfig (kiroAgent.openUserMcpConfig)
2025-08-13T00:31:38.123Z:     - openActiveMcpConfig (kiroAgent.openActiveMcpConfig)
2025-08-13T00:31:38.123Z:     - openMcpConfigForServerName (kiroAgent.openMcpConfigForServerName)
2025-08-13T00:31:38.123Z:   OTHER: 78 commands
2025-08-13T00:31:38.123Z:     - onboarding.resetOnboardingCompleteStatus (kiroAgent.onboarding.resetOnboardingCompleteStatus)
2025-08-13T00:31:38.123Z:     - debug.openMetadata (kiroAgent.debug.openMetadata)
2025-08-13T00:31:38.123Z:     - debug.purgeMetadata (kiroAgent.debug.purgeMetadata)
2025-08-13T00:31:38.123Z:     - hooks.create (kiroAgent.hooks.create)
2025-08-13T00:31:38.123Z:     - hooks.delete (kiroAgent.hooks.delete)
2025-08-13T00:31:38.123Z:     - hooks.read (kiroAgent.hooks.read)
2025-08-13T00:31:38.123Z:     - hooks.setEnabled (kiroAgent.hooks.setEnabled)
2025-08-13T00:31:38.123Z:     - hooks.getEnabled (kiroAgent.hooks.getEnabled)
2025-08-13T00:31:38.123Z:     - hooks.trigger (kiroAgent.hooks.trigger)
2025-08-13T00:31:38.123Z:     - hooks.syncRunningState (kiroAgent.hooks.syncRunningState)
2025-08-13T00:31:38.123Z:     - onboarding.checkSteps (kiroAgent.onboarding.checkSteps)
2025-08-13T00:31:38.123Z:     - onboarding.checkStep (kiroAgent.onboarding.checkStep)
2025-08-13T00:31:38.123Z:     - onboarding.executeStep (kiroAgent.onboarding.executeStep)
2025-08-13T00:31:38.123Z:     - debug.captureLog (kiroAgent.debug.captureLog)
2025-08-13T00:31:38.123Z:     - debug.captureLLMLog (kiroAgent.debug.captureLLMLog)
2025-08-13T00:31:38.123Z:     - deleteAccount (kiroAgent.deleteAccount)
2025-08-13T00:31:38.123Z:     - enableShellIntegration (kiroAgent.enableShellIntegration)
2025-08-13T00:31:38.123Z:     - createDebugLogZip (kiroAgent.createDebugLogZip)
2025-08-13T00:31:38.123Z:     - initiateSpecCreation (kiroAgent.initiateSpecCreation)
2025-08-13T00:31:38.123Z:     - agent.promptAgent (kiroAgent.agent.promptAgent)
2025-08-13T00:31:38.123Z:     - agent.askAgent (kiroAgent.agent.askAgent)
2025-08-13T00:31:38.123Z:     - executions.retryAgent (kiroAgent.executions.retryAgent)
2025-08-13T00:31:38.123Z:     - executions.compactAgent (kiroAgent.executions.compactAgent)
2025-08-13T00:31:38.123Z:     - getTokenUsage (kiroAgent.getTokenUsage)
2025-08-13T00:31:38.123Z:     - recordReferences (kiroAgent.recordReferences)
2025-08-13T00:31:38.123Z:     - executions.getExecutionHistory (kiroAgent.executions.getExecutionHistory)
2025-08-13T00:31:38.123Z:     - executions.getQueuedExecutions (kiroAgent.executions.getQueuedExecutions)
2025-08-13T00:31:38.123Z:     - executions.getExecutionById (kiroAgent.executions.getExecutionById)
2025-08-13T00:31:38.123Z:     - executions.getExecutions (kiroAgent.executions.getExecutions)
2025-08-13T00:31:38.123Z:     - executions.extractLastExecutionPaths (kiroAgent.executions.extractLastExecutionPaths)
2025-08-13T00:31:38.123Z:     - executions.abortActiveAgent (kiroAgent.executions.abortActiveAgent)
2025-08-13T00:31:38.123Z:     - executions.triggerAgent (kiroAgent.executions.triggerAgent)
2025-08-13T00:31:38.123Z:     - executions.addToExecution (kiroAgent.executions.addToExecution)
2025-08-13T00:31:38.123Z:     - execution.getExecutionChanges (kiroAgent.execution.getExecutionChanges)
2025-08-13T00:31:38.123Z:     - execution.applyPendingChanges (kiroAgent.execution.applyPendingChanges)
2025-08-13T00:31:38.123Z:     - execution.restorePendingChanges (kiroAgent.execution.restorePendingChanges)
2025-08-13T00:31:38.123Z:     - execution.restoreAllChanges (kiroAgent.execution.restoreAllChanges)
2025-08-13T00:31:38.123Z:     - checkpoint.acceptDiff (kiroAgent.checkpoint.acceptDiff)
2025-08-13T00:31:38.123Z:     - executions.acceptUserResponse (kiroAgent.executions.acceptUserResponse)
2025-08-13T00:31:38.123Z:     - mcp.showLogs (kiroAgent.mcp.showLogs)
2025-08-13T00:31:38.123Z:     - mcp.debugServer (kiroAgent.mcp.debugServer)
2025-08-13T00:31:38.123Z:     - mcp.testTool (kiroAgent.mcp.testTool)
2025-08-13T00:31:38.123Z:     - mcp.enable (kiroAgent.mcp.enable)
2025-08-13T00:31:38.123Z:     - mcp.resetConnection (kiroAgent.mcp.resetConnection)
2025-08-13T00:31:38.123Z:     - hooks.handleRetryGenerate (kiroAgent.hooks.handleRetryGenerate)
2025-08-13T00:31:38.123Z:     - hooks.setLoading (kiroAgent.hooks.setLoading)
2025-08-13T00:31:38.123Z:     - hooks.setRunning (kiroAgent.hooks.setRunning)
2025-08-13T00:31:38.123Z:     - hooks.upgrade (kiroAgent.hooks.upgrade)
2025-08-13T00:31:38.123Z:     - hooks.createNew (kiroAgent.hooks.createNew)
2025-08-13T00:31:38.123Z:     - steering.getSteering (kiroAgent.steering.getSteering)
2025-08-13T00:31:38.123Z:     - acceptDiff (kiroAgent.acceptDiff)
2025-08-13T00:31:38.123Z:     - rejectDiff (kiroAgent.rejectDiff)
2025-08-13T00:31:38.123Z:     - acceptVerticalDiffBlock (kiroAgent.acceptVerticalDiffBlock)
2025-08-13T00:31:38.123Z:     - rejectVerticalDiffBlock (kiroAgent.rejectVerticalDiffBlock)
2025-08-13T00:31:38.123Z:     - codebaseForceReIndex (kiroAgent.codebaseForceReIndex)
2025-08-13T00:31:38.123Z:     - docsIndex (kiroAgent.docsIndex)
2025-08-13T00:31:38.123Z:     - docsReIndex (kiroAgent.docsReIndex)
2025-08-13T00:31:38.123Z:     - userInputFocusNoSubmit (kiroAgent.userInputFocusNoSubmit)
2025-08-13T00:31:38.123Z:     - focusContinueInput (kiroAgent.focusContinueInput)
2025-08-13T00:31:38.123Z:     - focusContinueInputWithoutClear (kiroAgent.focusContinueInputWithoutClear)
2025-08-13T00:31:38.123Z:     - writeCommentsForCode (kiroAgent.writeCommentsForCode)
2025-08-13T00:31:38.123Z:     - writeDocstringForCode (kiroAgent.writeDocstringForCode)
2025-08-13T00:31:38.123Z:     - fixCode (kiroAgent.fixCode)
2025-08-13T00:31:38.123Z:     - optimizeCode (kiroAgent.optimizeCode)
2025-08-13T00:31:38.123Z:     - fixGrammar (kiroAgent.fixGrammar)
2025-08-13T00:31:38.123Z:     - debugTerminal (kiroAgent.debugTerminal)
2025-08-13T00:31:38.123Z:     - hideInlineTip (kiroAgent.hideInlineTip)
2025-08-13T00:31:38.123Z:     - addModel (kiroAgent.addModel)
2025-08-13T00:31:38.123Z:     - sendMainUserInput (kiroAgent.sendMainUserInput)
2025-08-13T00:31:38.123Z:     - selectRange (kiroAgent.selectRange)
2025-08-13T00:31:38.123Z:     - foldAndUnfold (kiroAgent.foldAndUnfold)
2025-08-13T00:31:38.123Z:     - sendToTerminal (kiroAgent.sendToTerminal)
2025-08-13T00:31:38.123Z:     - newSession (kiroAgent.newSession)
2025-08-13T00:31:38.123Z:     - logAutocompleteOutcome (kiroAgent.logAutocompleteOutcome)
2025-08-13T00:31:38.123Z:     - toggleTabAutocompleteEnabled (kiroAgent.toggleTabAutocompleteEnabled)
2025-08-13T00:31:38.123Z:     - getAutonomyMode (kiroAgent.getAutonomyMode)
2025-08-13T00:31:38.123Z:     - setAutonomyMode (kiroAgent.setAutonomyMode)
2025-08-13T00:31:38.123Z:     - updateCoachingStatus (kiroAgent.updateCoachingStatus)

2025-08-13T00:31:38.123Z: === END KIRO AGENT ANALYSIS ===

2025-08-13T00:31:38.123Z: Found 29 other kiro commands:
2025-08-13T00:31:38.123Z:   1. kiro.subscriptionPlans.showSubscriptionPlans
2025-08-13T00:31:38.123Z:   2. kiro.accountDashboard.showDashboard
2025-08-13T00:31:38.123Z:   3. kiro.views.emptyWorkspace.focus
2025-08-13T00:31:38.123Z:   4. kiro.views.emptyWorkspace.resetViewLocation
2025-08-13T00:31:38.123Z:   5. kiro.views.specExplorer.focus
2025-08-13T00:31:38.123Z:   6. kiro.views.specExplorer.resetViewLocation
2025-08-13T00:31:38.123Z:   7. kiro.views.specExplorer.toggleVisibility
2025-08-13T00:31:38.123Z:   8. kiro.views.specExplorer.removeView
2025-08-13T00:31:38.123Z:   9. kiro.usageLimits.enableOverages
2025-08-13T00:31:38.123Z:   10. kiro.subscriptionPlans.getPortalSessionUrl
2025-08-13T00:31:38.123Z:   11. kiro.usageLimits.getUsageLimits
2025-08-13T00:31:38.123Z:   12. kiro.subscriptionPlans.getSubscriptionPlans
2025-08-13T00:31:38.123Z:   13. kiro.subscriptionPlans.getCheckoutSessionUrl
2025-08-13T00:31:38.123Z:   14. kiro.spec.refreshRequirementsFile
2025-08-13T00:31:38.123Z:   15. kiro.spec.refreshDesignFile
2025-08-13T00:31:38.123Z:   16. kiro.spec.refreshPlanFile
2025-08-13T00:31:38.123Z:   17. kiro.spec.nextDocument
2025-08-13T00:31:38.123Z:   18. kiro.spec.previousDocument
2025-08-13T00:31:38.123Z:   19. kiro.spec.navigateToRequirements
2025-08-13T00:31:38.123Z:   20. kiro.spec.navigateToDesign
2025-08-13T00:31:38.123Z:   21. kiro.spec.navigateToTasks
2025-08-13T00:31:38.123Z:   22. kiro.spec.explorerCreateSpec
2025-08-13T00:31:38.123Z:   23. kiro.spec.explorerDeleteSpec
2025-08-13T00:31:38.123Z:   24. kiro.config.getWorkspaceState
2025-08-13T00:31:38.123Z:   25. kiro.config.setWorkspaceState
2025-08-13T00:31:38.123Z:   26. kiro.steering.createInitialSteering
2025-08-13T00:31:38.123Z:   27. kiro.steering.createSteering
2025-08-13T00:31:38.123Z:   28. kiro.steering.deleteSteering
2025-08-13T00:31:38.123Z:   29. kiro.steering.refineSteeringFile

2025-08-13T00:31:38.123Z: === COMMAND DISCOVERY SUMMARY ===

2025-08-13T00:31:38.123Z: Total commands in VS Code: 2713
2025-08-13T00:31:38.123Z: kiroAgent commands: 131
2025-08-13T00:31:38.123Z: Other kiro commands: 29

2025-08-13T00:31:38.123Z: === END SUMMARY ===