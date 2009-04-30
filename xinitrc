#!/bin/sh
DEFAULT_SESSION=awesome

case $1 in
	awesome) exec awesome ;;
	xterm) exec xterm ;;
	*) exec $DEFAULT_SESSION ;;
esac
