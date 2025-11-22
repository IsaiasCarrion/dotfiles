#!/bin/bash

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_message() {
    echo -e "${BLUE}[LOG] $1${NC}"
}

print_info() {
    echo -e "${BLUE}➜ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

print_error() {
    echo -e "${RED}✖ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

run_command() {
    local cmd="$1"
    local desc="$2"
    local critical="$3" # "yes" para salir si falla
    
    # MODO SIMULACIÓN (DRY RUN)
    if [ "$DRY_RUN" == "1" ]; then
        echo -e "${YELLOW}[DRY-RUN] Would execute:${NC} $cmd"
        echo -e "${YELLOW}          Description:${NC} $desc"
        return 0
    fi

    # EJECUCIÓN REAL
    echo -ne "${BLUE}Running: $desc...${NC}"
    
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e " ${GREEN}OK${NC}"
        return 0
    else
        echo -e " ${RED}FAILED${NC}"
        if [ "$critical" == "yes" ]; then
            echo -e "${RED}Error crítico ejecutando: $cmd${NC}"
            exit 1
        fi
        return 1
    fi
}
