# SUSFS provenance and compatibility

- Upstream project: https://gitlab.com/simonpunk/susfs4ksu
- Linux branch: `kernel-4.14`
- Official branch commit observed during integration: `77905b5a071e6f3669e3b1814cea30147c0801da`
- Imported source mirror: https://github.com/Star-Seven/susfs4ksu
- Mirror commit used for the imported 4.14 patch/source: `d18028f2a8f3ba16a907bff0edc16376cf38e2bf`
- Reported implementation version: `v1.5.5`

The generic Linux 4.14 changes were adapted manually to this Qualcomm vendor
kernel, and the userspace command ABI was bridged to the manually integrated
Backslashxx KernelSU tree. The old upstream KernelSU patch was not applied
wholesale because it targets a different KernelSU layout and API.

This implementation is older than the SUSFS v2.2.0-or-newer requirement stated
by BRENE. It must not be represented as BRENE-compatible.
