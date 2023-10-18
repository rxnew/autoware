#!/bin/bash -e

: "${WEBAUTO_CI_SOURCE_PATH:?is not set}"
: "${WEBAUTO_CI_DEBUG_BUILD:?is not set}"

: "${AUTOWARE_PATH:?is not set}"
: "${CCACHE_DIR:=}"
: "${CCACHE_SIZE:=1G}"
: "${PARALLEL_WORKERS:=4}"

cp -rfT "$WEBAUTO_CI_SOURCE_PATH" "$AUTOWARE_PATH"
chmod 755 "$AUTOWARE_PATH"
cd "$AUTOWARE_PATH"

if [ -n "$CCACHE_DIR" ]; then
    mkdir -p "$CCACHE_DIR"
    export USE_CCACHE=1
    export CCACHE_DIR="$CCACHE_DIR"
    export CC="/usr/lib/ccache/gcc"
    export CXX="/usr/lib/ccache/g++"
    ccache -M "$CCACHE_SIZE"
fi

sudo -E apt-get -y update

# get installed ros distro
# shellcheck disable=SC2012
ROS_DISTRO=$(ls -1 /opt/ros | head -1)
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
rosdep update
rosdep install -y --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"

[[ $WEBAUTO_CI_DEBUG_BUILD == "true" ]] && build_type="RelWithDebInfo" || build_type="Release"

colcon build \
    --symlink-install \
    --cmake-args -DCMAKE_BUILD_TYPE="$build_type" -DCMAKE_CXX_FLAGS="-w" -DBUILD_TESTING=off \
    --catkin-skip-building-tests \
    --executor parallel \
    --parallel-workers "$PARALLEL_WORKERS"
