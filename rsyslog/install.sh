#!/bin/bash
# /bin/install.sh for atomic rsyslog image

prefix=${HOST:-/host}

function install_dir ()
{
    source="$1"
    dest=$prefix/"$1"

    if [ ! -e "$source" ] ; then
	echo Error, source directory "$source" not found 1>&2
	return 1
    fi

    if [ -d "$dest" ] ; then
	return 0;
    fi

    echo Creating directory at "$dest" 1>&2
    mkdir -p "$dest" || return $?
    chmod --reference="$source" "$dest" || return $?
    chown --reference="$source" "$dest"
    return $?
}

function install_file ()
{
    source="$1"
    dest=$prefix/"$1"

    if [ ! -e "$source" ] ; then
	echo Error, source file "$source" not found 1>&2
	return 1
    fi

    if [ -e "$dest" ] ; then
	if [ -d "$dest" ] ; then
	    # Work around a docker behaviour:
	    #
	    # if we try to bind mount a single config file from the host
	    # to the container, and the file does not exist, then docker
	    # will create it...  as a directory.
	    #
	    # This can happen if we "atomic run" the image before "atomic
	    # install", so detect that and fix it up here.
	    rmdir --ignore-fail-on-non-empty "$dest" || return 1
	    if [ -d "$dest" ] ; then
		echo Failed to install file at "$dest", directory in the way 1>&2
		return 1
	    fi
	    echo Installing file at "$dest" in place of existing empty directory 1>&2

	else

	    cmp --silent "$source" "$dest" && return 0
	    # Attempting to install over an existing file with new contents?
	    # Copy to a predictable alternative instead, similar to ".rpmnew"
	    echo Installing over file "$dest", new file placed in "$dest".atomicnew 1>&2
	    cp -af "$source" "$dest".atomicnew || return 1
	    return 0;
	fi
    fi

    echo Installing file at "$dest" 1>&2
    cp -a "$source" "$dest" || return $?
    return $?
}

install_dir /etc/pki
install_dir /etc/pki/rsyslog
install_dir /etc/rsyslog.d

install_file /etc/rsyslog.conf
install_file /etc/sysconfig/rsyslog
install_file /etc/logrotate.d/syslog

chcon -t etc_t "$prefix"/etc/logrotate.d/syslog

# rsyslog's logrotate script expects all its log files to exist
# already, even if they are only empty and not actively in use.
#
# So prepopulate the log files in the same way as the rpm .spec file's
# %post section.

for n in "$prefix"/var/log/{messages,secure,maillog,spooler}
do
        [ -f $n ] && continue
        umask 066 && touch $n
done
