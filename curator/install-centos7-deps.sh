#!/bin/bash
if [ -f /etc/centos-release ] ; then
    echo "Installing temporarily centos 7 deps for CI"
    yum install -y python3
    yum clean all
    ln -sf /usr/bin/python3 /usr/bin/python
    ln -sf /usr/bin/pip3 /usr/bin/pip
fi
