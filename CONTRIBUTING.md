# Contributing to Amethyst

We welcome contributions to Amethyst! This document outlines the process for contributing to the project.

## Code of Conduct

[CODE-OF-CONDUCT.md](CODE-OF-CONDUCT.md)

## How to Contribute

We welcome all kinds of contributions, including:

*   Bug fixes
*   New features
*   Documentation improvements
*   Testing
*   UI/UX enhancements

To ensure a smooth contribution process, please follow these guidelines:

### 1. Discuss Your Idea First

Before starting work on a significant change, please open an issue on Codeberg to discuss your idea. This will help us ensure that your contribution aligns with the project's goals and that you're not duplicating effort.  Describe the problem you're trying to solve or the feature you're proposing.

### 2. Fork the Repository

Fork the Amethyst repository on Codeberg to your own account.

### 3. Create a Branch

Create a new branch in your forked repository with a descriptive name related to your contribution. For example:

*   `fix/crash-on-startup`
*   `feature/add-tab-grouping`
*   `docs/update-installation-instructions`

### 4. Implement Your Changes

*   Write clean, readable, and reusable code.
*   Follow the project's coding conventions (see below).
*   Ensure your code is well-tested (see testing section below).
*   If you're making changes to a SwiftData model, be sure to include working migrations.

### 5. Coding Conventions

*   **Language:** Swift
*   **Folder Structure:** Maintain the existing folder structure.
*   **Extensions:** Utilize extensions for larger views and controllers to improve organization.
*   **Readability:** Write code that is self-documenting and easy to understand. Minimize the need for comments by using clear and descriptive variable and function names.
*   **Reusability:** Design your code to be reusable whenever possible.

### 6. Submit a Pull Request

Once you've implemented your changes and are satisfied with the results, submit a pull request (PR) to the main Amethyst repository on Codeberg.

*   **Link to Related Issue:** In your PR description, link to the issue that your PR addresses.
*   **Description of Changes:** Provide a clear and concise description of the changes you've made.
*   **Motivation:** Explain the motivation behind your changes and why they are valuable to the project.

### 7. Code Review

Your PR will be reviewed by the project maintainer. We will assess your code for:

*   **Relevance:** Whether the changes are beneficial to the project.
*   **Code Quality:** Whether the code is clean, readable, and well-documented.
*   **Correctness:** Whether the code functions as intended and doesn't introduce new issues.
*   **Adherence to Conventions:** Whether the code follows the project's coding conventions.

We may request changes to your code before merging it. Please be responsive to feedback and address any concerns raised during the review process.

### 8. License

By contributing to Amethyst, you agree to grant the project maintainer an irrevocable, fully-paid, non-exclusive license to use, modify, and distribute your code. This is necessary to ensure the long-term sustainability of the project.

### Important Restrictions

To maintain the privacy and security of our users, **you are strictly prohibited from sending any data to external sources without explicit permission from the project maintainer.** This includes analytics, crash reporting, and any other form of data collection.  The project maintainer will handle any necessary data collection.

## Setting Up Your Development Environment

### 1. System Requirements

*   macOS Sequoia (15.0) or later
*   Xcode

### 2. Installation

1.  Install Xcode from the Mac App Store.
2.  Clone the Amethyst repository from Codeberg:

    ```bash
    git clone <repository URL>
    ```

3.  Open the Amethyst project in Xcode.

### 3. Building and Running

Xcode will handle the build process. Simply select the target and click the "Run" button.

If Xcode signing fails on a personal Apple development team because the browser target uses capabilities that are not supported there, you can still build locally from the command line without code signing:

```bash
xcodebuild -project 'Amethyst Project.xcodeproj' -scheme 'Amethyst Debug' -configuration Debug CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

## Testing

Currently, Amethyst does not have extensive unit tests due to the challenges of testing UI-heavy applications. Therefore, it is crucial that you thoroughly test your changes manually.

*   **Manual Testing:** After making changes, carefully test all related functionality to ensure that it works as expected and doesn't introduce any regressions.
*   **Pre-Release Testing:** Before a release, a build will be available in TestFlight for at least two weeks. We encourage you to participate in pre-release testing to help identify any remaining issues.

## Reporting Bugs

If you encounter a bug, please submit an issue on Codeberg with the following information:

*   A clear and concise description of the bug.
*   Steps to reproduce the bug.
*   The expected behavior.
*   The actual behavior.
*   Any relevant error messages or logs.
*   Your system configuration (macOS version, Xcode version).

## Feature Requests

If you have a feature request, please submit an issue on Codeberg with a detailed description of the proposed feature and why you believe it would be valuable to the project.

## SwiftData Migrations

**Important:** If you make any changes to a SwiftData model, you **must** include working migrations to ensure that existing user data is not lost.  Provide clear instructions on how to test the migrations.

## Where to Get Help

If you have any questions or need help contributing, please don't hesitate to ask in the Codeberg issue tracker.

Thank you for your interest in contributing to Amethyst!
