# chris.bracken.jp

If you were looking for my actual blog, you'd find it at [chris.bracken.jp][blog],
but if you're here, odds are you're looking for the source. You've come to the
right place.

## Prerequisites

To build, you'll need [hugo][hugo_install] installed on your system.

## Obtaining the source

First, clone the repo:

    git clone git://git.bracken.jp/blog.git

Next, initialise and fetch git submodules:

    git submodule update --init

## Starting the dev server

Fire up hugo's dev server:

    # For the production site:
    hugo server
    
    # To run with draft posts enabled:
    hugo server -D

Follow the on-screen instructions to test the site out locally.

## Adding a new post

To create a new post:

    hugo new post/yyyy-mm-dd-title-of-post.md

Edit `content/post/yyyy-mm-dd-title-of-post.md` in your favourite editor. When
it's ready to post, remove the `draft` tag from the post header, commit the
changes, and push.

## Building and deploying the site

To build and deploy the site, run:

    ./publish.sh

[blog]: https://chris.bracken.jp
[hugo_install]: https://gohugo.io/getting-started/installing/
