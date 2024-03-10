# Personal tools collection

This repo is a collection of useful tools that are either performance-critical or have no convenient way to install from a package manager.

It works on Linux and macOS although not been thoroughly tested other than on Ubuntu.

All tools are installed under the root of the repository (except for some libraries that are installed to the system) by default.

## Supported tools

- [ffmpeg](https://ffmpeg.org/)
- [cosmocc](https://github.com/jart/cosmopolitan)
- [rav1e](https://github.com/xiph/rav1e) (Can be installed along with `ffmpeg`)
- [nasm](https://www.nasm.us/) (Also be installed along with `ffmpeg`)

## Special Files

### `setup.sh`

User configuration file.  
This file will be created in the root of the repository if it does not exist.
You can edit it to add or remove tools from the installation process.

### `scripts/install.sh`

It contains installation instructions for the tools in the repository.

### `scripts/env.sh` and `env/*sh`

`env/` will be created in the root of the repository.  
`env.sh` will source all the files in the `env` directory.
They configure the environment variables to include the tools in the repository. (e.g. `PATH`)

You may want to add the following line to your `.bashrc` or `.zshrc` file:

```sh
source /path/to/repo/scripts/env.sh
```
