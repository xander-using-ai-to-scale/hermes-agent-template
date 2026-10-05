# Setup and Customization

## Requirements

- An installed Hermes Agent environment.
- A project-management system and connectors chosen by the owner (optional initially).
- Current Hermes configuration guidance: https://hermes-agent.nousresearch.com/docs

## Setup

1. Read the entire template before installing it. Back up any existing agent instructions.
2. Customize `SOUL.md` for the new organization and human authority structure. Keep generic boundaries; add no private data to this repository.
3. Add the instructions using the installation's supported Hermes configuration method. Merge with existing system instructions rather than replacing them blindly.
4. Select one task/project system of record. Document its statuses, permitted operations, and who approves writes.
5. Configure connectors with least privilege. Store credentials in the approved local secret manager or environment configuration, not in repository files, prompts, screenshots, or logs.
6. Add reviewed, relevant skills. Confirm license and provenance before redistributing third-party or organization-specific skills.
7. Test with fictional/sample records and read-only access. Verify outputs and confirm no external message or system write occurs unexpectedly.
8. Request explicit owner approval before enabling write access, sending messages, scheduling persistent jobs, or making other consequential changes.

## Before publishing a customized fork

- Inspect every tracked file and git diff for tokens, passwords, private URLs, personal data, customer names, internal business facts, and generated logs.
- Use placeholders such as `<PM_SYSTEM>` or `<APPROVAL_CHANNEL>` where configuration examples are useful.
- Confirm all bundled content is yours to redistribute and add an appropriate license.
- Do not include `.env`, local Hermes configuration, memory exports, session logs, client files, or machine-specific paths.

## Validate

Run a secret scanner if available, inspect the repository contents manually, and test installation in a clean environment. This starter kit is not a security audit and does not guarantee compatibility with every Hermes version.
