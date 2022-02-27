function LineBreak() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}

function InstallPackageOrFailAndExit() {
    local ExecutableName="$1"
    local PackageName="${2:-$ExecutableName}"
    echo "Installing $ExecutableName if not already installed"
    if [[ -z "$(which "$ExecutableName")" ]]; then
        sudo dnf install -y "$PackageName" || \
        sudo apt-get install -y "$PackageName" || \
        echo "ERROR: Install of $ExecutableName failed" && \
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
    echo "Deleting existing keypairs if they exist"
    rm -f "$GITHUB_SSH_KEY_OUTFILE"
    rm -f "$GITHUB_SSH_KEY_OUTFILE.pub"
    ssh-keygen -t ed25519 -C $GITHUB_USER_EMAIL -f $GITHUB_SSH_KEY_OUTFILE < <(echo -e "$GITHUB_SSH_PASSPHRASE\n$GITHUB_SSH_PASSPHRASE\n")
    echo ""
    LineBreak
    echo ""
    cat $GITHUB_SSH_KEY_OUTFILE.pub
    echo ""
    LineBreak
    echo ""
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

REPOSITORY_CLONE_URL="git@github.com:michaelhaycroft/mh.shells.git"
DEFAULT_SHELLS_INSTALL_ROOT="/mh.shells"
SHELLS_INSTALL_ROOT="${1:-$DEFAULT_SHELLS_INSTALL_ROOT}"
GENERATE_SSH_KEYPAIR="${2-1}"
CLONE_PROJECT="${3-1}"
INSTALL_PACKAGE_MANAGERS="${4:-1}"
INSTALL_PACKAGES="${5:-1}"
INSTALL_CONFIGURATIONS="${6:-1}"

LineBreak
echo "Shells install root:       $SHELLS_INSTALL_ROOT"
echo "Generate SSH keypair?:     $GENERATE_SSH_KEYPAIR"
echo "Clone project?             $CLONE_PROJECT"
echo "Install package managers?: $INSTALL_PACKAGE_MANAGERS"
echo "Install packages?:         $INSTALL_PACKAGES"
echo "Install configurations?:   $INSTALL_CONFIGURATIONS"
LineBreak

INSTALLER_PARAMETERS=""
INVOKE_INSTALLER="0"
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

sudo echo "" # Ensure sudo privilege is available before beginning
InstallPackageOrFailAndExit "git" "git-all"
InstallPackageOrFailAndExit "ssh-keygen" "openssh-client"
if [[ "$GENERATE_SSH_KEYPAIR" == "1" ]]; then
    SetupSshAccessToRepository
fi
if [[ "$CLONE_PROJECT" == "1" ]]; then
    echo "Cloning shells to $SHELLS_INSTALL_ROOT"
    CloneShellsRepository
else
    if [[ -e "SHELLS_INSTALL_ROOT" ]]; then
        echo "Not re-cloning shells to $SHELLS_INSTALL_ROOT"
    else
        echo "ERROR: Clone project option was disabled but no path exists at the given shells install root $SHELLS_INSTALL_ROOT"
        exit
        exit
    fi
fi
if [[ "$INVOKE_INSTALLER" == "1" ]]; then
    InstallPackageOrFailAndExit "datamash"
    echo "Launching package installer"
    sudo bash "$SHELLS_INSTALL_ROOT/linux/scripts/install.sh" $INSTALLER_PARAMETERS
fi
