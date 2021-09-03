#!/bin/bash -e
################################################################################
##  File:  haskell.sh
##  Desc:  Installs Haskell
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/etc-environment.sh

# Any nonzero value for noninteractive installation
export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
export GHCUP_INSTALL_BASE_PREFIX=/usr/local
export BOOTSTRAP_HASKELL_GHC_VERSION=0
ghcup_bin=$GHCUP_INSTALL_BASE_PREFIX/.ghcup/bin
setEtcEnvironmentVariable "BOOTSTRAP_HASKELL_NONINTERACTIVE" $BOOTSTRAP_HASKELL_NONINTERACTIVE

# Install Herbert V. Riedel's PPA for managing multiple version of ghc on ubuntu.
# https://launchpad.net/~hvr/+archive/ubuntu/ghc
apt-get install -y software-properties-common
add-apt-repository -y ppa:hvr/ghc
apt-get update

# Install GHCup
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh > /dev/null 2>&1 || true
export PATH="$ghcup_bin:$PATH"
prependEtcEnvironmentPath $ghcup_bin

availableVersions=$(ghcup list -t ghc -r | grep -v "prerelease" | awk '{print $2}')

# Install 3 latest major versions(For instance 8.6.5, 8.8.4, 8.10.2)
minorMajorVersions=$(echo "$availableVersions" | cut -d"." -f 1,2 | uniq | tail -n3)
for majorMinorVersion in $minorMajorVersions; do
    fullVersion=$(echo "$availableVersions" | grep "$majorMinorVersion." | tail -n1)
    echo "install ghc version $fullVersion..."
    ghcup install ghc $fullVersion
    ghcup set ghc $fullVersion

	# remove docs and profiling libs
	ghc_bin_dir="$(ghcup whereis --directory ghc $fullVersion)"
	[ -e "${ghc_bin_dir}" ] || exit 1
	ghc_dir="$(realpath "${ghc_bin_dir}"/..)"
	[ -e "${ghc_dir}" ] || exit 1
	find "${ghc_dir}" \( -name "*_p.a" -o -name "*.p_hi" \) -type f -delete
	rm -r "${ghc_dir}"/share/*
	unset ghc_bin_dir ghc_dir
done

echo "install cabal..."
ghcup install cabal

chmod -R 777 $GHCUP_INSTALL_BASE_PREFIX/.ghcup
ln -s $GHCUP_INSTALL_BASE_PREFIX/.ghcup /etc/skel/.ghcup
ln -s "/opt/ghc/$defaultGHCVersion/bin/ghc" "/usr/bin/ghc"

# Install the latest stable release of haskell stack
curl -sSL https://get.haskellstack.org/ | sh

# remove PPA repo
echo "ghc ppa:hvr/ghc" >> $HELPER_SCRIPTS/apt-sources.txt
add-apt-repository --remove ppa:hvr/ghc

invoke_tests "Haskell"
