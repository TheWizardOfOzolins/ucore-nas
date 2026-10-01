# ucore-nas

A custom [uCore](https://github.com/ublue-os/ucore) image (based on `ucore-hci:stable`) for a home NAS. It adds iSCSI target support and [Materia](https://github.com/stryan/materia) for GitOps-managed Quadlets.

## What's included

On top of `ucore-hci` (which already provides ZFS, Cockpit, libvirt, etc.):

| Addition | Details |
| --- | --- |
| Packages | `targetcli`, `tmux`, `vim`, `tree` |
| iSCSI | `iscsid` and `target` enabled at boot |
| Podman | `podman.socket` enabled |
| Materia | `/usr/bin/materia` plus `materia-update.timer` (runs every 5 min). See [Materia setup](#materia-setup) |
| Signature policy | The host only accepts updates to this image that are signed with [`cosign.pub`](cosign.pub) |
| Quieter login | `coreos-container-signing-migration-motd.service` disabled |

## Installing / switching to this image

From an existing uCore (or any bootc) host:

```bash
# 1. Switch to the image. The current deployment doesn't trust its key yet, so don't enforce signatures.
sudo bootc switch ghcr.io/thewizardofozolins/ucore-nas:latest
sudo systemctl reboot

# 2. Now that the policy and key are installed, switch again with signature enforcement.
sudo bootc switch --enforce-container-sigpolicy ghcr.io/thewizardofozolins/ucore-nas:latest
sudo systemctl reboot
```

After step 2, `bootc upgrade` and the automatic updates from `rpm-ostreed-automatic.timer` refuse images that aren't signed with this repo's key.

For fresh installs, see [Disk images](#disk-images).

## Materia setup

The image ships Materia but **no config or secrets**. The image is public, so the Git source and keys are provisioned per host. `materia-update.service` doesn't run until all of these exist:

| File | Purpose |
| --- | --- |
| `/etc/materia/config.toml` | Copy from `/usr/share/materia/config.toml.example` and set your repo URL |
| `/etc/materia/materia_key` | SSH deploy key with read access to the Materia repo |
| `/etc/materia/known_hosts` | Host key of your Git server (`ssh-keyscan -p <port> <host>`) |
| `/etc/materia/key.txt` | age identity used to decrypt secrets in the repo |

```bash
sudo cp /usr/share/materia/config.toml.example /etc/materia/config.toml
sudo $EDITOR /etc/materia/config.toml
sudo install -m 0600 materia_key key.txt /etc/materia/
sudo install -m 0644 known_hosts /etc/materia/
sudo systemctl start materia-update.service   # run once now instead of waiting for the timer
journalctl -u materia-update.service
```

Files in `/etc` persist across image updates. They can also be supplied via Butane/Ignition at install time.

## Build

- **CI:** [`build.yml`](.github/workflows/build.yml) builds daily (06:30 UTC), on pushes to `main`, and on PRs. Images from `main` are pushed to GHCR as `latest`, `latest.YYYYMMDD` and `YYYYMMDD`, then signed with cosign.
- **Dependencies:** [Renovate](.github/renovate.json5) updates GitHub Actions and the Materia version in `build_files/build.sh`. Materia bump PRs fail the build until the `MATERIA_SHA256` values are updated to match the new release.
- **Layout:**
  - `Containerfile` – base image and build entrypoint
  - `build_files/build.sh` – packages, services and downloads
  - `system_files/` – files copied as-is into the image root (systemd units, configs, signing policy)
  - `disk_config/` – bootc-image-builder configs for disk images

### Building locally

```bash
just build              # builds localhost/ucore-nas:latest with podman
just build-qcow2        # VM disk image from the local build
just run-vm-qcow2       # boot it in a VM
```

## Disk images

[`build-disk.yml`](.github/workflows/build-disk.yml) (manual dispatch) builds a qcow2 and an Anaconda installer ISO from the published image. The ISO installs and then runs `bootc switch` to `ghcr.io/thewizardofozolins/ucore-nas:latest`. Afterwards, do step 2 of [Installing](#installing--switching-to-this-image) to enforce signatures.

## Verifying signatures

```bash
cosign verify --key cosign.pub ghcr.io/thewizardofozolins/ucore-nas:latest
```

CI signs with `--new-bundle-format=false` so that signatures are stored as legacy `.sig` tags. podman and bootc can't verify cosign v3's new bundle format, so don't remove that flag.
