#!/bin/sh
echo -n "Enter name of the firefox profile: " && read name

echo "Creating Profile"
firefox -CreateProfile $name
folder=$(sed -n "/Path=.*.$name$/ s/.*=//p" ~/.mozilla/firefox/profiles.ini)
path="/home/$(whoami)/.mozilla/firefox/$folder"
cd $path
echo "Profile Creation Finished"

echo "Initialising Git Repo"
git init
git remote add origin https://github.com/ghoulboii/firefox
git fetch
git checkout origin/master -ft
git submodule update --init --recursive
git submodule update --recursive --remote
cp userjs/{updater.sh,prefsCleaner.sh,user.js} .
cp -r VerticalFox/{windows,sidebery} .
mv windows chrome
echo "Git Repo Initialised"

echo "Downloading Addons"
addonlist="ublock-origin bitwarden-password-manager darkreader"
addontmp="$(mktemp -d)"
echo "doing trap"
trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
mozillaurl="https://addons.mozilla.org"
IFS=' '
mkdir -p "$path/extensions/"
for addon in $addonlist; do
	addonurl="$(curl --silent "$mozillaurl/en-US/firefox/addon/${addon}/" | grep -o "$mozillaurl/firefox/downloads/file/[^\"]*")"
	file="${addonurl##*/}"
	curl -LOs "$addonurl" >"$addontmp/$file"
	id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
	id="${id%\"*}"
	id="${id##*\"}"
	mv "$file" "$path/extensions/$id.xpi"
done
echo "Addons Installed"
