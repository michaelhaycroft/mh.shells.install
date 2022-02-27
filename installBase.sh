REPOSITORY_CLONE_URL="git@github.com:michaelhaycroft/mh.shells.git"
DEFAULT_SHELLS_INSTALL_ROOT="/mh.shells"
SHELLS_INSTALL_ROOT="${1:-$DEFAULT_SHELLS_INSTALL_ROOT}"
INSTALL_PACKAGE_MANAGERS="${2:-1}"
INSTALL_PACKAGES="${3:-1}"
INSTALL_CONFIGURATIONS="${3:-1}"
INSTALLER_PARAMETERS=""
INVOKE_INSTALLER="0"

echo "Shells install root:       $SHELLS_INSTALL_ROOT"
echo "Install package managers?: $INSTALL_PACKAGE_MANAGERS"
echo "Install packages?:         $INSTALL_PACKAGES"
echo "Install configurations?:   $INSTALL_CONFIGURATIONS"
exit

if [[ "$INSTALL_PACKAGE_MANAGERS" == "1" ]]; then
    INSTALLER_PARAMETERS="${INSTALLER_PARAMETERS} -p"
    INVOKE_INSTALLER="1"
fi
if [[ "$INSTALL_PACKAGES" != "1" ]]; then
    INSTALLER_PARAMETERS="${INSTALLER_PARAMETERS} -i NONE"
    INVOKE_INSTALLER="1"
fi
if [[ "$INSTALL_CONFIGURATIONS" != "1" ]]; then
    INSTALLER_PARAMETERS="${INSTALLER_PARAMETERS} -c NONE"
    INVOKE_INSTALLER="1"
fi
GIT_INSTALL_ERROR="0"

function InstallPackageOrFailAndExit() {
    local ExecutableName="$1"
    local PackageName="${2:-$ExecutableName}"
    echo "Installing $ExecutableName if not already installed"
    if [[ -z "$(which "$ExecutableName")" ]]; then
        sudo dnf install -y "$PackageName" || \
        sudo apt-get install -y "$PackageName" || \
        echo "Install of $ExecutableName failed" && \
        exit
        echo "$ExecutableName was installed"
    else
        echo "$ExecutableName is already installed"
    fi
    return 0
}

function SetupSshAccessToRepository() {
    read -p "Enter a passphrase for Github SSH (e.g. empty string): " GITHUB_SSH_PASSPHRASE
    read -p "Enter github user email: " GITHUB_USER_EMAIL
    GITHUB_SSH_KEY_OUTFILE="$HOME/.ssh/github_$(echo $GITHUB_USER_EMAIL | sed 's/\./dot/g' | sed 's/@/at/g')"
    ssh-keygen -t ed25519 -C $GITHUB_USER_EMAIL -f $GITHUB_SSH_KEY_OUTFILE < <(echo -e "$GITHUB_SSH_PASSPHRASE\n$GITHUB_SSH_PASSPHRASE\n")
    cat $GITHUB_SSH_KEY_OUTFILE.pub
    echo "UPLOAD THE ABOVE GENERATED SSH PUBLIC KEY ($GITHUB_SSH_KEY_OUTFILE) TO GITHUB THEN PRESS ANY KEY TO CONTINUE"
    read
}

function CloneShellsRepository() {
    PARENT_DIR="$(dirname "$SHELLS_INSTALL_ROOT")"
    sudo mkdir -p "$PARENT_DIR"
    sudo chown $USER "$PARENT_DIR"
    pushd $PARENT_DIR
    git clone "$REPOSITORY_CLONE_URL"
    popd
    sudo chown $USER $SHELLS_INSTALL_ROOT -R
    sudo chmod u+x $SHELLS_INSTALL_ROOT -R
}

InstallPackageOrFailAndExit "git" "git-all"
InstallPackageOrFailAndExit "ssh-keygen" "x"
SetupSshAccessToRepository
CloneShellsRepository
if [[ "$INVOKE_INSTALLER" == "1" ]]; then
    InstallPackageOrFailAndExit "datamash"
    echo "Launching package installer"
    sudo bash "$SHELLS_INSTALL_ROOT/linux/scripts/install.sh" "$INSTALLER_PARAMETERS"
fi
