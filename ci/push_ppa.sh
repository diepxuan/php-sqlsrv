#!/usr/bin/env bash
#!/bin/bash

set -e
# set -u
. $(dirname $(realpath "$BASH_SOURCE"))/head.sh

start_group "move package builder to dists"
regex='^php.*(.deb|.ddeb|.buildinfo|.changes|.dsc|.tar.xz|.tar.gz|.tar.[[:alpha:]]+)$'
mkdir -p $dists_dir
while read -r file; do
    mv -vf "$source_dir/$file" "$dists_dir/" || true
done < <(ls $source_dir/ | grep -E $regex)

while read -r file; do
    mv -vf "$pwd_dir/$file" "$dists_dir/" || true
done < <(ls $pwd_dir/ | grep -E $regex)
end_group

start_group "put package to ppa"
cat | tee ~/.dput.cf <<-EOF
[caothu91ppa]
fqdn = ppa.launchpad.net
method = ftp
incoming = ~caothu91/ubuntu/ppa/
login = anonymous
allow_unsigned_uploads = 0
EOF

package=$(ls -a $dists_dir | grep _source.changes | head -n 1)

[[ -n $package ]] &&
    package=$dists_dir/$package &&
    [[ -f $package ]] &&
    dput caothu91ppa $package || true
end_group

start_group "put package to buildkite"
regex='.*(.deb)$'
while read -r file; do
    curl -X POST https://api.buildkite.com/v2/packages/organizations/diepxuan/registries/diepxuan/packages \
        -H "Authorization: Bearer $KITE_TOKEN" \
        -F "file=@$dists_dir/$file" || true
done < <(ls $dists_dir/ | grep -E $regex)
end_group
