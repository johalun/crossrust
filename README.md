# How to cross compile Rust from macOS to FreeBSD

## About this repository

This repository contain a script that will download and build cross
compile tools that can cross compile Rust from macOS to FreeBSD.  
  
It will also cross compile a hello world crate and execute on the
remote machine.  
  
This is not meant to be a solution that works for everyone out of the
box but hopefully it can help you get started to create your cross
compile environment.

## Prerequisites

A real or virtual FreeBSD 11 or 12 (10 or older is untested) machine.  
A macOS computer.  
  
For VirtualBox make sure you configure port forwarding so that you can
ssh in to the machine.  
  
Before running the script make sure to install `brew` and
`rustup`. You will be prompted if anything is missing.

Change the parameters in the top of `build.sh` to suite your system
then just type
`./build.sh`
in the checkout folder.
