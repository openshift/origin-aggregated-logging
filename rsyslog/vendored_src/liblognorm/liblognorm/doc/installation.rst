How to install
==============

Here you can find the first steps to install and try liblognorm.

Getting liblognorm
------------------

There are several ways to install libognorm. You can install it
from your distribution, if it is there. You can get binary packages from
Rsyslog repositories:

- `RedHat Enterprise Linux or CentOS <http://www.rsyslog.com/rhelcentos-rpms/>`_
- `Ubuntu <http://www.rsyslog.com/ubuntu-repository/>`_
- `Debian <http://www.rsyslog.com/debian-repository/>`_

Or you can build your own binaries from sources. You can fetch all 
sources from git (below you can find all commands you need) or you can 
download it as tarballs at: 

- `libestr <http://libestr.adiscon.com/download/>`_
- `liblognorm <http://www.liblognorm.com/download/>`_

Please note if you compile it from tarballs then you have to do the same 
steps which are mentioned below, apart from::

    $ git clone ...
    $ autoreconf -vfi

Building from git
-----------------

To build liblognorm from sources, you need to have 
`json-c <https://github.com/json-c/json-c/wiki>`_ installed.

Open a terminal and switch to the folder where you want to build 
liblognorm. Below you will find the necessary commands. First, build
and install prerequisite library called **libestr**::

    $ git clone git://git.adiscon.com/git/libestr.git
    $ cd libestr
    $ autoreconf -vfi
    $ ./configure
    $ make
    $ sudo make install

leave that folder and repeat this step again for liblognorm::

    $ cd ..
    $ git clone git://git.adiscon.com/git/liblognorm.git
    $ cd liblognorm
    $ autoreconf -vfi
    $ ./configure
    $ make
    $ sudo make install

That’s all you have to do.

Testing
-------

For a first test we need two further things, a test log and the rulebase. 
Both can be downloaded `here 
<http://blog.gerhards.net/2010/11/log-normalization-first-results.html>`_.

After downloading these examples you can use liblognorm. Go to 
liblognorm/src and use the command below::

    $ ./lognormalize -r messages.sampdb -o json <messages.log

where::
    
    -r = path to the rulebase
    -o = output format

Please have look at :doc:`lognormalizer` for all available options.
