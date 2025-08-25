# shellcheck shell=bash

log_info() {
  echo -e "\033[0;36m[INFO]\033[0m $1"      # Bright cyan
}

log_success() {
  echo -e "\033[0;92m[SUCCESS]\033[0m $1"   # Bright green
}

log_warning() {
  echo -e "\033[0;93m[WARNING]\033[0m $1"   # Bright yellow
}

log_error() {
  echo -e "\033[1;91m[ERROR]\033[0m $1"     # Bright red with bold
}
