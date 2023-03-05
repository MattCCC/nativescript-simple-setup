#!/bin/bash

if [[ "$(which brew)" == *"opst"* || "$(which brew)" == *"opta"* ]]; then
    echo "Working"
    exit;
fi

    echo "Not working"

exit

NVM_VERSION="0.39.3"
NATIVESCRIPT_VERSION="8.4.7"
NODE_VERSION="18.14.2"
NPM_VERSION="9.5.1"
PYTHON_VERSION="2.7.18"
PYENV_VERSION="2.2.5"
RUBY_VERSION="3.1.1"
PODS_VERSION="1.11.3"
JAVA_VERSION="11.0.15"

LOG_FILE="setup.log"
ZSHRC_FILE="$HOME/.zshrc"
BASH_PROFILE_FILE="$HOME/.bash_profile"

touch $BASH_PROFILE_FILE
touch $ZSHRC_FILE
echo "" > $LOG_FILE

unameOut="$(uname -s)"

case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Win;;
    MINGW*)     machine=Win;;
    *)          machine=$unameOut
esac

if [[ $(uname -m) == 'arm64' ]]; then
  M1=1
else
  M1=0
fi

start_message() {
    echo "\x1b[36m \nYou are running the cleanup script (V5)\nIt will help you to install or update all dependencies 🤟\n \x1b[0m"
}

initial_checks() {
    if [ ! -d "$(xcode-select -p)" ]; then
        echo "\n\033[0;31mERROR!\033[0m Please download & install XCode before running setup.\n"
        exit
    fi

    if [ ! -d "$HOME/Library/Android" ]; then
        echo "\n\033[0;31mERROR!\033[0m Please download & install Android Studio (https://developer.android.com/studio) before running setup.\n"
        exit
    fi
}

install_brew() {
    export HOMEBREW_NO_ENV_HINTS=1

    if [ $M1 == 1 ]; then
        BREW_REMOVED=false

        # Make sure brew is reinstalled when somebody migrates from Intel to M1 e.g. by using time-machine
        if [[ "$(which brew)" == *"usr/local"*  ]]; then
            echo "Removing old brew..."

            sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -s --path=/usr/local --quiet --force >> $LOG_FILE
            sudo rm -rf /usr/local/homebrew /usr/local/bin/brew

            echo "Old brew removal complete."

            BREW_REMOVED=true
        fi

        if [[ "$BREW_REMOVED" == "true" || "$(which brew)" == *"not found"*]]; then
            echo "Installing new brew... It can take a while..."

            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" -s --quiet --force >> $LOG_FILE

            echo "Brew installation complete."
        fi
    else
        if [[ "$(which brew)" == *"not found"* ]]; then
            echo "Installing new brew... It can take a while..."

            /bin/bash -c "$(git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow)"
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" -s --quiet --force >> $LOG_FILE

            echo "Brew installation complete."
        fi
    fi

    echo "Brew checks complete."

    wait
}

disable_brew_analytics() {
    brew analytics off
}

install_software_updates() {
    echo "Checking for software updates..."

    xcode-select --install
    sudo xcode-select --reset
    softwareupdate --install-rosetta --agree-to-license
    sudo gem install ffi

    wait

    echo "Software updates checks complete."
}

install_nvm() {
    echo "Checking NVM..."

    echo "\nexport NVM_DIR=\"\$HOME/.nvm\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"  # This loads nvm
    [ -s \"\$NVM_DIR/bash_completion\" ] && . \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion" | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    echo "\nexport PATH=\"\$HOME/.nvm/versions/node/v$NODE_VERSION/bin:\$PATH\"" | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

    if [ -f "$NVM_DIR/nvm.sh" ]; then
        source $NVM_DIR/nvm.sh

        CURRENT_NVM_VERSION="$(nvm -v 2>&1)"
    else
        CURRENT_NVM_VERSION=""
    fi

    if [ "$CURRENT_NVM_VERSION" != "$NVM_VERSION" ]; then
        echo "Reinstalling NVM..."

        rm -rf ~/.nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash

        NVM_INSTALLED=true

        echo "NVM installed successfully."
    fi

    source $NVM_DIR/nvm.sh

    echo "Installed NVM: $(nvm -v 2>&1)" >> $LOG_FILE

    wait

    echo "NVM checks complete."
}

install_node() {
    echo "Checking Node and NPM..."

    CURRENT_NODE_VERSION="$(node -v 2>&1)"
    CURRENT_NPM_VERSION="$(npm -v 2>&1)"

    if [ "$NVM_INSTALLED" == "true" ]; then
        CURRENT_NODE_VERSION=""
        CURRENT_NPM_VERSION=""
    fi

    if [ "$CURRENT_NODE_VERSION" == "v$NODE_VERSION" ]; then
        echo "Node is up to date."
    else
        echo "Installing Node..."

        nvm install $NODE_VERSION >> $LOG_FILE
        nvm use
        NODE_INSTALLED=true

        echo "Node installed."
    fi

    if [ "$CURRENT_NPM_VERSION" == "$NPM_VERSION" ]; then
        echo "NPM is up to date."
    else
        echo "Installing NPM..."

        npm i -g npm@$NPM_VERSION >> $LOG_FILE
        NPM_INSTALLED=true

        echo "NPM installed."
    fi

    echo "Installed Node: $(node -v 2>&1)" >> $LOG_FILE
    echo "Installed NPM: $(npm -v 2>&1)" >> $LOG_FILE

    wait

    echo "Node and NPM checks complete."
}

uninstall_node() {
    echo "Removing Node & NPM installed by brew..."

    brew uninstall node -f
    brew uninstall nvm -f

    echo "Node & NPM installed by brew removed."

    if [ $M1 == 1 ]; then
        echo "Removing Node & NPM leftovers from Intel migration (if any)..."

        rm -rf /usr/local/bin/node /usr/local/bin/npm /usr/local/lib/dtrace/node.d
        sudo rm -rf /usr/local/include/node/ /usr/local/lib/node_modules/npm $HOME/.npm

        echo "Node & NPM leftovers from Intel migration (if any) removed."
    fi

    brew cleanup --prune-prefix

    wait

    echo "Node checks complete."
}

reinstall_java() {
    echo "Checking JDK..."

    CURRENT_JAVA_VERSION="$(java -version 2>&1)"

    if [[ "$CURRENT_JAVA_VERSION" == *"$JAVA_VERSION"* ]]; then
        echo "JDK is up to date."
    else
        echo "Installing JDK update... This can take a while..."

        brew install openjdk@11 >> $LOG_FILE

        echo "Installation of JDK is complete."
    fi

    echo '\nexport JAVA_HOME=$(/usr/libexec/java_home -v11)' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    if [ $M1 == 1 ]; then
        echo '\nexport PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

        export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include"
        sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    else
        echo '\nexport PATH="/usr/local/homebrew/opt/openjdk@11/bin:$PATH"' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

        export CPPFLAGS="-I/usr/local/homebrew/opt/openjdk@11/include"
        sudo ln -sfn /usr/local/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
    fi

    export JAVA_HOME=$(/usr/libexec/java_home -v11)

    echo "Installed java: $(java -version 2>&1)" >> $LOG_FILE

    wait

    echo "JDK checks complete."
}

reinstall_android_tools() {
    echo "Adjusting Android Tools..."

    # Support new ANDROID_SDK_ROOT path to the SDK installation directory, as ANDROID_HOME will be deprecated
    echo '\nexport ANDROID_SDK_ROOT=$HOME/Library/Android/sdk' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport ANDROID_HOME=$HOME/Library/Android/sdk' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport PATH=$PATH:$ANDROID_HOME/platform-tools' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport PATH=$PATH:$ANDROID_HOME/emulator' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-31" "cmdline-tools;latest" "build-tools;31.0.0" "emulator"
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;20.0.5594570" --channel=3 > /dev/null 2>&1

    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --uninstall "build-tools;29.0.2" "build-tools;29.0.3" "build-tools;30.0.2" "build-tools;30.0.3" > /dev/null 2>&1

    if [[ "$(avdmanager list avd)" == *"-DEFAULT"* ]]; then
        echo "Emulator already installed."
    else
        if [ $M1 == 1 ]; then
            $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-30;google_apis_playstore;arm64-v8a"
            echo "no" | $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager --verbose create avd --force --name "Pixel-5-API-30-DEFAULT" --device "pixel" --package "system-images;android-30;google_apis_playstore;arm64-v8a" --tag "google_apis_playstore" --abi "arm64-v8a"
        else
            $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-30;google_apis_playstore;x86_64"
            echo "no" | $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager --verbose create avd --force --name "Pixel-5-API-30-DEFAULT" --device "pixel" --package "system-images;android-30;google_apis_playstore;x86_64" --tag "google_apis_playstore" --abi "x86_64"
        fi
    fi

    wait

    echo "Android Tools checks complete."
}

reinstall_ruby_and_pods() {
    echo "Checking Ruby..."

    # Nuke the gems! It's safer to do that when ruby version changes.
    sudo rm -rf /usr/local/lib/ruby/gems/ /opt/homebrew/lib/ruby/gems/ $HOME/.gem

    echo '\nGEM_HOME=$HOME/.gem' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport PATH=$GEM_HOME/bin:$PATH' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    if [ $M1 == 1 ]; then
        echo '\nexport PATH="/opt/homebrew/opt/ruby/bin:$PATH"' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    else
        echo '\nexport PATH="/usr/local/opt/ruby/bin:$PATH"' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    fi

    CURRENT_RUBY_VERSION="$(ruby -v 2>&1)"
    CURRENT_PODS_VERSION="$(pod --version 2>&1)"

    echo "Current ruby version: $CURRENT_RUBY_VERSION" >> $LOG_FILE
    echo "Current ruby path: $(which ruby 2>&1)" >> $LOG_FILE

    if [[ "$CURRENT_RUBY_VERSION" == *"$RUBY_VERSION"* ]]; then
        echo "Ruby version is correct."
    else
        echo "Installing Ruby update... This can take a while..."

        brew uninstall ruby -f --ignore-dependencies >> $LOG_FILE
        arch -x86_64 brew uninstall ruby --ignore-dependencies -f >> $LOG_FILE
        brew autoremove
        brew install ruby@3.1 >> $LOG_FILE

        echo "Installation of Ruby is complete."
    fi

    if [ $M1 == 1 ]; then
        export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
        export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
    else
        export LDFLAGS="-L/usr/local/opt/ruby/lib"
        export CPPFLAGS="-I/usr/local/opt/ruby/include"
    fi

    echo "Installing pods... This can take a while..."

    brew reinstall cocoapods >> $LOG_FILE
    brew unlink cocoapods >> $LOG_FILE
    brew link --overwrite cocoapods >> $LOG_FILE

    echo "Pods package installed."

    echo "Installed Ruby: $(ruby -v 2>&1)" >> $LOG_FILE
    echo "Installed Pods: $(pod --version 2>&1)" >> $LOG_FILE

    wait

    echo "Installation of Ruby is complete."
}

reinstall_python() {
    echo "Checking Python..."

    CURRENT_PYTHON_VERSION="$(python -V 2>&1)"
    CURRENT_PYENV_VERSION="$(pyenv -v 2>&1)"

    echo "Current Pyenv version: $CURRENT_PYENV_VERSION"
    echo "Current Python version: $CURRENT_PYTHON_VERSION"

    if [ "$CURRENT_PYTHON_VERSION" == "Python $PYTHON_VERSION" ] &&
        [ "$CURRENT_PYENV_VERSION" == "pyenv $PYENV_VERSION" ]; then
        echo "Pyenv & Python are up to date."
        PYENV_INSTALLED=false
    else
        echo "Installing Pyenv..."

        sudo rm -rf $HOME/.pyenv
        brew uninstall pyenv -f >> $LOG_FILE
        brew install pyenv >> $LOG_FILE

        echo "Installing Pyenv is complete."

        PYENV_INSTALLED=true
    fi

    echo '\nexport PYENV_ROOT=$HOME/.pyenv' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null
    echo '\nexport PATH=$PYENV_ROOT/bin:$PATH' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"

    echo '\nif command -v pyenv 1>/dev/null 2>&1; then # pyenv
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
    fi # pyenv' | tee -a $ZSHRC_FILE $BASH_PROFILE_FILE > /dev/null

    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
    fi

    if [ "$PYENV_INSTALLED" == "true" ]; then
        echo "Installing Python..."
        pyenv install $PYTHON_VERSION >> $LOG_FILE
        pyenv global $PYTHON_VERSION >> $LOG_FILE
        echo "Installing Python is complete."
    fi

    echo "Installing pip..."
    pip install --upgrade pip >> $LOG_FILE
    python -m pip install six >> $LOG_FILE
    echo "Installing pip is complete."

    echo "Installed Pyenv: $(pyenv -v 2>&1)" >> $LOG_FILE
    echo "Installed Python: $(python -V 2>&1)" >> $LOG_FILE

    wait

    echo "Installation of Python is complete."
}

install_gems() {
    echo "Installing gems..."

    # Try w/o sudo
    gem install xcodeproj >> $LOG_FILE

    sudo gem install xcodeproj >> $LOG_FILE
    sudo gem pristine ffi --version 1.15.3 >> $LOG_FILE
    sudo gem pristine ffi --version 1.15.1 >> $LOG_FILE
    sudo gem pristine unf_ext --version 0.0.7.7 >> $LOG_FILE

    wait

    echo "Installation of gems is complete."
}

install_ns() {
    echo "Checking NativeScript version..."

    CURRENT_NATIVESCRIPT_VERSION="$(ns --version 2>&1)"

    if [ "$NVM_INSTALLED" == "true" ]; then
        CURRENT_NATIVESCRIPT_VERSION=""
    fi

    if [[ "$CURRENT_NATIVESCRIPT_VERSION" == *"$NATIVESCRIPT_VERSION"* ]] && [[ "$CURRENT_NATIVESCRIPT_VERSION" != *"($NATIVESCRIPT_VERSION)"* ]]; then
        echo "NS version is correct."
    else
        echo "Installing NativeScript... This can take a while..."

        npm i -g nativescript@$NATIVESCRIPT_VERSION >> $LOG_FILE

        echo "Installation of NativeScript is complete."
    fi

    echo "$(ns doctor)" >> $LOG_FILE & ns doctor

    wait

    echo "NativeScript checks complete."
}

prepare_project() {
    echo "Preparing project's environment (integration)"

    rm -rf ./platforms/ ./hooks/ $HOME/.gradle/caches/

    echo "Removing node modules after upgrade..."
    rm -rf ./node_modules
    echo "Node modules removal complete."

    echo "Cleaning pods cache..."
    pod cache clean --all
    echo "Pods cache clean-up complete."

    wait

    echo "Preparation of project's environment is complete."
}

# Remove unnecessary PATH variables as there might be cases when paths are updated
# Also make sure to strip newlines & make it working for both bash & zsh respectively
unset_paths() {
    PATHS_TO_REMOVE="NVM_DIR|ANDROID_HOME|ANDROID_SDK_ROOT|GEM_HOME|JAVA_HOME|PYENV|ruby|nvm/versions|openjdk|pyenv"
    grep -vE $PATHS_TO_REMOVE $ZSHRC_FILE > $ZSHRC_FILE-tmp && mv $ZSHRC_FILE-tmp $ZSHRC_FILE
    grep -vE $PATHS_TO_REMOVE $BASH_PROFILE_FILE > $BASH_PROFILE_FILE-tmp && mv $BASH_PROFILE_FILE-tmp $BASH_PROFILE_FILE
    awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' $ZSHRC_FILE > $ZSHRC_FILE-tmp && mv $ZSHRC_FILE-tmp $ZSHRC_FILE
    awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' $BASH_PROFILE_FILE > $BASH_PROFILE_FILE-tmp && mv $BASH_PROFILE_FILE-tmp $BASH_PROFILE_FILE
}

reload_shell_init_file() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        cat $ZSHRC_FILE >> $LOG_FILE
        source $ZSHRC_FILE
    else
        cat $BASH_PROFILE_FILE >> $LOG_FILE
        source $BASH_PROFILE_FILE
    fi
}

success_message() {
    echo "Current PATH: $PATH" >> $LOG_FILE

    echo "$(which ruby) | $(ruby -v 2>&1)" >> $LOG_FILE
    echo "$(which python) | $(python -V 2>&1)" >> $LOG_FILE
    echo "$(which pod) | $(pod --version 2>&1)" >> $LOG_FILE
    echo "$(which node) | $(node -v 2>&1)" >> $LOG_FILE
    echo "$(which ns)" >> $LOG_FILE
    echo "$(which java) | $(java -version 2>&1)" >> $LOG_FILE
    echo "$(which gem) | $(gem -v 2>&1)" >> $LOG_FILE
    echo "$(gem list)" >> $LOG_FILE
    echo "$(system_profiler SPDeveloperToolsDataType)" >> $LOG_FILE

    echo "\n\\033[32mSUCCESS! Everything is updated.\\033[0m"
}

initial_checks
start_message

unset_paths

install_brew
disable_brew_analytics

reinstall_java
reinstall_android_tools
reinstall_ruby_and_pods

install_software_updates

reinstall_python

install_gems

uninstall_node
install_nvm
install_node
install_ns

prepare_project

reload_shell_init_file
success_message