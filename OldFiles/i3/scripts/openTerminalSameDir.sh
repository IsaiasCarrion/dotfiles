#!/bin/bash
WHEREAMI=$(cat /tmp/whereami)
kitty --working-directory="$WHEREAMI"
