#!/bin/bash
failed="0"
for d in $(ls $WORKDIR) ; do
    pushd ${WORKDIR}/${d}
        bundle exec rake test
	    if [ "$?" != "0" ] ; then
              failed="1"
	    fi
    popd
done
exit $failed
