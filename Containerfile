# Image variant: hci or minimal (selects the uCore base image and which variant layer build.sh applies)
ARG VARIANT=hci

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY cosign.pub /system_files/common/etc/pki/containers/ucore-nas.pub

# Base Image
FROM ghcr.io/ublue-os/ucore-${VARIANT}:stable@sha256:bfc398580c2f04f1550efdeed89b15c8398846d3e4b28fbd6938d661a23323c7
ARG VARIANT

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## build.sh applies the shared layer, then the variant layer:
##   build_files/common/*.sh + system_files/common/     -> every image
##   build_files/${VARIANT}/*.sh + system_files/${VARIANT}/ -> that image only

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    VARIANT=${VARIANT} /ctx/build.sh && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint