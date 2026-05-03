#!/bin/bash

set -eu

if [ -n "${1:-}" ]
then
  HELM_VERSION="$1"
elif [ -n "${HELM_VERSION:-}" ]
then
  :
else
  echo "Usage: $0 <helm-version>" >&2
  exit 1
fi

if ! printf '%s\n' "${HELM_VERSION}" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+$'
then
  echo "Invalid HELM_VERSION format: expected full semantic version vX.Y.Z or X.Y.Z, got ${HELM_VERSION}" >&2
  exit 1
fi

HELM_VERSION_NO_PREFIX="${HELM_VERSION#v}"
HELM_MAJOR_VERSION="${HELM_VERSION_NO_PREFIX%%.*}"
HELM_INSTALL_SCRIPT="get-helm-${HELM_MAJOR_VERSION}"
HELM_WORKDIR="$(mktemp -d)"

cleanup() {
  rm -rf "${HELM_WORKDIR}"
}

trap cleanup EXIT

cd "${HELM_WORKDIR}"

if ! curl -fsSLO "https://raw.githubusercontent.com/helm/helm/main/scripts/${HELM_INSTALL_SCRIPT}"
then
  echo "Failed to download Helm installer script ${HELM_INSTALL_SCRIPT} for version ${HELM_VERSION}" >&2
  exit 1
fi

bash "./${HELM_INSTALL_SCRIPT}" --version "${HELM_VERSION}"
