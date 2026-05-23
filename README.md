# ReleaseNotesGen

A native macOS app that connects to the GitHub API, compares commits between two tags, and generates formatted release notes in Markdown — in seconds.

![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![License](https://img.shields.io/github/license/OFFSerpa/ReleaseNotesGen?style=flat-square)

---

<!-- 
  SCREENSHOT: tela inicial do app (SetupView) com os campos de token e repositório
  Sugestão: 700x500, janela centralizada, light mode
-->
![Setup Screen](./docs/screenshot-setup.png)

---

## Features

- **GitHub API integration** — connects via Personal Access Token
- **Tag comparison** — select any two tags and compare the commits between them
- **Automatic categorization** — parses conventional commits (`feat`, `fix`, `chore`, `refactor`, `docs`) into sections
- **Markdown output** — generates clean, ready-to-paste release notes
- **Raw / Preview toggle** — switch between raw Markdown and a rendered preview
- **Copy to clipboard** — one click to copy the full output
- **Export as `.md`** — save the file locally
- **Secure token storage** — GitHub token stored in the macOS Keychain, never in plain text
- **Persistent session** — change repositories without re-entering your token

---

<!-- 
  SCREENSHOT ou GIF: tela principal (MainView) com tags selecionadas e release notes geradas
  Ideal: GIF mostrando o fluxo completo — selecionar tags → clicar Generate → resultado aparecer
-->
![Main Screen](./docs/screenshot-main.png)

---

<!-- 
  SCREENSHOT: aba Preview com o markdown renderizado
  Sugestão: mesmo conteúdo do screenshot anterior, mas na aba "Preview"
-->
![Preview Screen](./docs/screenshot-preview.png)

---

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later
- A [GitHub Personal Access Token](https://github.com/settings/tokens) with `public_repo` scope (or `repo` for private repositories)

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/OFFSerpa/ReleaseNotesGen.git
   ```

2. Open the project in Xcode
   ```bash
   open ReleaseNotesGen.xcodeproj
   ```

3. Build and run with **⌘R**

4. On first launch, paste your GitHub Personal Access Token and a repository in `owner/repo` format

## How It Works

1. Enter your GitHub PAT and target repository (e.g. `facebook/react`)
2. Select the **From** and **To** tags
3. Click **Generate** — the app fetches the commit diff via the GitHub REST API
4. Commits are categorized by their conventional commit prefix
5. Toggle between **Raw** and **Preview**, then copy or export

### Output format

```markdown
# Release Notes: v1.0.0 -> v1.1.0

**Repository:** owner/repo
**Generated:** May 22, 2026

## Features
- feat: add dark mode support (a1b2c3d)

## Bug Fixes
- fix: crash on empty tag list (e4f5g6h)
```

## Architecture

```
ReleaseNotesGen/
├── App/            → App entry point
├── Models/         → Repository, Tag, Commit, ReleaseNote
├── Services/       → GitHubService (API), TokenManager (Keychain)
├── ViewModels/     → SetupViewModel, ReleaseNoteViewModel
├── Views/          → SetupView, MainView, ReleaseNoteResultView, MarkdownPreviewView
└── Utils/          → CommitParser
```

- **Pattern:** MVVM
- **Concurrency:** Swift Concurrency (`async/await`)
- **Networking:** `URLSession` — zero external dependencies
- **Security:** GitHub token stored in the macOS Keychain via `Security.framework`

## License

Distributed under the MIT License. See `LICENSE` for details.
