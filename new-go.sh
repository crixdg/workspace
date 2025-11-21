#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

read -p "Enter the Go version you want to install (e.g., 1.25.4): " VERSION
FILENAME="go${VERSION}.linux-amd64.tar.gz"
# Verify the version exists online
if ! curl --silent --head "https://go.dev/dl/${FILENAME}" | grep -q "HTTP/2 302"; then
    echo "Go file ${FILENAME} not found online. Aborted."
    exit 1
fi

rm -rf $HOME/.local/go
mkdir -p $HOME/.local/go
wget https://go.dev/dl/${FILENAME} -O $HOME/.local/go/${FILENAME}
tar -C $HOME/.local -xzf $HOME/.local/go/${FILENAME}
rm $HOME/.local/go/${FILENAME}

START_MARK="# >>> golang initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'golang workspace init' !!"
END_MARK="# <<< golang initialize <<<"

GOLANG_BLOCK=$(
    cat <<EOF
$START_MARK
$DESCRIPTION_MARK
export GOROOT="\$HOME/.local/go"
if [ -d "\$GOROOT" ]; then
    export PATH="\$GOROOT/bin:\$PATH"
fi

export GOPATH="\$HOME/go"
if [ -d "\$GOPATH" ]; then
    export GOBIN="\$GOPATH/bin"
    export PATH="\$GOBIN:\$PATH"
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
    awk -v block="$GOLANG_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
        BEGIN {inblock=0}
        $0 ~ start {
            print block;
            inblock=1;
            next
        }
        $0 ~ end {inblock=0; next}
        !inblock {print}
    ' "$SHELL_RC" >"${SHELL_RC}.tmp" && mv "${SHELL_RC}.tmp" "$SHELL_RC"
else
    # Append block with empty line before
    echo "" >>"$SHELL_RC"
    echo "$GOLANG_BLOCK" >>"$SHELL_RC"
fi

echo "Go ${VERSION} installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
