#!/bin/sh
echo "1..1"

basedir=$(dirname $0)/..

$basedir/perl -c $basedir/lib/I401/Main.pm && echo "ok 1"
