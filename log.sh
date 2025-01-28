#! /bin/bash

# variable used
run_command_is_piped=0
run_command_no_log_error=0

LOG_DEBUG=${LOG_DEBUG:-1}
LOG_EXIT_ON_ERROR=${LOG_EXIT_ON_ERROR:-0}

LOG_GREEN='\033[0;32m'
LOG_RED='\033[0;31m'
LOG_YELLOW='\033[1;33m'
LOG_CYAN='\033[0;36m'
LOG_GREY='\033[1;36m'
LOG_MAGENTA='\033[1;35m'
LOG_NC='\033[0m' # No Color

get_log_data() {
  local data
  if [ -n "$*" ]; then
    # Read data from arguments
    data="$*"
  elif [ ! -t 0 ]; then
    # Read data from stdin (pipe or <<EOM)
    IFS= read -r data <&0
  else
    data="I dont know what is there to log..."
  fi
  printf "%s\n" "$data"
}

log_info() {
  printf "${LOG_GREEN}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

log_debug() {
  printf "${LOG_GREY}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

log_step() {
  printf "${LOG_YELLOW}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

log_command() {
  printf "${LOG_CYAN}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

log_warn() {
  printf "${LOG_MAGENTA}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

log_error() {
  printf "${LOG_RED}%s${LOG_NC}\n" "$(get_log_data "$*")" >&2
}

exit_error() {
  log_error "$@" >&2
  exit 1
}

# Simply display the command and run it
# run_command echo "Hello World" # --> output: "Hello World"
run_command() {
  local prefix=
  [ "$run_command_is_piped" = '1' ] && prefix=' | '
  [ "$LOG_DEBUG" = '1' ] && log_command "${prefix}$*"
  "$@" || {
    status=$?
    # If it ok to have an error, just return the status
    [ "$run_command_no_log_error" = '1' ] && return $status
    log_error "[ERROR] The following command failed with status $status:" && log_command "$*"
    [ "$LOG_EXIT_ON_ERROR" = '1' ] && exit $status
    return $status
  }
}

# Same as run_command but will not log an error if an error occurs
# eg. useful when checking a string does not exist with grep
run_command_nerr() {
  run_command_no_log_error=1 run_command "$@"
}

# Display the command, run it and hide its output but display it in case of error
# run_command_hide echo "Hello World" # --> no output
# run_command_hide cat "Hello World" # --> output: An error saying that file "Hello World" does not exist
run_command_hide() {
  local command_output
  command_output=$(mktemp)

  [ "$LOG_DEBUG" = '1' ] && log_command "$@"
  "$@" &>"$command_output" || {
    status=$?
    # If it ok to have an error, just return the status
    [ "$run_command_no_log_error" = '1' ] && return $status
    log_error "[ERROR] The following command failed with status $status:" && log_command "$*"
    cat "$command_output" >&2
    rm -f "$command_output"
    [ "$LOG_EXIT_ON_ERROR" = '1' ] && exit $status
    return $status
  }
  rm -f "$command_output"
  return 0
}

# Similar to run_command_hide but does not display the output in case of error
run_command_hide_nerr() {
  run_command_no_log_error=1 run_command_hide "$@"
}

# Similar to run_command but with eval
# it allows to run command starting with !, variables or any valid shell
run_command_eval() {
  local prefix=
  [ "$run_command_is_piped" = '1' ] && prefix=' | '
  local command_output
  command_output=$(mktemp)

  [ "$LOG_DEBUG" = '1' ] && log_command "${prefix}$*"
  eval "$*" &>"$command_output" || {
    status=$?
    # If it ok to have an error, just return the status
    [ "$run_command_no_log_error" = '1' ] && return $status
    log_error "[ERROR] The following command failed with status $status:" && log_command "$*"
    cat "$command_output" >&2
    rm -f "$command_output"
    [ "$LOG_EXIT_ON_ERROR" = '1' ] && exit $status
    return $status
  }
  rm -f "$command_output"
  return 0
}

# Specify the command is piped so run_command will add ' | ' while logging the command
# eg. run_command echo "Hello world" | run_command_piped grep -i "hello" will output:
#  echo Hello world
#  |  grep -i hello
run_command_piped() {
  run_command_is_piped=1 run_command "$@"
}

# Same as run_command_piped but will not log an error if an error occurs
# eg. useful when checking a string does not exist with grep
run_command_piped_nerr() {
  run_command_is_piped=1 run_command_no_log_error=1 run_command "$@"
}

# Similar to run_command_piped but with eval
# it allows to run command starting with !, variables or any valid shell
run_command_piped_eval() {
  run_command_is_piped=1 run_command_eval "$@"
}
