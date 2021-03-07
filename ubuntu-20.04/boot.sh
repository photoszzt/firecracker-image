#!/bin/sh

/bin/mount proc /proc -t proc
haveged

/usr/bin/python3 /kcmd_run.py
