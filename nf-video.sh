#!/bin/bash

#==========================================================================
#
#         File: nf-video.sh
#
#        Usage: ./nf-video.sh -i $FILETOENCODE
#
#  Description: Runs a video job.
#
# Requirements: -t -c -d
#       Author: Christopher Mundus <crashGoBoom>
#      Project: nf-video
#      Created: 20190116
#==========================================================================


#==========================================================================
# Error checking
#==========================================================================
set -o errexit   # Exit when a command fails

#==========================================================================
# Constants
#==========================================================================
WARN="\033[31m"
INFO="\033[32m"
NOCOLOR="\033[0m"
INSTALL_DIR="/usr/local/bin"
CRF=23
X=10
Y=10

#==========================================================================
# Functions
#==========================================================================

#==== FUNCTION ============================================================
#         NAME: info
#  DESCRIPTION: Output some info.
#         ARGS: $1 = Type of info to display, $2 = Text to display
#      CREATED: 20190116
#==========================================================================

function log() {
  local type="$1" 
  local text="$2" 
  echo -e "${type}${text}${NOCOLOR}"
}

#==== FUNCTION ============================================================
#         NAME: usage
#  DESCRIPTION: Displays usage
#       AUTHOR: Christopher Mundus <chris@kindlyops.com>
#      CREATED: 20190115
#==========================================================================
function usage() {
  cat <<help_message
--- script subcommand -------------------------------------------------------------
Commands related to this script
USAGE:
  ./nf-video.sh [FLAGS] [SUBCOMMAND]
FLAGS:
  -c  CRF Number for ffmpeg
  -h  Prints help information
  -i  Video to Process (Required.)
  -w  Adds a watermark (Defaults to lower right.)
  -x  X location for the watermark
  -y  Y location for the watermark
SUBCOMMANDS:
  all                  Do everything (blah, blah2) [default]
help_message

  return 1
}

function get_opts() {
  #  Parse options to the main command.
  while getopts 'c:h?:w:i:x:y:' opt; do
    case "${opt}" in
      c)
        CRF="${OPTARG}"
      ;;
      h|\?)
        log $INFO "Help:\n-w Add a watermark image (PNG,JPG). "
        usage
      ;;
      i)
        VIDEO_INPUT=${OPTARG}
        log $INFO "Processing: ${VIDEO_INPUT}"
      ;;
      w)
        WATERMARK="${OPTARG}"
        log $INFO "Adding a watermark with ${WATERMARK}"
      ;;
      x)
        X="${OPTARG}"
      ;;
      y)
        Y="${OPTARG}"
      ;;
      *)
        usage
      ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ ${VIDEO_INPUT} = "" ]]; then
    log "${WARN}" "Please provide a video to process."
    usage
  fi

  #  Remove the main command from the argument list.
  local -r _subcommand="${1:-}"
  if [[ -z ${_subcommand} ]]; then
    install_nextflow
    run_nextflow
    return 0
  fi

  shift
  case "${_subcommand}" in
    run)
      run_nextflow
      ;;
    install)
      install_nextflow
      ;;
    *)
      usage
      ;;
  esac

  return 0
}

#==== FUNCTION ============================================================
#         NAME: install_nextflow
#  DESCRIPTION: Install nextflow if its not already.
#      CREATED: 20190116
#==========================================================================

function install_nextflow() {
  if type nextflow &>/dev/null; then
    log "${INFO}" "Nextflow found..."
    return 0
  elif type ./nextflow &>/dev/null; then
    log "${INFO}" "Nextflow found..."
    return 0
  else
    log "${WARN}" "Nextflow not found!"
    prompt_user "Would you like to install it?"
    log "${INFO}" "Installing from nextflow.io..."
    curl -s https://get.nextflow.io | bash >/dev/null
    mv "${PWD}/nextflow" "${INSTALL_DIR}/nextflow"
  fi
  return 0
}

#==== FUNCTION ============================================================
#         NAME: prompt_user
#  DESCRIPTION: Prompts the user for something.
#      CREATED: 20190116
#==========================================================================

function prompt_user() {
    log "${WARN}" "${1}"
    read -p "(Y)es or (N)o?" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        [[ "$0" = "${BASH_SOURCE[*]}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
}

#==== FUNCTION ============================================================
#         NAME: run_nextflow
#  DESCRIPTION: Run the nextflow command
#      CREATED: 20190116
#==========================================================================

function run_nextflow() {
  if nextflow run video.nf \
      --inputs="${VIDEO_INPUT}" \
      --watermark="${WATERMARK}" \
      --crf="${CRF}" \
      --y="${Y}" --x="${X}"; then
    log "${INFO}" "Successfully processed ${VIDEO_INPUT} as completed.mp4!"
    log "${INFO}" "Cleaning up..."
    nextflow clean -f &>/dev/null
  fi

  return 0
}

#==== FUNCTION ============================================================
#         NAME: main
#  DESCRIPTION: Triggers the whole process.
#      CREATED: 20190116
#==========================================================================

function main() {
  get_opts "${@}"

  return 0
}

main "${@}"