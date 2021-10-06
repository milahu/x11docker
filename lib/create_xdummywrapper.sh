create_xdummywrapper() {        # options --xdummy, --xpra: create startscript for Xdummy
  echo '#!/bin/sh
# fork of https://xpra.org/trac/browser/xpra/trunk/src/scripts/xpra_Xdummy
find_ld_linux() {
	arch="$(uname -m)"

	if [ $arch = "x86_64" ]; then
		LD_LINUX="/lib64/ld-linux-x86-64.so.2"
	elif [ $arch = "i386" ]; then
		LD_LINUX="/lib/ld-linux.so.2"
	elif [ $arch = "i486" ]; then
		LD_LINUX="/lib/ld-linux.so.2"
	elif [ $arch = "i586" ]; then
		LD_LINUX="/lib/ld-linux.so.2"
	elif [ $arch = "i686" ]; then
		LD_LINUX="/lib/ld-linux.so.2"
	elif [ $arch = "armel" ]; then
		LD_LINUX="/lib/ld-linux.so.3"
	elif [ $arch = "armhfp" ]; then
		LD_LINUX="/lib/ld-linux.so.3"
	elif [ $arch = "armhf" ]; then
		LD_LINUX="/lib/ld-linux-armhf.so.3"
	elif [ $arch = "ppc64" ]; then
		LD_LINUX="/lib64/ld64.so.1"
	elif [ $arch = "s390x" ]; then
		LD_LINUX="/lib64/ld64.so.1"
	else
		#suitable for: powerpc/ppc, mips/mipsel, s390 and others:
		LD_LINUX="/lib/ld.so.1"
	fi

	if [ ! -x "$LD_LINUX" ]; then
		# Musl C / Alpine Linux
		ldmusl="$(ls /lib | grep ^ld-musl)"
		if [ -n "$ldmusl" ]; then
			LD_LINUX="/lib/$ldmusl"
		else
			LD_LINUX=""
			echo "could not determine ld path for $arch, please file an xpra bug"
		fi
	fi
}