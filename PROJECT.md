# Project Description

This project is a desktop system called Dwellware that acts as a personal household software engineer, capable of creating bespoke applications for a single user or household on demand. While the system may eventually be deployed on bespoke hardware, the system will run initially on macOS and consist of:

## 1. Frontend Dashboard (Flutter Desktop)
- Serves as the main user interface for the system.
- Displays a grid/tile view of existing custom applications.
- Allows the user to request a new application or modifications to an existing one.
- Embeds applications in WebViews (for web apps) or launches native windows (for desktop binaries).
- Shows real-time, high-level progress of the development process for each requested application.

## 2. Orchestrator Backend
- Runs locally and manages all app generation jobs.
- Collects user input and converts it into a structured specification document.
- Initiates and manages headless development sessions in Amazon Kiro (a VS Code fork with AI agent capabilities).
- Monitors progress, collects build/test output, and communicates updates to the frontend.
- Stores application metadata (e.g., title, description, manifest details, deployment port, status) as local JSON documents in a dedicated metadata directory — effectively a lightweight, SQL-less datastore.
- Maintains a separate App Capsule for each generated application (standalone repository with source, tests, manifest, and container config).
- Builds and deploys each application in a sandboxed container.
- Registers applications with a local reverse proxy (e.g., Caddy) for routing.

## 3. AI Development Engine Integration (Amazon Kiro)
- Takes the structured specification and generates code, tests, and documentation using predefined templates and policies.
- Runs tests and iteratively refines the code until build and health checks pass.
- Outputs application artifacts into the assigned App Capsule.

## 4. Application Isolation
- Each generated application runs independently to prevent breaking changes when new apps are created.
- Network and filesystem access are restricted via per-app policies.
- Applications have local data storage and optional per-app secrets from the macOS Keychain.

## Primary Goals
- Enable a non-technical user to create and deploy custom household software tools entirely via a friendly UI.
- Keep all processing and application execution local for privacy and control.
- Ensure generated apps are self-contained and easily maintainable.
- Allow iterative refinement of applications via conversational updates.

## Non-Goals for Initial Phase
- Direct IoT device control or hardware integration.
- Cloud-hosted deployment.
- Real-time collaboration between multiple households.

## Example Use Cases
- A household chore rotation tracker with custom rules.
- A trip cost forecaster combining travel booking data and expense estimates.
- A seasonal home maintenance reminder app.
- A local events dashboard pulling from community sources.