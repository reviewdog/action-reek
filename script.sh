#!/bin/sh

version() {
  if [ -n "$1" ]; then
    echo "-v $1"
  fi
}

cd "${GITHUB_WORKSPACE}" || exit

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo '::group:: Installing reek ... https://github.com/troessner/reek'
# if 'gemfile' reek version selected
if [ "$INPUT_REEK_VERSION" = "gemfile" ]; then
  # if Gemfile.lock is here
  if [ -f 'Gemfile.lock' ]; then
    # grep for reek version
    REEK_GEMFILE_VERSION=$(grep -oP '^\s{4}reek\s\(\K.*(?=\))' Gemfile.lock)

    # if reek version found, then pass it to the gem install
    # left it empty otherwise, so no version will be passed
    if [ -n "$REEK_GEMFILE_VERSION" ]; then
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

# shellcheck disable=SC2046,SC2086
gem install -N reek $(version $REEK_VERSION)
echo '::endgroup::'

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

echo '::group:: Running reek with reviewdog 🐶 ...'
# shellcheck disable=SC2086
reek --single-line . ${INPUT_REEK_FLAGS} \
  | reviewdog -f=reek \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-level="${INPUT_FAIL_LEVEL}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?

echo '::endgroup::'

exit $reviewdog_rc
