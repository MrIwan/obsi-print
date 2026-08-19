# tlmgr-repo.sh: resolve the tlmgr repository URL for the image's TeX Live year.
#
# Resolves the repo URL for the image's TeX Live year: the frozen historic
# tlnet-final snapshot once it exists, otherwise a CTAN mirror. mirror.ctan.org
# round-robins with no timeout, so we verify one mirror and pin it for all
# calls instead of risking a dead one stalling the build.
#
# Shared by build.sh (runtime installs) and the Dockerfile (image build).

nope_tlmgr_repo() {
  year=$(tlmgr version | sed -n 's/.*version \([0-9]\{4\}\).*/\1/p')
  hist="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${year}/tlnet-final"
  ctan="https://mirror.ctan.org/systems/texlive/tlnet"

  # No downloader in the environment: keep the historic URL (old behavior),
  # the callers' fallback chain handles the current-year case.
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "$hist"
    return
  fi

  if nope_tlmgr_probe "$hist/tlpkg/texlive.tlpdb"; then
    echo "$hist"
    return
  fi

  # Current TL year. Pin one verified CTAN mirror, re-roll up to three times.
  if command -v curl >/dev/null 2>&1; then
    n=0
    while [ "$n" -lt 3 ]; do
      m=$(curl -fsIL --max-time 20 -o /dev/null -w '%{url_effective}' \
        "$ctan/tlpkg/texlive.tlpdb" 2>/dev/null) && [ -n "$m" ] &&
        nope_tlmgr_probe "$m" && {
        echo "${m%/tlpkg/texlive.tlpdb}"
        return
      }
      n=$((n + 1))
    done
  fi

  # Last resort: the round-robin URL, tlmgr rolls its own dice.
  echo "$ctan"
}

nope_tlmgr_probe() {
  # A plain HEAD/200 check is not enough, some mirrors return an HTML error page
  # with HTTP 200 for missing files. Validate that we can read a tlpdb payload.
  if command -v curl >/dev/null 2>&1; then
    curl -fsL --max-time 20 --range 0-4095 "$1" 2>/dev/null |
      grep -qm1 '^name[[:space:]]'
  else
    wget -q -O - --timeout=20 --tries=1 "$1" 2>/dev/null |
      grep -qm1 '^name[[:space:]]'
  fi
}
