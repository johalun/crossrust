#!/usr/bin/env sh

REMOTEUSER=${USER}  # Remote login for root not allowed in default settings
REMOTEIP=127.0.0.1  # Remote machine is in a VirtualBox on localhost
REMOTEPORT=2222     # VirtualBox might require port forwarding on localhost

# ^^^ DEFINITELY CONFIGURE THE ABOVE ^^^

PREFIX=`pwd`/crossrust
TOOLCHAIN=${PREFIX}/toolchain
SYSROOT=${PREFIX}/sysroot_mount
BUILD=${PREFIX}/build
DOWNLOAD=`pwd`/download
LOG=${PREFIX}/build.log
NCPUS=`sysctl -n hw.ncpu`
GCCMAJOR=8
BINUTILSVERSION=2.30
MPFRVERSION=4.0.1
MPCVERSION=1.1.0
GMPVERSION=6.1.2

# ^^^ TWEAK ABOVE IF NEEDED ^^^

REMOTEVERSIONLONG=`ssh -p ${REMOTEPORT} ${REMOTEUSER}@${REMOTEIP} sysctl -n kern.osreldate` || (echo Error reading remote OS version && exit)
REMOTEVERSION=${REMOTEVERSIONLONG:0:2}
TARGET=x86_64-unknown-freebsd${REMOTEVERSION}

export CC=/usr/local/bin/gcc-${GCCMAJOR}
export CXX=/usr/local/bin/g++-${GCCMAJOR}
export CPP=/usr/local/bin/cpp-${GCCMAJOR}
export LD=/usr/local/bin/gcc-${GCCMAJOR}

if [ ! -d ${PREFIX} ]
then
    echo "===> Creating dir ${PREFIX}"
    mkdir -p ${PREFIX} || (echo "mkdir -p ${PREFIX} failed. Trying with sudo." && sudo mkdir -p ${PREFIX} && sudo chown ${USER} ${PREFIX} || exit 1)
fi
mkdir -p ${BUILD} || exit 1
mkdir -p ${TOOLCHAIN} || exit 1
mkdir -p ${SYSROOT} || exit 1
mkdir -p ${DOWNLOAD} || exit 1

touch ${LOG}
echo Starting log > ${LOG}


rsync --version >> ${LOG} && echo "===> Found rsync" || (echo "Please install rsync" && exit 1)
ssh -p ${REMOTEPORT} ${REMOTEUSER}@${REMOTEIP} rsync --version >> ${LOG}  && echo "===> Found remote rsync"  || (echo "Please install rsync on remote machine" && exit 1)

brew -v >> ${LOG} && echo "===> Found brew" || (echo "Please install brew" && exit 1)
if [ ! -f ${PREFIX}/.brew ]
then
    echo "===> Installing tools with brew"
    brew install gcc@${GCCMAJOR} || exit 1
    brew install wget || exit 1
    brew cask install osxfuse || exit 1
    brew install sshfs || exit 1
    touch ${PREFIX}/.brew
else
    echo "===> Skipping install tools"
fi

${CC} --version >> ${LOG} && echo "===> Found ${CC}" || (echo "${CC} not found" && exit 1)
GCCVERSION=`${CC} --version | head -n 1 | awk '{print $5}'`


echo "===> Mounting remote root with sshfs as sysroot at ${SYSROOT}"
sshfs -p ${REMOTEPORT} -o idmap=user,follow_symlinks ${REMOTEUSER}@${REMOTEIP}:/ ${SYSROOT} || exit 1

#
# Download tarballs
#
if [ ! -f ${PREFIX}/.fetch ]
then
    echo "===> Fetching tarballs"
    cd ${DOWNLOAD}
    wget -c http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVERSION}.tar.gz || exit 1
    wget -c http://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVERSION}.zip || exit 1
    wget -c http://ftp.gnu.org/gnu/mpc/mpc-${MPCVERSION}.tar.gz || exit 1
    wget -c http://ftp.gnu.org/gnu/gmp/gmp-${GMPVERSION}.tar.xz || exit 1
    wget -c http://ftp.gnu.org/gnu/gcc/gcc-${GCCVERSION}/gcc-${GCCVERSION}.tar.gz || exit 1
    touch ${PREFIX}/.fetch
else
    echo "===> Skipping fetch tarballs"
fi


#
# Extract tarballs
#
if [ ! -f ${PREFIX}/.extract ]
then
    echo "===> Extracting tarballs"
    cd ${BUILD}
    tar xf ${DOWNLOAD}/binutils-${BINUTILSVERSION}.tar.gz || exit 1
    unzip -q ${DOWNLOAD}/mpfr-${MPFRVERSION}.zip || exit 1
    tar xf ${DOWNLOAD}/mpc-${MPCVERSION}.tar.gz || exit 1
    tar xf ${DOWNLOAD}/gmp-${GMPVERSION}.tar.xz || exit 1
    tar xf ${DOWNLOAD}/gcc-${GCCVERSION}.tar.gz || exit 1
    touch ${PREFIX}/.extract
else
    echo "===> Skipping extract tarballs"
fi


#
# Build binutils
#
if [ ! -f ${PREFIX}/.binutils ]
then
    echo "===> Building binutils"
    cd ${BUILD}
    mkdir -p build-binutils || exit 1
    cd build-binutils
    ../binutils-${BINUTILSVERSION}/configure --prefix=${TOOLCHAIN} --target=${TARGET} --with-sysroot=${SYSROOT} \
		--enable-interwork --enable-multilib --disable-nls --disable-werror || exit 1
    make -j${NCPUS} || exit 1
    make install || exit 1
    touch ${PREFIX}/.binutils
else
    echo "===> Skipping binutils"
fi



#
# GCC
#
# Link in libraries so they will be built together with gcc.
cd ${BUILD}
ln -sf mpfr-${MPFRVERSION} gcc-${GCCVERSION}/mpfr || exit 1
ln -sf mpc-${MPCVERSION} gcc-${GCCVERSION}/mpc || exit 1
ln -sf gmp-${GMPVERSION} gcc-${GCCVERSION}/gmp || exit 1

# Build GCC
if [ ! -f ${PREFIX}/.buildgcc ]
then
    echo "===> Building gcc"
    cd ${BUILD}
    rm -fr build-gcc > /dev/null
    mkdir -p build-gcc || exit 1
    cd build-gcc
    ../gcc-${GCCVERSION}/configure --prefix=${TOOLCHAIN} --target=${TARGET} --with-sysroot=${SYSROOT} \
	   --disable-nls --enable-languages=c,c++ --without-headers --enable-interwork --enable-multilib || exit 1
    make -j${NCPUS} || exit 1
    make install || exit 1
    touch ${PREFIX}/.buildgcc
else
    echo "===> Skipping build gcc"
fi

unset CC
unset CXX
unset CPP
unset LD

#
# Rust
#
rustup -V >> ${LOG} && echo "===> Found rustup" || (echo "Please install rustup" && exit 1)


# Download toolchain
if [ ! -f ${PREFIX}/.rustup ]
then
    echo "===> Installing rust toolchains"
    rustup toolchain install nightly
    rustup target add x86_64-unknown-freebsd || exit 1
    rustup toolchain install nightly-x86_64-unknown-freebsd || exit 1
    touch ${PREFIX}/.rustup
else
    echo "===> Skipping install rust toolchains"
fi

# Set linker
if [ ! -f ${PREFIX}/.linker ]
then
    echo "===> Setting Cargo linker"
    cd ${PREFIX}
    mkdir -p .cargo || exit 1
    cat <<EOF > .cargo/config
[target.x86_64-unknown-freebsd]
linker = "${TOOLCHAIN}/bin/x86_64-unknown-freebsd${REMOTEVERSION}-gcc"
EOF
    touch ${PREFIX}/.linker
else
    echo "===> Skipping set Cargo linker"
fi

# Create and build hello world crate
cd ${PREFIX}
if [ ! -f ${PREFIX}/.helloworld ]
then
    echo "===> Building rust hello world crate"
    rm -fr helloworld > /dev/null
    cargo new --bin helloworld || exit 1
    cd helloworld
    rustup override set nightly || exit 1
    cargo build --target x86_64-unknown-freebsd || exit 1
    file target/x86_64-unknown-freebsd/debug/helloworld | grep -q FreeBSD && Echo "Successfully cross compiled FreeBSD binary" || (echo "Something is wrong the the compiled rust binary" && exit 1)
    touch ${PREFIX}/.helloworld
else
    echo "===> Skipping build rust hello world crate"
fi


echo "===> Unmounting sysroot"
umount ${SYSROOT}

#
# Run on remote machine
#
echo "===> Copy binary to remote machine"
scp -P ${REMOTEPORT} ${PREFIX}/helloworld/target/x86_64-unknown-freebsd/debug/helloworld ${REMOTEUSER}@${REMOTEIP}:/tmp/helloworld  > /dev/null || exit 1

echo "===> Executing binary on remote FreeBSD machine. Expected output is \"Hello, world!\", actual output is: "
ssh -p ${REMOTEPORT} ${REMOTEUSER}@${REMOTEIP} /tmp/helloworld
