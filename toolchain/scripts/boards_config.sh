#!/bin/bash

get_board_id() {
    case $1 in
        x1slte) echo "SRPSJ28B018KU" ;;
        x1s)    echo "SRPSI19A018KU" ;;
        y2slte) echo "SRPSJ28A018KU" ;;
        y2s)    echo "SRPSG12A018KU" ;;
        z3s)    echo "SRPSI19B018KU" ;;
        c1slte) echo "SRPTC30B009KU" ;;
        c1s)    echo "SRPTB27D009KU" ;;
        c2slte) echo "SRPTC30A009KU" ;;
        c2s)    echo "SRPTB27C009KU" ;;
        r8s)    echo "SRPTF26B014KU" ;;
        *)      return 1 ;;
    esac
}
