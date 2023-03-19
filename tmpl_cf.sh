#!/bin/bash

set -eu

# Add an exception for the GitHub Actions workspace
git config --global --add safe.directory /github/workspace

# Configure Git user information
git config --global user.email "tmpl-cf@dondakeshimo.com"
git config --global user.name "tmpl-cf"

# Load main configuration
main_config="$(cat $CONFIG_FILE_PATH)"
follower_branch_name=$(echo "$main_config" | jq -r '.follower_branch_name')

# Checkout branch
echo $(git remote -v)
remote_branch_exists=$(git ls-remote --heads origin "${follower_branch_name}")
if [ -z "${remote_branch_exists}" ]; then
  git checkout -b "${follower_branch_name}"
else
  git checkout "${follower_branch_name}"
fi

# Load follower branch configuration
follower_org=$(echo "$config" | jq -r '.follower_org')
follower_repo_name=$(echo "$config" | jq -r '.follower_repo_name')
file_paths=$(echo "$config" | jq -c '.file_paths[]')
follower_branch_name=$(echo "$config" | jq -r '.follower_branch_name')
follower_commit_message=$(echo "$config" | jq -r '.follower_commit_message')
pr_title=$(echo "$config" | jq -r '.pr_title')
pr_body=$(echo "$config" | jq -r '.pr_body')

access_token="${ACCESS_TOKEN}"

# Initialize a flag for PR creation
create_pr=0

for file_path in $file_paths; do
  template_repo_url=$(echo "$file_path" | jq -r '.template_repo_url')
  template_repo_url="https://x-access-token:$access_token@${template_repo_url#https://}"
  template_file_path=$(echo "$file_path" | jq -r '.template_file_path')
  follower_file_path=$(echo "$file_path" | jq -r '.follower_file_path')
  last_applied_commit=$(echo "$file_path" | jq -r '.last_applied_commit')
  template_repo_dir="template-repo"

  # Clone the template repository
  git clone "$template_repo_url" "$template_repo_dir" || true

  # Get the latest commit hash of the template file
  cd "$template_repo_dir"
  template_file_latest_commit=$(git log -n 1 --pretty=format:%H -- "$template_file_path")
  cd ..

  # Check if the template has updates
  if [ "$template_file_latest_commit" != "$last_applied_commit" ]; then
    # Create a diff file between the template and your file
    diff -u "$follower_file_path" "$template_repo_dir/$template_file_path" > "diff_${follower_file_path}.patch" || true

    # Get commit messages of the template file
    cd "$template_repo_dir"
    commit_messages=$(git log --pretty=format:"%h - %s" $last_applied_commit.. -- "$template_file_path")
    cd ..

    # Update the PR body with commit messages
    pr_body="$pr_body\n\nCommit messages for $template_file_path:\n$commit_messages"

    # Apply the diff file, add the changes, and remove the diff file
    git apply "diff_${follower_file_path}.patch"
    git add "$follower_file_path"
    rm "diff_${follower_file_path}.patch"

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
    "https://api.github.com/repos/$follower_org/$follower_repo_name/pulls?state=open" | jq ".[] | select(.head.ref == \"${follower_branch_name}\")")

  # Close the former PR
  if [ -n "${existing_pr}" ]; then
    echo "A pull request already exists for the branch ${follower_branch_name}. Closing the existing PR."
    existing_pr_number=$(echo "${existing_pr}" | jq ".number")
    curl -s -X PATCH -H "Authorization: token ${access_token}" \
      -H "Accept: application/vnd.github+json" \
      -d '{"state": "closed"}' \
      "https://api.github.com/repos/$follower_org/$follower_branch_name/pulls/${existing_pr_number}"
  fi

  # Update config JSON
  echo $config | jq > $CONFIG_FILE_PATH
  git add $CONFIG_FILE_PATH

  # Commit the changes and push the branch to your repository
  git commit -m "$follower_commit_message"
  git push origin "$follower_branch_name"

  # Create a PR using curl
  # TODO: should changable about base branch
  echo $pr_body
  curl -X POST -H "Authorization: token $access_token" -d "{\"title\":\"$pr_title\", \"head\":\"$follower_branch_name\", \"base\":\"main\", \"body\":\"$pr_body\"}" "https://api.github.com/repos/$follower_org/$follower_repo_name/pulls"
else
  echo "No updates found in the template file."
fi
