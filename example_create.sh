#!/bin/sh
# - Makes index for repositories in a single directory.
# - Makes static pages for each repository directory.
#
# NOTE, things to do manually (once) before running this script:
# - copy style.css, logo.png and favicon.png manually, a style.css example
#   is included.
# - modify the categories in the for loop with your own.
#
# - write clone url, for example "git://git.codemadness.org/dir" to the "url"
#   file for each repo.
# - write owner of repo to the "owner" file.
# - write description in "description" file.
#
# Usage:
# - mkdir -p htmldir && cd htmldir
# - sh example_create.sh

# path must be absolute
reposdir="/var/www/git"
webdir="/var/www/git.lucas"
defaultdir="/root/stagit-alt/stagit/"

mkdir -p "$webdir" || exit 1

# set assets if not already there
ln -s "$defaultdir/style.css" "$webdir/style.css" 2> /dev/null
ln -s "$defaultdir/logo.png" "$webdir/logo.png" 2> /dev/null
ln -s "$defaultdir/favicon.png" "$webdir/favicon.png" 2> /dev/null

# clean
for dir in "$webdir/"*/; do
    rm -rf "$dir"
done

# make files per repo
for dir in "$reposdir/"*.git/; do
    dir="${dir%/}"
    [ ! -f "$dir/git-daemon-export-ok" ] && continue
    [ ! -f "$dir/category" ] && [ -z "$stagit_uncat" ] && stagit_uncat="1"

    # strip .git suffix
    r="$(basename "$dir")"
    d="$(basename "$dir" ".git")"
    printf "%s... " "$d"

    mkdir -p "$webdir/$d"
    cd "$webdir/$d" || continue
    stagit -c ".stagit-build-cache" "$reposdir/$r"

    # symlinks
    [ -f "about.html" ] \
        && ln -sf "about.html" "index.html" \
        || ln -sf "log.html" "index.html"
    ln -sfT "$reposdir/$r" ".git"

    echo "done"
done

# generate index arguments
args=""
for cat in "Projects" "Miscellanea"; do
    args="$args -c \"$cat\""
    for dir in "$reposdir/"*.git/; do
        dir="${dir%/}"
        [ -f "$dir/git-daemon-export-ok" ] && [ -f "$dir/category" ] && \
            [ "$(cat "$dir/category")" = "$cat" ] && \
            args="$args $dir"
    done
done

if [ -n "$stagit_uncat" ]; then
    args="$args -c Uncategorized"
    for dir in "$reposdir/"*.git/; do
        dir="${dir%/}"
        [ -f "$dir/git-daemon-export-ok" ] && [ ! -f "$dir/category" ] && \
            args="$args $dir"
    done
fi

# make index
echo "$args" | xargs stagit-index > "$webdir/index.html"
