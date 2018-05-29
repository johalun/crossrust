# How to cross compile Rust from OS X to FreeBSD

## About this repository
This repository contain instructions on how to build a cross compiler and a set of files that I build on my El Capitan machine.

If you don't want to build the necessary files yourself, clone this repository, skip to Rust section and take it from there.

If you don't need a gcc cross compiler for C/C++ maybe there is a easier and faster way of making a cross toolchain for only Rust. Please let me know if you know it.


## Prerequisites
A FreeBSD 11 machine (real or virtual).  
A Mac OS X computer.  


## Setup
On OS X, declare variables we need and create the folder for cross compile files.  

`export REMOTEUSER=myusername`  
`export REMOTEIP=ip.to.remote.freebsd.machine`  
`export PREFIX=/opt/cross-freebsd`  
`export BUILD=/opt/build`  
`export TARGET=x86_64-unknown-freebsd11`

NOTE: target triple must contain version number postfix to build gcc.

`sudo mkdir -p $PREFIX`  
`sudo chown $USER $PREFIX`  
`sudo mkdir -p $BUILD`  
`sudo chown $USER $BUILD`  

We build our cross compiler using gcc because clang is not officially supported. Install using brew.  
View brew install instructions: http://brew.sh/  or install with  

`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

Install wget

`brew install wget`

Install gcc

`brew install gcc`

Configure make to use gcc and not Apple's clang.  

`export CC=/usr/local/bin/gcc-5`  
`export CXX=/usr/local/bin/g++-5`  
`export CPP=/usr/local/bin/cpp-5`  
`export LD=/usr/local/bin/gcc-5`  


## Make cross compiler
Reference: http://wiki.osdev.org/GCC_Cross-Compiler

### Binutils
`cd $BUILD`  
`wget http://ftp.gnu.org/gnu/binutils/binutils-2.26.tar.gz && tar xf binutil-2.26.tar.gz`  
`makedir build-binutil && cd build-binutil`  
`../binutils-2.26/configure --prefix=$PREFIX --target=$TARGET --enable-interwork --enable-multilib --disable-nls --disable-werror`  
`make -j4 && make install`

### Copy FreeBSD files
There should now be a folder `$PREFIX/x86_64-unknown-freebsd11`  
Copy files needed for compiling gcc from FreeBSD to it.  

`cd $PREFIX/x86_64-unknown-freebsd11`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/include .`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/lib/libc.so.7 lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libc_nonshared.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libssp_nonshared.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/crt1.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/crti.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/crtn.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libc.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libc.so lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libm.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libm.so lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libpthread.so lib/`  

To later cross compile Rust programs we need a few more files.

`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/Scrt1.a lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/libexecinfo.so lib/`  
`rsync -avL $REMOTEUSER@$REMOTEIP:/usr/lib/librt.so lib/`  

### GCC
`cd $BUILD`  
`wget http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.zip && unzip mpfr-3.1.4.zip`  
`wget http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz && tar xf mpc-1.0.3.tar.gz`  
`wget http://ftp.gnu.org/gnu/gmp/gmp-6.1.0.tar.xz && tar xf gmp-6.1.0.tar.xz`  
`wget http://ftp.gnu.org/gnu/gcc/gcc-5.3.0/gcc-5.3.0.tar.gz && tar xf gcc-5.3.0.tar.gz`

Link in libraries so they will be built together with gcc.

`ln -s mpfr-3.1.4 gcc-5.3.0/mpfr`  
`ln -s mpc-1.0.3 gcc-5.3.0/mpc`  
`ln -s gmp-6.1.0 gcc-5.3.0/gmp`  
`makedir build-gcc && cd build-gcc`  
`../gcc-5.3.0/configure --prefix=$PREFIX --target=$TARGET --disable-nls --enable-languages=c,c++ --without-headers --enable-interwork --enable-multilib`  
`make -j4 && make install`


## Rust
Multirust install instructions: https://github.com/brson/multirust

Install with  

`curl -sf https://raw.githubusercontent.com/brson/multirust/master/blastoff.sh | sh`

Add files for cross compilation  

`multirust add-target nightly x86_64-unknown-freebsd`

### Cargo
We need to configure cargo to use our new toolchain. If you cloned this repository instead of building it yourself, replace $PREFIX with the path to the repository.

`echo "[target.x86_64-unknown-freebsd]" >> ~/.cargo/config`  
`echo "linker = $PREFIX/bin/x86_64-unknown-freebsd11-gcc" >> ~/.cargo/config`


## Finally, Cross Compile
Create new project

`cargo new --bin helloworld`  
`cd helloworld`  

Tell multirust to use nightly for this folder  

`multirust override nightly`  

Compile

`cargo build --target x86_64-unknown-freebsd`  

Check file properties with

`file target/x86_64-unknown-freebsd/debug/helloworld`

should return something like  
`target/x86_64-unknown-freebsd/debug/helloworld: ELF 64-bit LSB shared object, x86-64, version 1 (FreeBSD), dynamically linked (uses shared libs), for FreeBSD 11.0 (1100097), not stripped`

### Run on remote machine
`scp target/x86_64-unknown-freebsd/debug/helloworld $REMOTEUSER@$REMOTEIP:/tmp/helloworld`  
`ssh $REMOTEUSER@$REMOTEIP /tmp/helloworld`

Expected output should be  
`Hello, world!`
