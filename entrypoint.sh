#!/bin/sh

version() {
  if [ -n "$1" ]; then
    echo "-v $1"
  fi
}

cd "$GITHUB_WORKSPACE"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# if 'gemfile' reek version selected
if [[ $INPUT_REEK_VERSION = "gemfile" ]]; then
  # if Gemfile.lock is here
  if [[ -f 'Gemfile.lock' ]]; then
    # grep for reek version
    REEK_GEMFILE_VERSION=`cat Gemfile.lock | grep -oP '^\s{4}reek\s\(\K.*(?=\))'`

    # if reek version found, then pass it to the gem install
    # left it empty otherwise, so no version will be passed
    if [[ -n "$REEK_GEMFILE_VERSION" ]]; then
      REEK_VERSION=$REEK_GEMFILE_VERSION
      else
        printf "Cannot get the reek's version from Gemfile.lock. The latest version will be installed."
    fi
    else
      printf 'Gemfile.lock not found. The latest version will be installed.'
  fi
  else
    # set desired reek version
    REEK_VERSION=$INPUT_REEK_VERSION
fi

gem install -N reek $(version $REEK_VERSION)

reek --single-line . ${INPUT_REEK_FLAGS} \
  | reviewdog -f=reek \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS}
