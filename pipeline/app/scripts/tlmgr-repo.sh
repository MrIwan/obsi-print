# tlmgr-repo.sh: resolve the tlmgr repository URL for the image's TeX Live year.
#
# CTAN only serves the current TeX Live release, so a version-pinned image needs
# the frozen historic tlnet-final repo of its own year. That repo only appears
# once the year is frozen: while the image's year IS the current release the
# historic URL 404s, so probe it first and use CTAN instead.
#
# mirror.ctan.org redirects to a random mirror on EVERY request, and tlmgr has
# no timeout — one dead mirror stalls a build for many minutes, and two tlmgr
# calls in a row can land on different mirrors. So resolve the redirect once,
# verify that concrete mirror serves the tlpdb, and pin it for all calls.
# Callers keep their own fallback as a safety net.
#
# Single source for this resolution. Sourced by build.sh (runtime nope-tlmgr
# installs) and by the Dockerfile base-package layer (image build).

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
