#!/usr/bin/env bash
#!/bin/bash

__build() {
    __build_time

    local old_pwd=$(pwd)
    # git submodule add -b 4.0.0a6 git@github.com:runkit7/runkit7.git src/runkit7-4.0.0a6
    git submodule update --init -f
    cp src/runkit7-4.0.0a6/package.xml src/package.xml

    cd ./src/
    dpkg-buildpackage
    cd - >/dev/null

    cd ./src/
    __build_status=$(dpkg-buildpackage -S 2>&1)
    cd - >/dev/null

    mkdir -p dists
    mv *.ddeb *.deb *.buildinfo *.changes *.dsc *.tar.xz *.tar.gz *.tar.* dists/ >/dev/null 2>&1
}

__build_time() {
    cat src/debian/changelog | sed -e "0,/<ductn@diepxuan.com>  .*/ s/<ductn@diepxuan.com>  .*/<ductn@diepxuan.com>  $(date -R)/g" >src/debian/changelog
}

__dput_ppa() {
    package=dists/$(echo "$__build_status" | grep _source.changes | grep signfile | sed 's| signfile ||g')
    dput ductn-ppa $package
}

if [[ -n $* ]]; then
    "__$@"
fi
