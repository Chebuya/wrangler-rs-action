#!/bin/bash

set -e

export HOME="/github/workspace"
export WRANGLER_HOME="/github/workspace"
export API_CREDENTIALS=""

mkdir -p "$HOME/.wrangler"
chmod -R 770 "$HOME/.wrangler"
rustup default nightly

# Used to execute any specified pre and post commands
execute_commands() {
  echo "$ Running: $1"
  COMMANDS=$1
  while IFS= read -r COMMAND; do
    CHUNKS=()

    for CHUNK in $COMMAND; do
      CHUNKS+=("$CHUNK")
    done

    eval "${CHUNKS[@]}"

    CHUNKS=()
  done <<< "$COMMANDS"
}

secret_not_found() {
  echo "::error::Specified secret \"$1\" not found in environment variables."
  exit 1
}

# If an API token is detected as input
if [ -n "$INPUT_APITOKEN" ]; then
  export CLOUDFLARE_API_TOKEN="$INPUT_APITOKEN"
  export API_CREDENTIALS="API Token"
fi

if [ -n "$INPUT_ACCOUNTID" ]; then
  export CLOUDFLARE_ACCOUNT_ID="$INPUT_ACCOUNTID"
fi

if [ -z "$API_CREDENTIALS" ]
then
  >&2 echo "Unable to find authentication details. Please pass in an 'apiToken' as an input to the action."
  exit 1
else
  echo "Using $API_CREDENTIALS authentication"
fi

# If a working directory is detected as input
if [ -n "$INPUT_WORKINGDIRECTORY" ]
then
  cd "$INPUT_WORKINGDIRECTORY"
fi

# If precommands is detected as input
if [ -n "$INPUT_PRECOMMANDS" ]
then
  execute_commands "$INPUT_PRECOMMANDS"
fi

# If we have secrets, set them
for SECRET in $INPUT_SECRETS; do
  VALUE=$(printenv "$SECRET") || secret_not_found "$SECRET"

  if [ -z "$INPUT_ENVIRONMENT" ]; then
    echo "$VALUE" | wrangler secret put "$SECRET"
  else
    echo "$VALUE" | wrangler secret put "$SECRET" --env "$INPUT_ENVIRONMENT"
  fi
done
# If there's no input command then default to deploy otherwise run it
if [ -z "$INPUT_COMMAND" ]; then
  echo "::notice:: No command was provided, defaulting to 'deploy'"
 
 if [ -z "$INPUT_ENVIRONMENT" ]; then
    wrangler deploy
  else
    wrangler deploy --env "$INPUT_ENVIRONMENT"
  fi

else
  if [ -n "$INPUT_ENVIRONMENT" ]; then
    echo "::notice::Since you have specified an environment you need to make sure to pass in '--env $INPUT_ENVIRONMENT' to your command."
  fi

  execute_commands "wrangler $INPUT_COMMAND"
fi

# If postcommands is detected as input
if [ -n "$INPUT_POSTCOMMANDS" ]
then
  execute_commands "$INPUT_POSTCOMMANDS"
fi

# If a working directory is detected as input, revert to the
# original directory before continuing with the workflow
if [ -n "$INPUT_WORKINGDIRECTORY" ]
then
  cd $HOME
fi
