#!/usr/bin/env bash

set -e

if [[ ! $# -eq 2 ]]; then
	echo "usage: $0 [ruby|mruby|jruby|rubinius|truffleruby|truffleruby-graalvm] [VERSION]"
	exit 1
fi

ruby="$1"
version="$2"
dest="pkg"

case "$ruby" in
	ruby)
		version_major="${version:0:1}"
		version_family="${version:0:3}"

		if [[ "$version_major" == "2" ]]; then
			exts=(tar.bz2 tar.gz tar.xz zip)
		else
			exts=(tar.gz tar.xz zip)
		fi

		downloads_url="https://cache.ruby-lang.org/pub/ruby"
		;;
	mruby)
		exts=(tar.gz zip)
		downloads_url="https://github.com/mruby/mruby/archive"
		;;
	jruby)
		exts=(tar.gz zip)
		downloads_url="https://repo1.maven.org/maven2/org/jruby/jruby-dist"
		;;
	rubinius)
		exts=(tar.bz2)
		downloads_url="https://rubinius-releases-rubinius-com.s3.amazonaws.com"
		;;
	truffleruby)
		exts=(linux-amd64 linux-aarch64 macos-amd64)
		downloads_url="https://github.com/oracle/truffleruby/releases/download"
		;;
	truffleruby-graalvm)
		exts=(linux-amd64 linux-aarch64 darwin-amd64)
		downloads_url="https://github.com/graalvm/graalvm-ce-builds/releases/download"
		;;
	*)
		echo "$0: unknown ruby: $ruby" >&2
		exit 1
		;;
esac

mkdir -p "$dest"
pushd "$dest" >/dev/null

for ext in "${exts[@]}"; do
	case "$ruby" in
		ruby)
			archive="ruby-${version}.${ext}"
			url="$downloads_url/$version_family/$archive"
			;;
		mruby)
			archive="mruby-${version}.${ext}"
			url="$downloads_url/$version/$archive"
			;;
		jruby)
			archive="jruby-dist-${version}-bin.${ext}"
			url="$downloads_url/$version/$archive"
			;;
		rubinius)
			archive="rubinius-${version}.${ext}"
			url="$downloads_url/$archive"
			;;
		truffleruby)
			archive="truffleruby-${version}-${ext}.tar.gz"
			url="$downloads_url/vm-$version/$archive"
			;;
		truffleruby-graalvm)
			archive="graalvm-ce-java11-${ext}-${version}.tar.gz"
			url="$downloads_url/vm-$version/$archive"
			;;
	esac

	if [ -f "$archive" ]; then
		echo "Already downloaded $archive"
	else
		wget -O "$archive" "$url"
	fi

	for algorithm in md5 sha1 sha256 sha512; do
		${algorithm}sum "$archive" >> "../$ruby/checksums.$algorithm"
	done
done

echo "$version" >> "../$ruby/versions.txt"

if [[ $(wc -l < "../$ruby/stable.txt") == "1" ]]; then
	echo "$version" > "../$ruby/stable.txt"
else
	echo "Please update $ruby/stable.txt manually"
fi

popd >/dev/null
