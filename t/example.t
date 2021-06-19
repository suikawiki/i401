#!/bin/sh
echo "1..1"

basedir=$(dirname $0)/..

$basedir/perl -c $basedir/example/bot.pl && echo "ok 1"
