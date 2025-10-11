#!/bin/sh
echo "1..1"

basedir=$(dirname $0)/..

$basedir/perl -c $basedir/lib/I401/WSServer.pm && echo "ok 1"
