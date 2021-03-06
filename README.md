# Overview #

A utility for converting web pages into ePub formatted eBooks.

## Installation

On macOS html2epub can be installed via homebrew with the following command:

```
brew install jwhitehorn/brew/html2epub
```

## Usage

A more in-depth overview of how to use html2epub can be found here:

- [Generating ePub Books From HTML](https://jason.whitehorn.us/blog/2018/08/05/generating-epub-books-from-html/)

For the quick-start version, simply invoke the command with references to the table of contents, cover image, and contents.json (see the example directory for examples of those files):

```
html2epub --url https://www.datasyncbook.com \
    --toc ./example/toc.xhtml \
    --cover ./example/cover.png \
    --contents ./example/contents.json \
    --title "Data Synchronization" \
    --subtitle "Patterns, Tools, & Techniques" \
    --author "Jason Whitehorn"
```


## License ##

Copyright (c) 2018, [Jason Whitehorn](https://jason.whitehorn.us)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
