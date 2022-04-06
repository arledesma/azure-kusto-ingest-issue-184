#!/usr/bin/env bash

function print_line {
  local -r line="$1";
  local -r separator="$(printf -- '=%.0s' $(seq 1 40))";
  cat <<_EOF_
$separator
  $line
$separator
_EOF_
}

function main {
  local -r testdir="$(mktemp -d)";
  trap 'echo "Removing $testdir"; rm -rf "$testdir"; trap - return' return;

  (
    cd "$testdir" || exit 1;
    print_line "Created $testdir";
    git init;
    print_line "Initialized $testdir as a git repository";
    git commit --allow-empty -m "Initial Commit";

    echo "node_modules/" > .gitignore;
    git add .gitignore;
    git commit -m "Add .gitignore";
    print_line "Added .gitignore";

    npm init --yes;
    git add package.json;
    git commit -m "Add package.json";
    print_line "Added package.json";

    npm install --save azure-kusto-ingest;
    git add package.json package-lock.json;
    git commit --all -m "Add azure-kusto-ingest";
    print_line "Added azure-kusto-ingest package";

    print_line "This is our current package.json";
    cat package.json;
    print_line "This is the package.json from azure-kusto-ingest";
    cat node_modules/azure-kusto-ingest/package.json;

    print_line "Running npm ci directly after installing the package should have no errors";
    npm ci;
    print_line "npm ci should not have failed";
    print_line "Adding overrides for azure-kusto-data to package.json";

    sponge package.json < <(jq '.overrides = { "azure-kusto-data": "^3.2.0" }' package.json);
    print_line "This is our new hacky package.json";
    cat package.json
    git add package.json;
    git commit -m "Add hacky overrides for azure-kusto-data";

    npm install;
    git add package.json package-lock.json;
    git commit -m "Update package-lock.json";
    print_line "Updated package.json and package-lock.json";

    print_line "Now we can see npm ci is successful";
    npm ci
    print_line "Here are the changes from git";
    git --no-pager log --abbrev-commit --date=relative -p --reverse
  )
}

main