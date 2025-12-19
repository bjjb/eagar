# eagar

A crystal library to help load configuration files.

The Eagar module contains functions to locate configuration files in JSON, YAML
or INI format, to sort them according to priority, to parse their contents and
ultimately to return hash of hashes of key-value pairs which can be used as the
basis for a configuration.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     eagar:
       github: bjjb/eagar
   ```

2. Run `shards install`

## Usage

```crystal
require "eagar"
File.open(".foo.ini", "w", &.puts(%(bar = baz)))
Eagar.configuration("foo")[""]["bar"] #=> "baz"
```

## Development

```
git clone https://github.com/bjjb/eagar
cd eagar
# ... make your changes
crystal spec
```

- [bjjb](https://github.com/bjjb) - creator and maintainer
