# Pinned upstream metadata for the vendored BakaSU driver.
#
# Source: https://github.com/Baka-SU/BakaSU
# Tag:    v4.2.0-rc3
# Commit: 239e1e8871b8fcd51a6e5b3002e0ba522fdd99fb
#
# KSU_VERSION is the value upstream's Kbuild computes for that commit:
#
#     30000 + $(git rev-list --count HEAD) + 700
#   = 30000 + 4471 + 700
#   = 35171
#
# The manager release this pairs with is named
# ReSukiSU_v4.2.0-rc3_35171-<abi>-release.apk for the same reason, and the
# manager reports the kernel's version code from this value.
#
# Bump all five values together when the vendored driver is updated, or the
# version the manager displays will not match the driver it is talking to.

KSU_LOCAL_VERSION := 4471
KSU_VERSION       := 35171
KSU_TAG_NAME      := v4.2.0-rc3
KSU_COMMIT_SHA    := 239e1e88
KSU_BRANCH_NAME   := v4.2.0-rc3
