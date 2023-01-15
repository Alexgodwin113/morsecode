#!/bin/bash
as -g -o $1.o $1.s && gcc -g -o $1 $1.o
