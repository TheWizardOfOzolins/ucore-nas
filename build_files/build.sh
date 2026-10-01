#!/bin/bash
# Build orchestrator. Runs the shared layer first, then the variant layer:
#   1. copy system_files/common/ then system_files/${VARIANT}/ into /
#   2. run build_files/common/*.sh then build_files/${VARIANT}/*.sh (in name order)
# Add shared changes under common/, image-specific ones under hci/ or minimal/.

set -ouex pipefail

VARIANT=${VARIANT:?VARIANT must be set (hci or minimal)}
CTX=/ctx

if [[ ! -d "${CTX}/${VARIANT}" ]]; then
  echo "Unknown variant: ${VARIANT}" >&2
  exit 1
fi

for layer in common "${VARIANT}"; do
  ### Copy static files (systemd units, configs) into the image
  if [[ -d "${CTX}/system_files/${layer}" ]]; then
    cp -a "${CTX}/system_files/${layer}/." /
    rm -f /.gitkeep
  fi

  ### Run build steps
  for script in "${CTX}/${layer}"/*.sh; do
    [[ -e "$script" ]] || continue
    echo "::group:: ${layer}/$(basename "$script")"
    bash "$script"
    echo "::endgroup::"
  done
done
