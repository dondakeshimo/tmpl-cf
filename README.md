# tmpl-cf

Title: Template Update Notification and Merge Script

## Introduction

This document describes the product requirements for a Shell script that automates the process of checking for updates in template files from multiple remote repositories and merging the changes into corresponding files in a local repository. The script also creates a pull request in the local repository whenever there are updates to the template files.

## Problem Statement

It is challenging for users to keep track of updates in template files located in remote repositories and manually merge the changes into their local files. The proposed script aims to simplify this process by automating the update check, merging the changes, and creating a pull request for the updated files.

## Requirements
### Functional Requirements

- Use Shell Script
- Support multiple template repositories
- Support multiple template files in each repository
- Support multiple local files corresponding to the template files
- Automatically check for updates in the template files
- Merge the changes into the local files when updates are detected
- Create a pull request in the local repository for the updated files
- Maintain a configuration file (config.json) to store the necessary information for the script execution

### Non-Functional Requirements

- The script should be easy to set up and configure
- The script should be efficient in checking for updates and creating pull requests
- The script should be able to handle errors and edge cases gracefully
- The script should be well-documented and maintainable

## Configuration

The script will use a configuration file (config.json) that stores the following information:

- GitHub username
- Personal access token for authentication
- Local repository name
- File mappings (template repositories, template files, local files, and last applied commit hashes)
- Branch name for the created pull request
- Commit message for the updated files
- Title and body of the pull request

## Implementation

The script will be implemented using Shell script, with the following key steps:

- Load configuration from config.json
- Clone and pull updates from the template repositories
- Create a new branch in the local repository
- Iterate through the file mappings and perform the following tasks for each mapping:
    - Check if there are updates in the template file
    - Merge the changes into the corresponding local file if updates are detected
    - Update the last applied commit hash in config.json
- Create a pull request in the local repository if updates were detected and merged
- Remove the cloned template repositories
- Testing

A test scenario will be provided that verifies the script's functionality by creating template repositories and local repositories with corresponding files, running the script, and ensuring the updates are merged and pull requests are created.

## Future Enhancements

- Provide support for different file formats and merge strategies
- Implement a notification system to alert users when updates are detected
- Add support for other version control platforms, such as GitLab and Bitbucket
