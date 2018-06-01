---
comments: true
date: "2011-10-25T00:00:00Z"
tags:
- Howto
- Japanese
- Linux
- Software
title: Installing ibus-mozc on Ubuntu 11.10 (Oneiric Ocelot)
---

After doing a clean install of Oneiric on my machine, first thing I did was
install mozc as my input method. Turns out this is much simpler than under
Natty.<!--more-->

The process goes something like this:

1. **Install ibus-mozc:**
    ```shell
    sudo apt-get install ibus-mozc
    ```
1. **Restart the ibus daemon:**
   ```shell
   /usr/bin/ibus-daemon --xim -r
   ```
1. **Set your input method to mozc:**
   1. Open *Keyboard Input Methods* settings.
   1. Select the *Input Method* tab.
   1. From the *Select an input method* drop-down, select Japanese, then mozc from
      the sub-menu.
   1. Select *Japanese - Anthy* from the list, if it appears there, and click
      *Remove*.
1. **Optionally, remove Anthy from your system:**
   ```shell
   sudo apt-get autoremove anthy
   ```

That's it, Mozcを楽しんでください！
