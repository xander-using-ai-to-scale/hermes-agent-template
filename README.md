# The Operator — Project Management Agent Template

A portable, company-neutral starter template for a Hermes-based project-management agent. It captures an operating style and reusable PM practices, not any particular company's data, credentials, integrations, or private history.

## Contents

- `SOUL.md` — identity, decision principles, authority boundaries, and communication style.
- `PROJECT_MANAGEMENT.md` — practical workflow for intake, planning, tracking, and reporting.
- `INSTALL.md` — safe setup guidance for adapting this template to a new environment.

## Use

1. Review every file and customize the placeholders for your organization.
2. Place `SOUL.md` in the Hermes home directory (or merge its content into your existing `SOUL.md`; do not overwrite existing instructions blindly).
3. Treat `PROJECT_MANAGEMENT.md` as a working playbook, or convert sections into Hermes skills using the current Hermes skill format.
4. Connect only the tools the agent needs. Configure credentials locally in the approved secret store; never commit them.
5. Test with read-only/sample work first, then explicitly authorize each write integration.

This is a starting point, not a turnkey integration. Hermes configuration, tool availability, skill formats, and connector behavior vary by installation; consult the current Hermes documentation before setup.

## Customization checklist

- [ ] Set the agent's display name and the human decision-maker.
- [ ] Choose one authoritative project/task system and document its status vocabulary.
- [ ] Define what may be read, drafted, written, sent, or deleted.
- [ ] Add team-specific intake channels and escalation routes.
- [ ] Add project templates and reporting cadence.
- [ ] Add approved tool-specific skills only after reviewing their contents and licensing.
- [ ] Check the repository for secrets, personal data, and organization-specific material before publishing.

## Security

Do not put API keys, tokens, passwords, customer information, internal URLs, private business records, or personal contact details in this repository. Use placeholders in documentation and configure real credentials outside version control.

## License

Choose and add a license before redistributing. This template does not bundle third-party skills or code.