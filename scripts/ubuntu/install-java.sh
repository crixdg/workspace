#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

ask_version() {
	local default="$1" label="$2" answer=""
	if [ -t 0 ]; then
		read -r -p "Enter the ${label} version you want to install [${default}]: " answer || answer=""
	fi
	printf '%s' "${answer:-$default}"
}

LTS_VERSION="${JAVA_VERSION:-$(ask_version "25" "Java LTS")}"

sudo apt install -y openjdk-${LTS_VERSION}-jdk

GRADLE_VERSION="${GRADLE_VERSION:-$(ask_version "9.2.1" "Gradle")}"
gradle_filename="gradle-${GRADLE_VERSION}-bin.zip"
if ! curl --silent --head "https://services.gradle.org/distributions/${gradle_filename}" | grep -q "HTTP/1.1 307"; then
	echo "Gradle file ${gradle_filename} not found online. Aborted."
	exit 1
fi

rm -rf $HOME/.local/gradle
mkdir -p $HOME/.local/gradle
wget https://services.gradle.org/distributions/${gradle_filename} -O $HOME/.local/gradle/${gradle_filename}
wget https://services.gradle.org/distributions/${gradle_filename}.sha256 -O $HOME/.local/gradle/${gradle_filename}.sha256
cd $HOME/.local/gradle
sha256sum -c <(awk '{print $1 "  gradle-'"${GRADLE_VERSION}"'-bin.zip"}' gradle-${GRADLE_VERSION}-bin.zip.sha256) || {
	echo "Checksum FAILED! Exiting."
	exit 1
}
unzip -q $HOME/.local/gradle/${gradle_filename} -d $HOME/.local/gradle
rm $HOME/.local/gradle/${gradle_filename}
rm $HOME/.local/gradle/${gradle_filename}.sha256

CONFIG_NAME="java"
CONFIG_CONTENT="export GRADLE_HOME=\"\$HOME/.local/gradle/gradle-${GRADLE_VERSION}\"
if [ -d \"\$GRADLE_HOME\" ]; then
	path=(\"\$GRADLE_HOME/bin\" \$path)
fi"
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Java OpenJDK ${LTS_VERSION} and Gradle ${GRADLE_VERSION} installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
