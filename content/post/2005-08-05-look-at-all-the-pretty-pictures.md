+++
title = "Look At All The Pretty Pictures!"
date = "2005-08-05T00:00:00Z"
slug = "look-at-all-the-pretty-pictures"
tags = ["Meta"]
+++

So I moved my webpage and was all of a sudden faced with a deluge of emails
from people who I never even knew read the thing. Among those emails was a
request from my amigo Chaffee requesting more pictures.<!--more--> Seeing as
I'd always wanted to play with the [Flickr API][flickr_api], I requested an API
Key and started hacking away at some [PHP][php]. The end result is that on the
left side of this page, you now get to see whatever happens to be the latest
picture I've taken on my mobile phone.

The moment I take a picture with my cellphone, it gets emailed to the magical
servers at [Flickr][flickr] and tagged with a title, some keywords, and a
description. The next time someone loads this page, a small PHP script in the
innards of this site makes a [SOAP][soap] request to Flickr's servers and
retrieves an [XML][xml] response. This response is then parsed out and a URI to
the thumbnail image on Flickr's servers is generated which is then inserted
into this page. To improve performance a tiny bit, I avoid the overhead of the
SOAP call every time this page is loaded by caching the response for five
minutes and reading the cached XML if it's available.

For those of you who are into [RSS][rss], I've added a [Flickr
feed][flickr_feed] to my pictures in the HTML headers on this site.

My goal—and this is entirely for you, Chaffee—is to take at least one
picture a day, which is far more ambitious a schedule than my posting to this
page. We'll see how that works out.

[flickr]: https://flickr.com
[flickr_api]: https://flickr.com/services/
[flickr_feed]: feed://flickr.com/services/feeds/photos_public.gne?id=37996625178@N01&format=atom_03
[php]: https://php.net
[rss]: https://www.xml.com/pub/a/2002/12/18/dive-into-xml.html
[soap]: https://www.w3.org/TR/soap/
[xml]: https://www.w3.org/XML/
