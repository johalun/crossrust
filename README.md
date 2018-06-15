# How to cross compile Rust from macOS to FreeBSD

## About this repository

This repository contain a script that will download and build cross
compile tools that can cross compile Rust from macOS to FreeBSD.  
  
It will also cross compile a hello world crate and execute on the
remote machine.

## Prerequisites

A real or virtual FreeBSD 11 or 12 (10 or older is untested) machine.  
A macOS computer.  
  
For VirtualBox make sure you configure port forwarding so that you can
ssh in to the machine.  
  
Before running the script make sure to install `brew` and
`rustup`. You will be prompted if anything is missing.

Check in `build.sh` for more details.

