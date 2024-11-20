#!/bin/sh
acme -Wtype-mismatch -r test.lst -v test.b
acme -Wtype-mismatch -r ramtest.lst -v ramtest.b
#acme -v ramtest.b
