#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

read -p "Enter the Java LTS version you want to install (e.g., 25): " LTS_VERSION

sudo apt update
sudo apt install -y openjdk-${LTS_VERSION}-jdk

read -p "Enter the Gradle version you want to install (e.g., 9.2.1): " GRADLE_VERSION
gradle_filename="gradle-${GRADLE_VERSION}-bin.zip"
# Verify the version exists online
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

START_MARK="# >>> java initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'java workspace init' !!"
END_MARK="# <<< java initialize <<<"

JAVA_BLOCK=$(
	cat <<EOF
$START_MARK
$DESCRIPTION_MARK
export GRADLE_HOME="\$HOME/.local/gradle/gradle-${GRADLE_VERSION}"
if [ -d "\$GRADLE_HOME" ]; then
    export PATH="\$GRADLE_HOME/bin:\$PATH"
fi
$END_MARK
EOF
)

if [[ "$SHELL" =~ "zsh" ]]; then
	SHELL_RC="$HOME/.zshrc"
else
	SHELL_RC="$HOME/.bashrc"
fi

if grep -q "$START_MARK" "$SHELL_RC"; then
	# Replace existing block, ensure empty line before block
	awk -v block="$JAVA_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
        BEGIN {inblock=0}
        $0 ~ start {
            print block;
            inblock=1;
            next
        }
        $0 ~ end {
            inblock=0;
            next
        }
        inblock == 0 {print}
    ' "$SHELL_RC" >"$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
else
	# Append new block with preceding empty line
	{
		echo ""
		echo "$JAVA_BLOCK"
	} >>"$SHELL_RC"
fi

echo "Java OpenJDK ${LTS_VERSION} and Gradle ${GRADLE_VERSION} installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
