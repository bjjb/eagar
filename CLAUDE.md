# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eagar is a Crystal library for loading configuration files from multiple sources and formats. It searches for configuration files in standard system, site, user, and XDG directories, then merges them into a unified configuration hash.

## Development Commands

- **Install dependencies**: `shards install`
- **Run tests**: `crystal spec`
- **Run specific test**: `crystal spec spec/eagar_spec.cr`
- **Format code**: `crystal tool format`

## Code Architecture

### Core Module (`src/eagar.cr`)
- **Main entry point**: `Eagar.configuration(name)` - loads and merges all configuration files for a given application name
- **File discovery**: `Eagar.files()` and `Eagar.globs()` - locate configuration files across multiple directories
- **Parsing**: `Eagar.parse()` - handles JSON, YAML, and INI formats
- **Type aliases**: `YAMLConfig` and `INIConfig` define expected configuration structures

### Search Hierarchy
Configuration files are searched in this order:
1. System directories (`/etc`)
2. Site directories (`/usr/local/etc`) 
3. User home directory (`~`)
4. XDG config directory (`~/.config`)
5. Current working directory (`.`)

### Supported Formats
- JSON (`.json`)
- YAML (`.yaml`) 
- INI/Config (`.ini`, `.conf`)

### Directory Structure
```
/
├── src/eagar.cr          # Main module implementation
├── spec/eagar_spec.cr    # Test suite
├── shard.yml            # Crystal project metadata
└── README.md            # Project documentation
```

## Key Implementation Details

- Configuration files are merged with later files taking precedence
- INI files are parsed as section-based configs, others as flat key-value pairs
- Files must be readable to be included in the final configuration
- The library searches for `<name>.*` files and `<name>/config.*` files in each directory