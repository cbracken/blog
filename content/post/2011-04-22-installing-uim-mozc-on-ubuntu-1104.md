---
comments: true
date: "2011-04-22T00:00:00Z"
tags:
- Howto
- Japanese
- Linux
- Software
title: Installing uim-mozc on Ubuntu 11.04 (Natty Narwhal)
---

If you're like me, one of the first things you do when you install a fresh
Linux distribution is to install a decent [Japanese IME][wiki_ime]. Ubuntu
defaults to [ibus-anthy][anthy], but I personally prefer [uim-mozc][mozc], and
that's what I'm going to show you how to install here.<!--more-->

*Update (2011-05-01):* Found an older [video tutorial][yt_tutorial] on YouTube
which provides an alternative (and potentially more comprehensive) solution for
Japanese support on 10.10 using ibus instead of uim, which is the better choice
for newer releases.

### Japanese Input Basics

Before we get going, let's understand a bit about how Japanese input works on
computers. Japanese comprises three main character sets: the two phonetic
character sets, hiragana and katakana at 50 characters each, plus many
thousands of Kanji, each with multiple readings. Clearly a full keyboard is
impractical, so a mapping is required.

Input happens in two steps. First, you input the text phonetically, then you
convert it to a mix of kanji and kana.

{{< figure src="/post/2011-04-22-henkan.png"
    alt="Japanese IME completion menu" >}}

Over the years, two main mechanisms evolved to input kana. The first was common
on old *wapuro*, and assigns a kana to each key on the keyboard—e.g. where
the *A* key appears on a QWERTY keyboard, you'll find a ち. This is how our
grandparents hacked out articles for the local *shinbun*, but I suspect only a
few die-hard traditionalists still do this. The second and more common method
is literal [transliteration of roman characters into kana][wiki_wapuro]. You
type *fujisan* and out comes ふじさん.

Once the phonetic kana have been input, you execute a conversion step wherein
the input is transformed into the appropriate mix of kanji and kana. Given the
large number of homonyms in Japanese, this step often involves disambiguating
your input by selecting the intended kanji. For example, the *mita* in *eiga wo
mita* (I watched a movie) is properly rendered as 観た whereas the *mita* in
*kuruma wo mita* (I saw a car) should be 見た, and in neither case is it *mita*
as in the place name *Mita-bashi* (Mita bridge) which is written 三田.


### Some Implementation Details

Let's look at implementation. There are two main components used in inputting
Japanese text:

The GUI system (e.g. ibus, uim) is responsible for:

1. Maintaining and switching the current input mode:
   ローマ字、ひらがな、カタカナ、半額カタカナ.
1. Transliteration of character input into kana: *ku* into く,
   *nekko* into ねっこ, *xtu* into っ.
1. Managing the text under edit (the underlined stuff) and the
   drop-down list of transliterations.
1. Ancillary functions such as supplying a GUI for custom dictionary
   management, kanji lookup by radical, etc.

The transliteration engine (e.g. anthy, mozc) is responsible for transforming a
piece of input text, usually in kana form, into kanji: for example みる into
one of: 見る、観る、診る、視る. This involves:

1. Breaking the input phrase into components.
1. Transforming each component into the appropriate best guess based on context
   and historical input.
1. Supplying alternative transformations in case the best guess was incorrect.


### Why uim-mozc?

Because it's there. And because it's better. Have a look at the conversion list
up at the top of this post. The input is *kinou*, for which there are two main
conversion candidates: 機能 (feature) and 昨日 (yesterday). Notice however,
that it also supplies several conversions for yesterday's date in various
formats, including 「平成23年4月21日」 using [Japanese Era Name][wiki_jp_era]
rather than the Western notation 2011. This is just one small improvement among
dozens of clever tricks it performs. If you're thinking this bears an uncanny
resemblance to tricks that [Google's Japanese IME][google_ime] supports, you're
right: mozc originated from the same codebase.


### Switching to uim-mozc

So let's assume you're now convinced to abandon your ibus-anthy and
switch to uim-mozc. You'll need to make some changes. Here are the
steps:

If you haven't yet done so, install some Japanese fonts from either Software
Centre of Synaptic. I'd recommend grabbing the *ttf-takao* package.

Search for and install the *uim* and *uim-mozc* packages.

Under the *Personal* section of the System Settings, select *Input
Method*. A dialog will open. Under Global Settings, make the following
changes:

1. Ensure *Specify default IM* is checked.
1. Set *Default input method* to 'Mozc'.
1. Set *Enabled input methods* to 'Mozc' using the *Edit...* button if
   necessary.
1. Ensure *Enable IM switching by hotkey* is checked.
1. Ensure *Skip direct method for IM switch* is checked.
1. Set *Preedit color* to 'uim'.
1. Set *Candidate window position* to your preference. Generally
   'Adjacent to cursor'.
1. If you set *Show input mode nearby cursor*, a small popup will
   briefly appear whenever you reposition your cursor, indicating input
   mode: '-' for romaji or a あ for hiragana.

{{< figure src="/post/2011-04-22-input_method_config.png"
    alt="UIM configuration dialog box" >}}

Under the Toolbar group, make the following changes:

1. Ensure *Enable menu-based input method switcher* is checked.
1. Set *Effective coverage* to *whole desktop*.
1. Ensure *preference tool* is checked.

Click *OK* to save and close the dialog.

In Software Centre, search for and uninstall any *ibus* related
packages.

Log out, and back in. You should see an input method menu in the menu
bar at the top of the screen.

[anthy]: https://sourceforge.jp/projects/anthy/news/
[google_ime]: https://www.google.com/intl/ja/ime/
[mozc]: https://code.google.com/p/mozc/
[wiki_ime]: https://en.wikipedia.org/wiki/Japanese_IME
[wiki_jp_era]: https://en.wikipedia.org/wiki/Japanese_era_name
[wiki_wapuro]: https://en.wikipedia.org/wiki/Wapuro
[yt_tutorial]: https://www.youtube.com/watch?v=MfgjTCXZ2-s
