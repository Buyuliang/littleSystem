#! /bin/bash  
  
# Defining transition function  
function convert_size() {  
    local size=$1  
    local suffix=${size: -1}  
    local value=${size%?}  
  
    # Remove everything after the decimal point, if any, in order to handle the decimal part separately
    local integer_part=${value%%.*}  
    local decimal_part=${value#*.}  
    # Only take the first decimal place, if you need more digits can be adjusted
    decimal_part=${decimal_part:0:1}
  
    # The initial scale is 1, which means that a decimal place is reserved for bc operations 
    export BC_LINE_LENGTH=0  
    local scale=1  
      
    case $suffix in  
        K) value=$(echo "scale=$scale; $integer_part * 1024 + $decimal_part / 10.0 * 1024" | bc) ;; # Kilobytes  
        M) value=$(echo "scale=$scale; $integer_part * 1024 * 1024 + $decimal_part / 10.0 * 1024 * 1024" | bc) ;; # Megabytes  
        G) value=$(echo "scale=$scale; $integer_part * 1024 * 1024 * 1024 + $decimal_part / 10.0 * 1024 * 1024 * 1024" | bc) ;; # Gigabytes  
        *) echo "Unknown suffix $suffix" >&2; exit 1 ;;  
    esac  
    value=${value%%.*}
    echo $value  
}  
