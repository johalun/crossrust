#ifndef GCC_TM_H
#define GCC_TM_H
#ifndef LIBC_GLIBC
# define LIBC_GLIBC 1
#endif
#ifndef LIBC_UCLIBC
# define LIBC_UCLIBC 2
#endif
#ifndef LIBC_BIONIC
# define LIBC_BIONIC 3
#endif
#ifndef FBSD_MAJOR
# define FBSD_MAJOR 11
#endif
#ifdef IN_GCC
# include "options.h"
# include "insn-constants.h"
# include "config/vxworks-dummy.h"
# include "config/i386/biarch64.h"
# include "config/i386/i386.h"
# include "config/i386/unix.h"
# include "config/i386/att.h"
# include "config/dbxelf.h"
# include "config/elfos.h"
# include "config/freebsd-spec.h"
# include "config/freebsd.h"
# include "config/freebsd-stdint.h"
# include "config/i386/x86-64.h"
# include "config/i386/freebsd.h"
# include "config/i386/freebsd64.h"
# include "config/initfini-array.h"
#endif
#if defined IN_GCC && !defined GENERATOR_FILE && !defined USED_FOR_TARGET
# include "insn-flags.h"
#endif
#if defined IN_GCC && !defined GENERATOR_FILE
# include "insn-modes.h"
#endif
#if defined IN_GCC && defined GENERATOR_FILE && !defined BITS_PER_UNIT
#include "machmode.h"
#endif
# include "defaults.h"
#endif /* GCC_TM_H */
