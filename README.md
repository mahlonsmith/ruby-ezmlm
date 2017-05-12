# Ruby-Ezmlm

code
: https://bitbucket.org/mahlon/Ruby-Ezmlm


## Authors

* Mahlon E. Smith <mahlon@martini.nu>
* Michael Granger <ged@faeriemud.org>
* Jeremiah Jordan <jeremiah.m.jordan@gmail.com>


## Description

This is a ruby interface for interacting with ezmlm-idx, an email list
manager for use with the Qmail MTA, and the messages contained therein.
(The -idx provides an extended feature set over the original ezmlm
environment.)

http://untroubled.org/ezmlm/

This was tested against ezmlm-idx 7.2.2.

*Strong recommendation*: Create your lists with archiving (-a) and
indexing (-i)!   This library is suitable for modifying behavior of
existing lists as a default, but with these flags enabled, can also
be a generic interface for parsing and browsing list content.


## Prerequisites

* Ruby 2.1 or better


## Installation

    $ gem install ezmlm

## Usage

	....


## TODO

  - Text file editing (trailers, etc.)
  - Header / mime list accessors


## Limitations

This library doesn't create new lists from scratch.  Use ezmlm-make.

This library is designed to only work with lists stored on disk (the
default), not the SQL backends.

Address space (32 bit vs 64 bit) matters when ezmlm calculates hashes.
If things aren't adding up, make sure this library is running on a
machine with a matching address space as the list itself.  (Running this
on a 64bit machine to talk to 32bit listserv isn't going to play well.)

A lot of the fine tuning niceties of ezmlm come as flag options to
the various ezmlm binaries.  This library largely just deals with
ezmlm-make flags for global list behaviors.  (For example, see the man
page for ezmlm-reject.)  Patches are welcome if you'd like these sorts
of miscellaneous things included.


## Acknowledgments

Portions of this library are copied from ezmlm-idx source, authored by
the following:

 * D. J. Bernstein <djb@cr.yp.to>
 * Bruce Guenter <bruce@untroubled.org>

Many thanks for Dan and Bruce for their commitment for fine software, and
contributions to the internet communities over the years.


## License

Copyright (c) 2017, Mahlon E. Smith <mahlon@martini.nu>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  * Neither the name of the author/s, nor the names of the project's
    contributors may be used to endorse or promote products derived from this
    software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
