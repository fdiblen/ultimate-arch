# Plugins
# ====================================
# fisher
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end


# General settings
# ====================================
# disable welcome message
set fish_greeting


# Environment variables
# ====================================
set -gx EDITOR vim
set -gx XDG_CONFIG_HOME $HOME'/.config'
set -gx DOCKER_ID_USER "fdiblen"
#set -gx JAVA_HOME /usr/lib/jvm/default
set -gx JAVA_HOME /opt/android-studio/jre


# Aliases
# ====================================


# Notification settings
# ====================================
set -U __done_min_cmd_duration 600000 # 10 mins 
set -U __done_exclude 'git (?!push|pull)'
#set -U __done_notification_command 'some custom command'


# Python virtual environment
# ====================================

# virtualenv prompt
if set -q VIRTUAL_ENV
    echo -n -s (set_color -b blue white) "(" (basename "$VIRTUAL_ENV") ")" (set_color normal) " "
end

## pyenv
#if type -q pyenv
#  set -gx PYENV_ROOT $HOME/.pyenv
#  status --is-interactive;
#  source (pyenv init -|psub)
#  #status --is-interactive;
#  source (pyenv virtualenv-init -|psub)
#end

## virtualfish
#eval (python -m virtualfish)

# venv
. ~/.venv/bin/activate.fish


# Node.js
# ====================================
function nvm
  set -gx NVM_DIR $HOME/.nvm
  bass source /usr/share/nvm/nvm.sh ';' nvm $argv
end 
set -gx NVM_DIR $HOME/.nvm
bass source /usr/share/nvm/nvm.sh


# Snapd
# ====================================
#set -gx PATH $PATH /var/lib/snapd/snap/bin


# Android sdk
# ====================================
#set -gx ANDROID_HOME /opt/android-sdk
set -gx ANDROID_HOME /home/fdiblen/Android/Sdk
set -gx PATH $PATH $ANDROID_HOME/tools
set -gx PATH $PATH $ANDROID_HOME/tools/bin
set -gx PATH $PATH $ANDROID_HOME/platform-tools 
set -gx PATH $PATH /opt/android-studio/gradle/gradle-5.1.1/bin
#set -gx ANDROID_SWT /usr/share/java

