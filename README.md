# Package indexer for ReaPack-based repositories

Parent project: [https://github.com/cfillion/reapack](https://github.com/cfillion/reapack)

[![Gem Version](https://badge.fury.io/rb/reapack-index.svg)](http://badge.fury.io/rb/reapack-index)
[![Build Status](https://travis-ci.org/cfillion/reapack-index.svg?branch=master)](https://travis-ci.org/cfillion/reapack-index)
[![Dependency Status](https://gemnasium.com/cfillion/reapack-index.svg)](https://gemnasium.com/cfillion/reapack-index)
[![Coverage Status](https://coveralls.io/repos/cfillion/reapack-index/badge.svg?branch=master&service=github)](https://coveralls.io/github/cfillion/reapack-index?branch=master)

### Installation

Ruby 2 need to be installed on your computer and ready to be used.
Install the dependencies with these commands:

```
cd path-to-this-repository
gem install bundler
bundle install
```

### Usage

```
bundle exec bin/reascript-indexer [options] [path-to-your-reascript-repository]
```

```
Options:
    -a, --[no-]amend                 Reindex existing versions
    -o, --output FILE=./index.xml    Set the output filename and path for the index
    -l, --link LINK                  Add or remove a website link
        --donation-link LINK         Add or remove a donation link
        --ls-links                   Display the link list then exit
    -A, --about=FILE                 Set the about content from a file
        --remove-about               Remove the about content from the index
        --dump-about                 Dump the raw about content in RTF and exit
        --[no-]progress              Enable or disable progress information
    -V, --[no-]verbose               Activate diagnosis messages
    -c, --[no-]commit                Select whether to commit the modified index
        --prompt-commit              Ask at runtime whether to commit the index
    -W, --warnings                   Enable warnings
    -w, --no-warnings                Turn off warnings
    -q, --[no-]quiet                 Disable almost all output
        --no-config                  Bypass the configuration files
    -v, --version                    Display version information
    -h, --help                       Prints this help
```

### Configuration

Options can be specified from the command line or stored in configuration files.
The syntax is the same as the command line, but with a single option per line.

The settings are applied in the following order:

- ~/.reapack-index.conf (`~` = home directory)
- ./.reapack-index.conf (`.` = repository root)
- command line

## Packaging Documentation

This indexer uses metadata found at the start of the files to generate the
database in ReaPack format.
See also [MetaHeader](https://github.com/cfillion/metaheader)'s documentation.

Tag not explicitly marked as required are optional.

### Package Tags

These tags affects an entire package. Changes to any of those tags are
applied immediately and may affect released versions.

**@noindex**

Disable indexing for this file. Set this on included files that
should not be distributed alone.

```
@noindex

NoIndex: true
```

**@version** [required]

The current package version.
Value must contain between one and four groups of digits.

```
@version 1.0
@version 1.2pre3

Version: 0.2015.12.25
```

### Version Tags

These tags are specific to a single package version. You may still edit them
after a release by running the indexer with the `--amend` option.

**@author**

```
@author cfillion

Author: Christian Fillion
```

**@changelog**

```
@changelog
  Documented the metadata syntax
  Added support for deleted scripts

Changelog:
  Added an alternate syntax for metadata tags
```

**@provides**

Add additional files to the package.
These files will be installed/updated together with the package.

```
@provides unicode.dat

Provides:
  Images/background.png
  Images/fader_small.png
  Images/fader_big.png
```
