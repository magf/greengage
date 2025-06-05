# MAIN BUILDER
# Build image with parameters
#
# Example (bash):
# export IMAGE=europe-west1-docker.pkg.dev/${PROJECT_ID:=tactile-acrobat-461712-m0}/greengage/ggdb${_IMAGE_VERSION:-6}_${TARGET_OS:=centos}${TARGET_OS_VERSION:=7}:$(git describe --tags --abbrev=0 HEAD^)
# or
# export IMAGE=europe-west1-docker.pkg.dev/${PROJECT_ID:=tactile-acrobat-461712-m0}/greengage/ggdb${_IMAGE_VERSION:-6}_${TARGET_OS:=ubuntu}${TARGET_OS_VERSION:=22}:$(git describe --tags --abbrev=0 HEAD^) PYTHON3=python3
#
# docker build --push --tag $IMAGE \
#   --build-arg PYTHON3=$PYTHON3 \
#   --build-arg PROJECT_ID=$PROJECT_ID \
#   --build-arg TARGET_OS=$TARGET_OS \
#   --build-arg TARGET_OS_VERSION=$TARGET_OS_VERSION \
# .

ARG PROJECT_ID=tactile-acrobat-461712-m0

ARG TARGET_OS=centos
ARG TARGET_OS_VERSION=7

ARG BASE=europe-west1-docker.pkg.dev/$PROJECT_ID/greengage/ggdb-base:$TARGET_OS$TARGET_OS_VERSION

FROM $BASE AS build

ARG PYTHON3
ARG TARGET_OS
ARG TARGET_OS_VERSION
ARG OUTPUT_ARTIFACT_DIR=bin_gpdb
ARG CONFIGURE_FLAGS="--enable-debug-extensions --with-gssapi --enable-cassert --enable-debug --enable-depend" 

ENV TARGET_OS=$TARGET_OS
ENV TARGET_OS_VERSION=$TARGET_OS_VERSION
ENV OUTPUT_ARTIFACT_DIR=$OUTPUT_ARTIFACT_DIR
ENV CONFIGURE_FLAGS=$CONFIGURE_FLAGS

# Use python3.9 to compile into GPDB's plpython3u. Use build option `--build-arg PYTHON3=python3`. Not set dy default - use python2
ENV PYTHON3=$PYTHON3

# Debug output
# RUN echo "TARGET_OS=$TARGET_OS TARGET_OS_VERSION=$TARGET_OS_VERSION OUTPUT_ARTIFACT_DIR=$OUTPUT_ARTIFACT_DIR CONFIGURE_FLAGS=$CONFIGURE_FLAGS"

COPY . gpdb_src

RUN mkdir /home/gpadmin/bin_gpdb

# Compile with running mocking tests
RUN bash /home/gpadmin/gpdb_src/concourse/scripts/compile_gpdb.bash

FROM $BASE AS code
# Use --exclude, when it will be available in stable syntax.
COPY . gpdb_src
RUN rm -rf gpdb_src/.git/

FROM $BASE AS test
COPY --from=code /home/gpadmin/gpdb_src gpdb_src
COPY --from=build /home/gpadmin/bin_gpdb /home/gpadmin/bin_gpdb

# Install entab used by pgindent utility.
# This should be done using gpdb sources.
RUN make -C gpdb_src/src/tools/entab install clean

# Volume for tests output
VOLUME /home/gpadmin/gpdb_src/src/test
