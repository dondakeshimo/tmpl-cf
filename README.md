# tmpl-cf

This Shell script automates the process of checking for updates in template files from multiple remote repositories and merging the changes into corresponding files in a local repository. The script also creates a pull request in the local repository whenever there are updates to the template files.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing](#testing)
- [License](#license)

## Features

- Supports multiple template repositories
- Supports multiple template files in each repository
- Supports multiple local files corresponding to the template files
- Automatically checks for updates in the template files
- Merges the changes into the local files when updates are detected
- Creates a pull request in the local repository for the updated files

## Requirements

- Git
- Bash
- [jq](https://stedolan.github.io/jq/) command-line JSON processor
- A GitHub account with appropriate access to the repositories

## Configuration

The script requires a `config.json` file that stores the necessary information for the script execution:

```json
{
  "github_username": "your-github-username",
  "access_token": "your-personal-access-token",
  "my_repo_name": "my-repo",
  "file_mappings": [
    {
      "template_repo_name": "template-repo-1",
      "template_file_path": "path/to/template-file-1",
      "my_file_path": "path/to/my-file-1",
      "last_applied_commit": "commit-hash-1"
    },
    {
      "template_repo_name": "template-repo-2",
      "template_file_path": "path/to/template-file-2",
      "my_file_path": "path/to/my-file-2",
      "last_applied_commit": "commit-hash-2"
    }
  ],
  "my_branch_name": "update-my-files",
  "my_commit_message": "Update my files with latest template changes",
  "pr_title": "Update my files with latest template changes",
  "pr_body": "This PR updates my files with the latest changes made in the templates."
}
```

Replace the placeholders in the `config.json` file with the appropriate information for your GitHub repositories and personal access token. The personal access token should have the necessary permissions to perform the required actions, such as creating a pull request.

## Usage

1. Clone your local repository:

```bash
git clone https://github.com/your-github-username/my-repo.git
```

2. Change the current directory to the cloned repository:

```bash
cd my-repo
```

3. Place the `config.json` file and the `update_my_files.sh` script in the root of the cloned repository.

4. Ensure that the `update_my_files.sh` script is executable:

```bash
chmod +x update_my_files.sh
```

5. Run the script:

```bash
./update_my_files.sh
```

The script will check for updates in the template files, merge the changes into the corresponding local files, and create a pull request in the local repository if updates were detected.

### Usage With GitHub Action

```yaml
name: Template Update

on:
  schedule:
    - cron: '0 0 * * *' # Run daily at midnight
  workflow_dispatch: # Allow manual trigger

jobs:
  check_template_updates:
    runs-on: ubuntu-latest

    steps:
    - name: Check out repository
      uses: actions/checkout@v2

    - name: Execute Template Update Action
      uses: your-github-username/template-update-action@main
      with:
        config-file: 'config.json'
```

## Testing

A test scenario is provided in the [Product Requirements Document](PRD.md) to verify the script's functionality. Follow the steps in the scenario to ensure that the script correctly updates the local files based on the template files and creates pull requests.

## License

This project is released under the [MIT License](LICENSE).
