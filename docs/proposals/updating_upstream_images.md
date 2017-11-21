Updating upstream image tags for supported branches
---------------------------------------------------
Our logging team received a few issue and bug reports for a stable upstream 
branch, where the proper code was already merged in github, but propagating
the code to upstream images was out of sync with openshift ansible releases.

Upstream image tags
-------------------
For upstream images, we have the `latest` image tag and then image tag based
on the `git tag` (for example `v3.6.1`). The `latest` is frequently updated
when we merge a PR to the `master` branch, the `v3.6.1` tag is created once and
does not get updated. For downstream images, we also have updating tags based
on `git branch` (for example branch `rhaos-3.6-rhel-7` to image tag `v3.6`) 
and these get updated by our release engineers.

I would like to propose similar updating tags for the upstream images based on 
the `git branch`.

Proposal
--------
We would like to keep the original workflow for `master` and `git tag` for
upstream image tags and add a separate workflow for when we merge a PR to
any release branch. The latest updates in our supported branches will be
tracked by floating image tags. These tags will get updated each time a PR
is merged to a certain branch, for example if we merge a PR to `release-3.6`
the image tag `v3.6` will also get updated and point to the latest image build.

This will work together with our current workflow. If we merge a PR to `master`,
we will still update the `latest` image tag. If we merge a PR to `v3.6` and
tag the commit `v3.6.1`, we will still get a new image tag `v3.6.1` and at
the same time, update the `v3.6` tag.

Mapping from git to the image tag:
```
git pointer            || image tag
-----------------------||---------------------
branch  | master       || floating  | latest
branch  | release-X.Y  || floating  | vX.Y         <--- proposed new image tag
tag     | vX.Y.Z       || fixed     | vX.Y.Z 
```

Our [current CI job](https://ci.openshift.redhat.com/jenkins/job/build-and-release-latest-origin-aggregated-logging/)
may soon be deprecated in favor of [aos-cd-jobs](https://github.com/openshift/aos-cd-jobs/tree/master/sjb)
and future [new CI job](https://ci.openshift.redhat.com/jenkins/job/push_origin_aggregated_logging_release/)
which tries to implement above described workflow and is still work in progress.


What will this bring
--------------------
Recent issue with our images not getting updated soon enough:
- https://github.com/openshift/origin-aggregated-logging/issues/677
- https://github.com/openshift/openshift-ansible/issues/5497

Where we had to direct our users to use the `latest`. Some users felt 
uncomfortable using `latest` in production, some users wanted to use
an older version and didn't want to update yet. At that time, we had
images rebuilt in brew but upstream images were not rebuilt for another
two months.

Having more regularly updating tags for each branch would allow us
to fix an issue, backport it where necessary, and deliver to our users 
without having to wait a few months for a tagged release.
