# Josh Dick's .zshrc <https://joshdick.net>

# *** MISC ***

# Clear out and reset PATH in case .zshrc is sourced multiple times in one session (while making changes)
# Do this before anything else so that this file can override any default settings that may be in /etc/profile
export PATH=$(env -i bash --login --norc -c 'echo $PATH')

# Test whether a given command exists
# Adapted from <http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script/3931779#3931779>
function command_exists() {
  hash "$1" &> /dev/null
}

# Include any machine-specific configuration if it exists
test -e ~/.localrc && . ~/.localrc

# When connecting via ssh, always [re]attach to a terminal manager
# Adapted from code found at <http://involution.com/2004/11/17/1-32/> (now offline)
if command_exists tmux && [ -z $TMUX ]; then
  if [ "$SSH_TTY" != "" -a "$TERM" -a "$TERM" != "screen" -a "$TERM" != "dumb" ]; then
    pgrep tmux
    # $? is the exit code of pgrep; 0 means there was a result (tmux is already running)
    if [ $? -eq 0 ]; then
      tmux -u attach -d
    else
      tmux -u
    fi
  fi
fi

# *** ZSH-SPECIFIC SETTINGS ***

HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt autocd beep nomatch prompt_subst correct inc_append_history interactivecomments share_history
unsetopt notify
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit && compinit
autoload -U colors && colors # Enable colors in prompt

# *** ZSH KEYBOARD SETTINGS ***

# Adapted from <http://zshwiki.org/home/zle/bindkeys#reading_terminfo<Paste>>

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="$terminfo[khome]"
key[End]="$terminfo[kend]"
key[Insert]="$terminfo[kich1]"
key[Backspace]="$terminfo[kbs]"
key[Delete]="$terminfo[kdch1]"
key[Up]="$terminfo[kcuu1]"
key[Down]="$terminfo[kcud1]"
key[Left]="$terminfo[kcub1]"
key[Right]="$terminfo[kcuf1]"
key[PageUp]="$terminfo[kpp]"
key[PageDown]="$terminfo[knp]"

# setup key accordingly
[[ -n "$key[Home]"      ]] && bindkey -- "$key[Home]"      beginning-of-line
[[ -n "$key[End]"       ]] && bindkey -- "$key[End]"       end-of-line
[[ -n "$key[Insert]"    ]] && bindkey -- "$key[Insert]"    overwrite-mode
[[ -n "$key[Backspace]" ]] && bindkey -- "$key[Backspace]" backward-delete-char
[[ -n "$key[Delete]"    ]] && bindkey -- "$key[Delete]"    delete-char
[[ -n "$key[Up]"        ]] && bindkey -- "$key[Up]"        up-line-or-history
[[ -n "$key[Down]"      ]] && bindkey -- "$key[Down]"      down-line-or-history
[[ -n "$key[Left]"      ]] && bindkey -- "$key[Left]"      backward-char
[[ -n "$key[Right]"     ]] && bindkey -- "$key[Right]"     forward-char
[[ -n "$key[PageUp]"    ]] && bindkey -- "$key[PageUp]"    history-beginning-search-backward
[[ -n "$key[PageDown]"  ]] && bindkey -- "$key[PageDown]"  history-beginning-search-forward

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        echoti smkx
    }
    function zle-line-finish () {
        echoti rmkx
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

# *** PROMPT FORMATTING ***

# Echoes a username/host string when connected over SSH (empty otherwise)
ssh_info() {
  [[ "$SSH_CONNECTION" != '' ]] && echo "%(!.%{$fg[red]%}.%{$fg[yellow]%})%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:" || echo ""
}

# Echoes information about Git repository status when inside a Git repository
git_info() {

  # Exit if not inside a Git repository
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  # Git branch/tag, or name-rev if on detached head
  local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

  local AHEAD="%{$fg[red]%}⇡NUM%{$reset_color%}"
  local BEHIND="%{$fg[cyan]%}⇣NUM%{$reset_color%}"
  local MERGING="%{$fg[magenta]%}⚡︎%{$reset_color%}"
  local UNTRACKED="%{$fg[red]%}●%{$reset_color%}"
  local MODIFIED="%{$fg[yellow]%}●%{$reset_color%}"
  local STAGED="%{$fg[green]%}●%{$reset_color%}"

  local -a DIVERGENCES
  local -a FLAGS

  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
  fi

  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
  fi

  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
    FLAGS+=( "$MERGING" )
  fi

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    FLAGS+=( "$UNTRACKED" )
  fi

  if ! git diff --quiet 2> /dev/null; then
    FLAGS+=( "$MODIFIED" )
  fi

  if ! git diff --cached --quiet 2> /dev/null; then
    FLAGS+=( "$STAGED" )
  fi

  local -a GIT_INFO
  GIT_INFO+=( "%{$fg[cyan]%}±" )
  [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
  [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
  GIT_INFO+=( "%{$fg[cyan]%}$GIT_LOCATION%{$reset_color%}" )
  echo "${(j: :)GIT_INFO}"

}

# Use ❯ as the non-root prompt character; # for root
# Change the prompt character color if the last command had a nonzero exit code
PS1="\$(ssh_info)%{$fg[magenta]%}%~%u \$(git_info) %(?.%{$fg[blue]%}.%{$fg[red]%})%(!.#.❯)%{$reset_color%} "

# *** HOMEBREW ***

# If we're on OS X and using Homebrew package manager, do some Homebrew-specific environmental tweaks
if command_exists brew; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

  # Assume Git was installed via Homebrew, and that the Git configuration below
  # should use Homebrew-provided locations instead of the defaults below
  GIT_BASH_COMPLETION_SOURCE="$HOMEBREW_PREFIX/etc/bash_completion.d/git-completion.bash"
  GIT_ZSH_COMPLETION_SOURCE="$HOMEBREW_PREFIX/share/zsh/site-functions/_git"
  GIT_DIFF_HIGHLIGHT_PATH="$HOMEBREW_PREFIX/share/git-core/contrib/diff-highlight"
else
  # Locations of the Git completion files for Arch Linux as of Git 1.8.1
  GIT_BASH_COMPLETION_SOURCE=/usr/share/git/completion/git-completion.bash
  GIT_ZSH_COMPLETION_SOURCE=/usr/share/git/completion/git-completion.zsh
  GIT_DIFF_HIGHLIGHT_PATH=~/.bin/diff-highlight
fi

# always install npm packages locally
export NPM_CONFIG_PREFIX="$HOME/.npm"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# always install pip packages locally
export PIP_USER=yes
export PATH="$HOME/.local/bin:$HOME/Library/Python/3.9/bin/:/usr/local/opt/findutils/libexec/gnubin:$PATH"

# always install gems locally with gem or bundler
GEM_HOME=~/.gem
export PATH="$GEM_HOME/bin:$PATH"

# SF development
sfi() { echo "${PWD##*/}" }

source <(kubectl completion zsh)

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
git config --global tag.sort version:refname

# Add sftools to PATH
export PATH="$PATH:$HOME/secureflag/sf-shell-utilities/bin"
