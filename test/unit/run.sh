#!/bin/bash
failed="0"
for d in $(ls $WORKDIR) ; do
    pushd ${WORKDIR}/${d}
        export GEM_HOME=vendor
        scl enable rh-ruby25 -- bundle exec rake test
	    if [ "$?" != "0" ] ; then
              failed="1"
	    fi
    popd
done
exit $failed
