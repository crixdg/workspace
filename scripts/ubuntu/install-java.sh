#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

DEFAULT_JAVA_LTS_VERSION="25"
read -p "Enter the Java LTS version you want to install [${DEFAULT_JAVA_LTS_VERSION}]: " LTS_VERSION
LTS_VERSION=${LTS_VERSION:-$DEFAULT_JAVA_LTS_VERSION}

sudo apt install -y openjdk-${LTS_VERSION}-jdk

DEFAULT_GRADLE_VERSION="9.2.1"
read -p "Enter the Gradle version you want to install [${DEFAULT_GRADLE_VERSION}]: " GRADLE_VERSION
GRADLE_VERSION=${GRADLE_VERSION:-$DEFAULT_GRADLE_VERSION}
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
CONFIG_BLOCK='export GRADLE_HOME="\$HOME/.local/gradle/gradle-${GRADLE_VERSION}"
if [ -d "\$GRADLE_HOME" ]; then
	export PATH="\$GRADLE_HOME/bin:\$PATH"
fi'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Java OpenJDK ${LTS_VERSION} and Gradle ${GRADLE_VERSION} installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
