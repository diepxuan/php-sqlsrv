#!/usr/bin/env bash
#!/bin/bash

set -e
# set -u
. $(dirname $(realpath "$BASH_SOURCE"))/head.sh

[[ -f /etc/os-release ]] && . /etc/os-release
[[ -f /etc/lsb-release ]] && . /etc/lsb-release

# os evironment
CODENAME=${CODENAME:-$DISTRIB_CODENAME}
CODENAME=${CODENAME:-$VERSION_CODENAME}
CODENAME=${CODENAME:-$UBUNTU_CODENAME}

RELEASE=${RELEASE:-$(echo $DISTRIB_DESCRIPTION | awk '{print $2}')}
RELEASE=${RELEASE:-$(echo $VERSION | awk '{print $1}')}
RELEASE=${RELEASE:-$(echo $PRETTY_NAME | awk '{print $2}')}
RELEASE=${RELEASE:-${DISTRIB_RELEASE}}
RELEASE=${RELEASE:-${VERSION_ID}}

DISTRIB=${DISTRIB:-$DISTRIB_ID}
DISTRIB=${DISTRIB:-$ID}
DISTRIB=$(echo "$DISTRIB" | awk '{print tolower($0)}')

# user evironment
email=ductn@diepxuan.com
changelog=$INPUT_SOURCE_DIR/debian/changelog

# plugin
owner=runkit7 project=runkit7
release_url=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/$owner/$project/releases/latest)
release_tag=$(basename $release_url)
release_dir=$INPUT_SOURCE_DIR/$project-$release_tag

rm -rf $release_dir
git clone -b $release_tag --depth=1 -- https://github.com/$owner/$project.git $release_dir

cp $release_dir/package.xml $INPUT_SOURCE_DIR/package.xml
ls -la $release_dir
ls -la $INPUT_SOURCE_DIR

# Update module runkit7 release latest
old_release_tag=$(cat $changelog | head -n 1 | awk '{print $2}' | cut -d '+' -f1 | sed 's|[()]||g')
sed -i -e "0,/$old_release_tag/ s/$old_release_tag/$release_tag/g" $changelog

# Update os release latest
old_release_os=$(cat $changelog | head -n 1 | awk '{print $2}' | cut -d '+' -f2 | cut -d '~' -f1)
sed -i -e "0,/$old_release_os/ s/$old_release_os/${DISTRIB}${RELEASE}/g" $changelog

# Update os codename
old_codename_os=$(cat $changelog | head -n 1 | awk '{print $3}')
sed -i -e "0,/$old_codename_os/ s/$old_codename_os/$CODENAME;/g" $changelog

# Update time building
BUILDPACKAGE_EPOCH=${BUILDPACKAGE_EPOCH:-$(date -R)}
sed -i -e "0,/<$email>  .*/ s/<$email>  .*/<$email>  $BUILDPACKAGE_EPOCH/g" $changelog
