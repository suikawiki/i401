#!/bin/sh
echo "1..1"

basedir=$(dirname $0)/..

ls $basedir/lib/I401/Rule/*.pm | \
xargs -l1 -i% \
$basedir/perl -c % && echo "ok 1"
