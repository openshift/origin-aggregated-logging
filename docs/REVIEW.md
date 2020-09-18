# OpenShift Logging - PR Review Guidelines

# Motivation

The general motivation for reviewing pull requests in our team is to ultimately ensure a frictionless review process that in turn addresses our quality and velocity goals. In particular all parties involved agree mutually that:

* The review process is a place of collaboration based on the [Prime Directive](https://retrospectivewiki.org/index.php?title=The_Prime_Directive).
* The review process is a place to meet our mutually shared quality goals together.
* The review process is a place to ensure a high velocity development cycle.

The following guidelines are structured across the three roles involved in general pull request based development work. All three subjects have a considerable take on improving a development artifact and are advised by the guidelines below to do so in a respectful manner and collaborative way.


# General advice

All three roles can consider the following advice:

1. Be kind
2. Explain the reasoning of your work, suggestion or direction
3. Your wording should be chosen wisely encouraging further communication and collaboration on the present PR and future work.
4. Speed in collaboration is a precious good but on the other side consider time zones and low notification noise
5. A PR should be a very focused place of work and not a place to resolve third-party conflicts. Escalate on later in a different medium (e.g. JIRA card, BZ, Slack)


# Author Guidelines

The author is the pilot on the road to land a PR. His/Her duty is to ensure that the PR addresses work planned and aligned with the product. To ensure a frictionless review experience for the other two subjects he/she must consider the following guidelines with respect to others capacity and capability to provide a good review:

1. Provide at **minimum**:
    1. A text description about the issue the PR is addressing that ensures the reader understands the context, the rationale behind and catches a 1000-feet perspective of the implementation.
    2. Link the BZ or the JIRA card or the enhancement doc after the description block, if one exists.
    3. Make sure to assign **ONE** approver and **ONE** reviewer. Introduce third-party people later if needed to ensure a low notification noise in the team.
    4. Use formatting to enhance readability: sections, code blocks, etc.
2. Mandatory additions:
    1. Enrich your PR with screenshots, code blocks.
    2. Link in your PR descriptions according to the PR template:
        1. Depending on PRs, e.g. “_Depends on: openshift/release#123”_
        2. Documents, e.g. _“Ref: Google doc UBI8 migration”_
    3. Use the cherry-pick bot command to declare backports, e.g _/cherry-pick release-4.5_
3. Communication stays on a PR and is **not** copied back/forth to Slack/IRC/etc. as much as is reasonable. Even on offline discussions on Slack/IRC/etc. ensure that the outcome lands back on the PR.
4. Use **@name** handles on a PR with great care:
    1. Only on PR creation to assign an approver and a reviewer (/cc name1 /assign name2)
    2. Tag people to bring in additional members for discussion (without /cc or /assign)


# Approver Guidelines

The approver is the cornerstone of a PR’s adherence to product and architecture directions, however his/her role is limited to that of the on-board flight computer. The corrections can be suggested to the other two subjects if any wrong turn is taken. However and most likely in most situations his/her role is limited to take a 100-feet view on the PR and apply the labels to ensure the other two can finish the work relatively quickly. In order to achieve few or even zero bottleneck situations and in turn a fast development face, he/she must consider the following guidelines:

1. Provide an **approved** label earliest possible to enable the author and the reviewer finish up the work.
2. **Approved** label should be given when:
    1. The PR’s general direction is aligned with the product direction
    2. The PR is changing architecture standpoints aligned with the team and/or enhancement document.
    3. The PR is vetted not breaking any product features and/or making future goals hard to achieve w/o justification.
3. General advice:
    1. The approver can but must not always be a full-scan reviewer.
    2. The approver should apply the label if the PR is a WIP and is not breaking any of the above. Ensures a higher velocity e.g. BZs.
    3. The approver ensures a relatively fast pace in moving a PR forward by jumping on the train at the earliest possible time.
    4. The approver collaboration on a PR can be a single hop-on/hop-off interaction (e.g. on PR opening) and leave the pilots (author, reviewer) finish the PR. The pilots can ensure further interaction by using the @handle notification with great care.


# Reviewer Guidelines

The reviewer is the co-pilot on the road to land a PR. He/she is the author’s selected candidate to collaborate with on a PR's quality and goal achievement. The role entails more bandwidth in communication with the author and is critical for achieving a fast pace. On the other hand the role has the responsibility to provide assistance and suggest changes that drive the PR to accomplishment. To achieve the aforementioned goals, the reviewer must consider the following guidelines:

1. Provide a thorough first-scan review upon assignment by the author on the earliest possible time. General rule of thumb should be: \
**No more than two business days to respond!**
2. When reviewing a PR:
    1. Remember the rule of thumb and choose your wording wisely:  \
**Be constructive with what you are suggesting and provide a why!**
    1. Classify suggestions into:
        1. **Must-Haves**: e.g. the PR breaks functionality or APIs, misses tests, does not implement the issue correctly or completely.
        2. **Recommended improvements:** e.g. split big functions, flesh out in separate PRs, etc.
        3. **Nits**: etc. code style aesthetics beyond mandatory formatting.
    2. Do not duplicate the same suggestions if applicable in other places. Ensure a reference to allow communication in a single thread.
    3. Resolve threads if the suggested change is implemented or a good-enough answer is provided.
    4. Apply the LGTM label if the PR resolved all issues and the tests are passing but do not insist on nits.
3. When pushing back on a PR:
    1. Explain the “why” a particular change is not a merge candidate.
    2. Provide advice and references to improve the PR if possible.
    3. Ensure that the other side can follow-up at a later moment or with a different approach.

_As a reviewer make it happen to be chosen again as a reviewer!_


# Github notification tips

[https://github.com/notifications](https://github.com/notifications) is a **much** better way to manage your review responsibilities than e-mail or the raw PR list. It shows just those PRs that require your attention, with a reason why. The basic workflow:

* Go though the notifications, using the filters (unread, review requested etc.) to focus on the most important things first.
* As you review the PR, tick the "viewed" check box for each file you have read.
* Mark the PR or notification "done" when you are done _for now_. It will vanish from your "todo' list.
* If the PR changes it will re-appear, showing the number of comments since you last marked it "done".
  * Jumping to the PR from the notification will open it where you left off.
  * When you re-review, only files that have changed since you marked them "viewed" will be open.
* If you are sure a PR will never need your attention again you can "unsubscribe"

There's a FireFox/Chrome extension to give desktop notifications and a badge in the browser, some team members have found it useful:[ https://github.com/sindresorhus/notifier-for-github](https://github.com/sindresorhus/notifier-for-github)

This isn't intended to be a comprehensive guide, play around and check the github help for this and other github tools.
