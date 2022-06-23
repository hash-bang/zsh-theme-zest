# Colors can be:
# - ANSI code: e.g. black, yellow, gray
# - 256 color code: e.g. 33, 19 (see https://michurin.github.io/xterm256-color-picker/)
#   Use `spectrum_ls` to get a list of valid colors
# - HEX code: #434C5E (only ZSH@>=5.7)

# Ensure that the RGB color handler is loaded, otherwise raise a public error
zmodload zsh/nearcolor

ZSH_THEME_SEGMENT_SEPARATOR='\ue0b0'

ZSH_THEME_STATUS_ENABLE="1"
ZSH_THEME_STATUS_COLOR_BG="black"
ZSH_THEME_STATUS_COLOR_RETVAL_NONZERO_FG="yellow"
ZSH_THEME_STATUS_COLOR_ROOT_FG="yellow"
ZSH_THEME_STATUS_COLOR_JOBS_FG="cyan"

# Enable hostname component: 0 - disable, 1 - always enable, 2 - only if the dialed into another server via SSH
ZSH_THEME_HOSTNAME_ENABLE="2"
ZSH_THEME_HOSTNAME_COLOR_BG="#ECBE7B"
ZSH_THEME_HOSTNAME_COLOR_FG="#3B4252"

# How to display paths, '%1d' - current directory only, '%d' - full path, '%~' - Shortened home full path (i.e. display `~` when the path starts with `$HOME`)
ZSH_THEME_PATH_FORMAT="%~"
ZSH_THEME_PATH_COLOR_BG="#81A1C1"
ZSH_THEME_PATH_COLOR_FG="#3B4252"

ZSH_THEME_GIT_COLOR_BG="#434C5E"
ZSH_THEME_GIT_COLOR_FG="#D8DEE9"
# Rewrite "master" with a symbol instead of showing the name - dirty + non-dirty
ZSH_THEME_GIT_REWRITE_REPLACE_ENABLE="1"
ZSH_THEME_GIT_REWRITE_REPLACE_BRANCHES=("master", "main")
ZSH_THEME_GIT_REWRITE_REPLACE_DIRTY='~'
ZSH_THEME_GIT_REWRITE_REPLACE_NONDIRTY='✔'

ZSH_THEME_GIT_SYMBOLS_ENABLE="0"
# Symbols for each part of the Git prompt
ZSH_THEME_GIT_PROMPT_UNTRACKED=" ✭"
ZSH_THEME_GIT_PROMPT_STASHED=' ⚑'
ZSH_THEME_GIT_PROMPT_DIVERGED=' ⚡'
ZSH_THEME_GIT_PROMPT_ADDED=" ✚"
ZSH_THEME_GIT_PROMPT_MODIFIED=" ✹"
ZSH_THEME_GIT_PROMPT_DELETED=" ✖"
ZSH_THEME_GIT_PROMPT_RENAMED=" ➜"
ZSH_THEME_GIT_PROMPT_UNMERGED=" ═"
ZSH_THEME_GIT_PROMPT_AHEAD=' ⬆'
ZSH_THEME_GIT_PROMPT_BEHIND=' ⬇'
ZSH_THEME_GIT_PROMPT_DIRTY=''


# --- No config below this line ---


# Local state tracking
CURRENT_BG='NONE'

# build_prompt() - main prompt sequence builder {{{
build_prompt() {
	if [[ "$ZSH_THEME_STATUS_ENABLE" == '1' ]]; then
		RETVAL=$?
		prompt_status
	fi
	prompt_user_hostname
	prompt_path
	prompt_git
	prompt_end
}
# }}}

# prompt_status() - display status of last executed command {{{
prompt_status() {
	local SYMBOLS
	SYMBOLS=()

	# Was there an error?
	[[ $RETVAL -ne 0 ]] && SYMBOLS+="%{%F{$ZSH_THEME_STATUS_COLOR_RETVAL_NONZERO_FG}%}✖"

	# Am I root?
	[[ $UID -eq 0 ]] && SYMBOLS+="%{%F{$ZSH_THEME_STATUS_COLOR_ROOT_FG}%}⚡"

	# Are there background jobs?
	[[ $(jobs -l | wc -l) -gt 0 ]] && SYMBOLS+="%{%F{$ZSH_THEME_STATUS_COLOR_JOBS_FG}%}⚙"

	[[ -n "$SYMBOLS" ]] && prompt_segment "$ZSH_THEME_STATUS_COLOR_BG" default "$SYMBOLS"
}
# }}}

# prompt_segment(bg, fg, content) {{{
prompt_segment() {
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}" || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
		echo -n " %{$bg%F{$CURRENT_BG}%}$ZSH_THEME_SEGMENT_SEPARATOR%{$fg%} "
	else
		echo -n "%{$bg%}%{$fg%} "
	fi
	CURRENT_BG=$1
	[[ -n $3 ]] && echo -n $3
}
# }}}

# prompt_user_hostname() - Show the hostname if it differs from the current machine {{{
prompt_user_hostname() {
	local user=`whoami`

	if [[ "$ZSH_THEME_HOSTNAME_ENABLE" == '1' || -n "$SSH_CLIENT" ]]; then
		prompt_segment "$ZSH_THEME_HOSTNAME_COLOR_BG" "$ZSH_THEME_HOSTNAME_COLOR_FG" "$user@%m"
	fi
}
# }}}

# prompt_path() - Show the current directory {{{
prompt_path() {
	prompt_segment "$ZSH_THEME_PATH_COLOR_BG" "$ZSH_THEME_PATH_COLOR_FG" "$ZSH_THEME_PATH_FORMAT"
}
# }}}

# prompt_git() - Show Git status, either simplied (dirty / not dirty), or with change display {{{
prompt_git() {
	local ref dirty
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		DIRTY=$(parse_git_dirty)
		REF=$(git symbolic-ref HEAD 2> /dev/null)
		REF="${REF/refs\/heads\//}"
		prompt_segment "$ZSH_THEME_GIT_COLOR_BG" "$ZSH_THEME_GIT_COLOR_FG"

		if [[ "$ZSH_THEME_GIT_REWRITE_REPLACE_ENABLE" == "1" && "${IFS}${ZSH_THEME_GIT_REWRITE_REPLACE_BRANCHES[*]}${IFS}" =~ "${IFS}${REF}${IFS}" ]]; then
			if [ -n $DIRTY ]; then
				REF="$ZSH_THEME_GIT_REWRITE_REPLACE_DIRTY"
			else
				REF="$ZSH_THEME_GIT_REWRITE_REPLACE_NONDIRTY"
			fi
		fi

		if [[ "$ZSH_THEME_GIT_SYMBOLS_ENABLE" == '1' ]]; then
			echo -n "${REF}${DIRTY}"$(git_prompt_status)
		else
			echo -n "${REF}${DIRTY}"
		fi
	fi
}
# }}}

# prompt_end() - Finish prompt and close out color escapes {{{
prompt_end() {
	if [[ -n $CURRENT_BG ]]; then
		echo -n " %{%k%F{$CURRENT_BG}%}$ZSH_THEME_SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''
}
# }}}

PROMPT='%{%f%b%k%}$(build_prompt) '
