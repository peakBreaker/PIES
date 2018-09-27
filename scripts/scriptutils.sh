# For colored debugging

LOG_INFO_COLOR='\e[1;34m'
LOG_SUCCESS_COLOR='\e[32m'
LOG_WARN_COLOR='\e[33m'
LOG_ERROR_COLOR='\e[31m'
LOG_DEFAULT_COLOR='\e[37m'

# Main logging function
LOG()
{
  local log_text="$1"
  local log_level="$2"
  local log_color="$3"
  
  # # Default level to "info"
  # [[ -z ${log_level} ]] && log_level="INFO";
  # [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

  echo "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] [${log_level}]${LOG_DEFAULT_COLOR} ${log_text} ";
  return 0;
}

INFO() { LOG "$1$2" "INFO" $LOG_INFO_COLOR; }
SUCCESS() { LOG "$1" "SUCCESS" $LOG_SUCCESS_COLOR; }
WARN() { LOG "$1" "WARN" $LOG_WARN_COLOR; }
ERROR() { LOG "$1" "ERROR" $LOG_ERROR_COLOR; }
