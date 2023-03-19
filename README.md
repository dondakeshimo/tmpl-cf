# tmpl-cf

_TeMPLate Continuous Following_

A GitHub Action that automates the process of checking for updates in template files from multiple remote repositories and merging the changes into corresponding follower files in a your repository. The action also creates a pull request in the your repository whenever there are updates to the template files.

## Table of Contents

- [Features](#features)
- [Configuration](#configuration)
- [Usage](#usage)
- [License](#license)

## Features

- Supports multiple template repositories
- Supports multiple template files in each repository
- Supports multiple files corresponding to the template files
- Automatically checks for updates in the template files
- Merges the changes into the your files when updates are detected
- Creates a pull request in the your repository for the updated files

## Configuration

The action requires a `tmpl_cf.json` file that stores the necessary information for the action execution:

```json
{
  "follower_org": "your-github-organization-name",
  "follower_repo_name": "my-repo",
  "file_paths": [
    {
      "template_repo_url": "https://github.com/your/template-repository-1",
      "template_file_path": "path/to/template-file-1",
      "follower_file_path": "path/to/my-file-1",
      "last_applied_commit": "commit-hash-1"
    },
    {
      "template_repo_url": "https://github.com/your/template-repository-2",
      "template_file_path": "path/to/template-file-2",
      "follower_file_path": "path/to/my-file-2",
      "last_applied_commit": "commit-hash-2"
    }
  ],
  "follower_branch_name": "main",
  "follower_commit_message": "[tmpl-cf] Update my files with latest template changes",
  "pr_title": "[tmpl-cf] Update my files with latest template changes",
  "pr_body": "This PR updates my files with the latest changes made in the templates."
}
```

Replace the placeholders in the `tmpl_cf.json` file with the appropriate information for your GitHub repositories.

## Usage

Add the following to your GitHub Actions workflow file (e.g., `.github/workflows/tmpl-cf.yml`):

```yaml
name: Template Continuous Following

on:
  schedule:
    - cron: '0 0 * * *' # Run daily at midnight
  workflow_dispatch: # Allow manual trigger

jobs:
  follow_template_updates:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
    - name: Check out repository
      uses: actions/checkout@v2

    - name: Execute tmpl-cf
      uses: dondakeshimo/tmpl-cf@main
```

Ensure that `Settings > Actions > General > Allow GitHub Actions to create and approve pull requests` is enabled.

## License

This project is released under the [MIT License](LICENSE).
