set -g __prompt_host (hostname|cut -d . -f 1)

function __prompt_tmux
	if test $TERM != tmux; return; end
	set session (tmux display-message -p "#S")
	if test $session != 0
		echo -n $__prompt_fg_mux$session$__prompt_fg_sep'|'
	end
	echo -n $__prompt_fg_mux(tmux display-message -p "#I")$__prompt_fg_sep'.'
end

function __prompt_whereami
	set -l dir (pwd | sed -e "s,^$HOME,~,")
	set -l len (echo $dir | awk '{ print length }')
	if test $len -gt 32
		echo -n …(echo $dir | cut -c(expr $len - 32)-$len)
	else
		echo -n $dir
	end
end

function __prompt_git_location
	set -l branch (git symbolic-ref HEAD ^/dev/null|cut -d '/' -f 3)
	set -l snipped ""
	if test (echo $branch | awk '{ print length }') -gt 16
		set snipped (echo $branch | cut -c1-15)…
	else
		set snipped $branch
	end
	set -l tag (git describe --tags --exact-match HEAD ^/dev/null)
	if test -z "$snipped$tag"
		echo -n $__prompt_fg_branch' <detached> '
		return
	end
	echo -n $__prompt_fg_sep' on '
	test -n "$snipped"; and echo -n $__prompt_fg_branch$snipped
	test -n "$tag"; and echo -n $__prompt_fg_sep'#'$__prompt_fg_branch$tag;
	echo -n ' '
end

function __prompt_statuschar
	echo $__prompt_gs_staged | grep -b $argv[1] >/dev/null ^&1
	and echo -n $__prompt_reset$argv[2]
	echo $__prompt_gs_indexed | grep -b $argv[1] >/dev/null ^&1
	and echo -n $__prompt_fg_branch$argv[2]
end

function __prompt_git_status
	set -l gs (git status --porcelain ^/dev/null|cut -c 1-2|sort|tr -d '\n')

	# Exist if everything is hunky dory
	test -z $gs; and echo -n $__prompt_fg_good'✔'; and return 0

	# Check if there are unmerged or unstaged files
	echo $gs|grep -qe "^\(..\)*\(UU\|AA\)"; and set unmerged
	echo $gs|grep -qe "^\(..\)*??"; and set unstaged

	# Split up the index flags and the staging flags
	set -g __prompt_gs_indexed (echo $gs|sed -e "s/\(.\)./\1/g"|tr -d '?U')
	set -g __prompt_gs_staged (echo $gs|sed -e "s/.\(.\)/\1/g"|tr -d '?U')

	__prompt_statuschar 'M' '*'
	__prompt_statuschar 'A' '+'
	__prompt_statuschar 'R' '→'
	__prompt_statuschar 'C' '⇒'
	__prompt_statuschar 'D' '✗'

	set -e __prompt_gs_indexed
	set -e __prompt_gs_staged
	set -q unstaged; and echo -n $__prompt_fg_warning'?'
	set -q unmerged; and echo -n $__prompt_fg_bad'!'
	return 0
end

function fish_prompt
	set laststatus $status
	# Stick in some multiplexor state
	__prompt_tmux
	# Username
	echo -n $__prompt_fg_user(whoami)$__prompt_fg_at'@'
	# Host
	echo -n $__prompt_fg_host$__prompt_host$__prompt_fg_sep':'
	# Location
	echo -n $__prompt_fg_path(__prompt_whereami)
	# Become aware of the repository
	set -l gitdir (git rev-parse --git-dir ^/dev/null)
	test -n "$gitdir";
	and __prompt_git_location
	# Consider __prompt_git_upstream here when you know what you're doing
	and __prompt_git_status
	# Multi-lineification & status color
	test $laststatus -ne 0
	and echo $__prompt_fg_bad
	or echo $__prompt_fg_prompt
	# Repository aware prompt character
	test -n "$gitdir"; and echo -n »; or echo -n →
	# Prep for user input
	echo -n $__prompt_reset' '
end
