# Personal patches

This directory contains patches which are applied to original `st` source code.

Rough steps to produce this setup:

- Download new vanilla `st` source code.
- Apply all number-prefixed patches in order with `patch -p1 < ***` (like `patch -p1 < patches/01_st-scrollback-0.8.5.diff`).
  IMPORTANT: look for success/fail hunk messages after each patch. There will be failed ones, which you need to apply manually. Rough steps:
    - Open 'xxx.rej' file. It contains part that was not applied (but still needs to be).
    - Locate place in 'xxx' file where rejected patch should be applied.
    - Imitate patch manually (remove `-` lines and add `+` lines, without those characters).
- Apply personal patch with `patch -p1 < patches/personal.diff`.
- Run `sudo make install`. It will install system-wide. NOTE: don't install for user because other programs might not work with it (like `i3-sensible-terminal`).

In order to update and commit some personal settings, try to not only update the code ('config.h', etc.) itself but also a 'patches/personal.diff' (manually, at this point).

# Sources

- https://st.suckless.org/
