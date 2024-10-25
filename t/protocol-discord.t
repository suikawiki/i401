#!/bin/sh
echo "1..1"

basedir=$(dirname $0)/..

$basedir/perl -c $basedir/lib/I401/Protocol/Discord.pm && echo "ok 1"
