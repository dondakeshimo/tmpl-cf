#!/bin/bash

set -eux

# Add an exception for the GitHub Actions workspace
git config --global --add safe.directory /github/workspace

# Configure Git user information
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "tmpl-cf"

# Load configuration
config="$(cat $CONFIG_FILE_PATH)"
file_paths=$(echo "$config" | jq -c '.file_paths[]')
follower_branch_name=$(echo "$config" | jq -r '.follower_branch_name')
base_branch_name=$(echo "$config" | jq -r '.base_branch_name')
follower_commit_message=$(echo "$config" | jq -r '.follower_commit_message')
pr_title=$(echo "$config" | jq -r '.pr_title')
pr_body=$(echo "$config" | jq -r '.pr_body')

follower_repo_name="${GITHUB_REPOSITORY}"
access_token="${ACCESS_TOKEN}"

# Checkout branch
remote_branch_exists=$(git ls-remote --heads origin "${follower_branch_name}")
if [ -z "${remote_branch_exists}" ]; then
  git checkout -b "${follower_branch_name}"
else
  git fetch
  git checkout "${follower_branch_name}"
fi

# Initialize a flag for PR creation
create_pr=0

for file_path in $file_paths; do
  template_repo_url=$(echo "$file_path" | jq -r '.template_repo_url')
  template_repo_url="https://x-access-token:$access_token@${template_repo_url#https://}"
  template_file_path=$(echo "$file_path" | jq -r '.template_file_path')
  follower_file_path=$(echo "$file_path" | jq -r '.follower_file_path')
  last_applied_commit=$(echo "$file_path" | jq -r '.last_applied_commit')
  template_repo_dir="template-repo"

  # Extract last applied commit to the follower branch
  branch_last_applied_commit=$(cat "$CONFIG_FILE_PATH" | jq -r ".file_paths[] | select(.template_file_path == \"$template_file_path\" and .follower_file_path == \"$follower_file_path\") | .last_applied_commit")

  # Clone the template repository
  git clone "$template_repo_url" "$template_repo_dir" || true

  # Get the latest commit hash of the template file
  cd "$template_repo_dir"
  template_file_latest_commit=$(git log -n 1 --pretty=format:%H -- "$template_file_path")
  cd ..

  # Check if the template has updates
  if [ "$template_file_latest_commit" != "$branch_last_applied_commit" ]; then
    # Copy the lastest template file
    cd "$template_repo_dir"
    cp "$template_file_path" "$template_file_path.latest"
    git checkout "$last_applied_commit"
    cp "$template_file_path" "$template_file_path.last_applied"
    git checkout "$template_file_latest_commit"
    cd ..

    # Create a 3way-merge file between your file, the last applied template file and the latest template
    git checkout $base_branch_name
    diff3 -m -E "$follower_file_path" "$template_repo_dir/$template_file_path.last_applied" "$template_repo_dir/$template_file_path.latest" > "$follower_file_path.merged" || true
    git checkout $follower_branch_name
    cp "$follower_file_path.merged" $follower_file_path
    rm "$follower_file_path.merged"
    git add "$follower_file_path"

    # Get commit messages of the template file
    cd "$template_repo_dir"
    commit_messages=$(git log --pretty=format:"%h - %s" $last_applied_commit.. -- "$template_file_path")
    cd ..

    # Update the PR body with commit messages
    pr_body="$pr_body\n\nCommit messages for $template_file_path:\n$commit_messages"

    # Set the flag to create PR
    create_pr=1

    # Update the last applied commit hash in config.json
    config=$(echo "$config" | jq ".file_paths |= map(if .template_file_path == \"$template_file_path\" and .follower_file_path == \"$follower_file_path\" then .last_applied_commit = \"$template_file_latest_commit\" else . end)")
  fi

  # Remove the cloned template repository
  rm -rf "$template_repo_dir"
done

if [ $create_pr -eq 1 ]; then
  # Check if the PR is already exists
  existing_pr=$(curl -s -H "Authorization: token ${access_token}" \
    "https://api.github.com/repos/$follower_repo_name/pulls?state=open" | jq ".[] | select(.head.ref == \"${follower_branch_name}\")")

  # Create a new comment to the PR
  if [ -n "${existing_pr}" ]; then
    existing_pr_number=$(echo "${existing_pr}" | jq ".number")
    curl -s -X POST -H "Authorization: token ${access_token}" \
      -H "Accept: application/vnd.github+json" \
      -d "{\"body\": \"$pr_body\"}" \
      "https://api.github.com/repos/$follower_repo_name/issues/${existing_pr_number}/comments"
  fi

  # Update config JSON
  echo $config | jq > $CONFIG_FILE_PATH
  git add $CONFIG_FILE_PATH

  # Commit the changes and push the branch to your repository
  git commit -m "$follower_commit_message"
  git push origin "$follower_branch_name"

  # Create a PR using curl
  if [ -z "${existing_pr}" ]; then
    # TODO: should changable about base branch
    curl -X POST -H "Authorization: token $access_token" \
      -d "{\"title\":\"$pr_title\", \"head\":\"$follower_branch_name\", \"base\":\"$base_branch_name\", \"body\":\"$pr_body\"}" "https://api.github.com/repos/$follower_repo_name/pulls"
  fi
else
  echo "No updates found in the template file."
fi
