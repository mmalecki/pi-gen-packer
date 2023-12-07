# pi-gen-packer
Example Packer setup integrated with `pi-gen` for fully homebrew Raspberry Pi OS images.
[Read more the "why" and the "how" in this blog post.](https://blog.mmalecki.com/2022/11/16/pi-gen-and-packer.html)

## Usage
To build example images:

```sh
git clone https://github.com/mmalecki/pi-gen-packer.git
cd pi-gen-packer
git submodule update --init
make images
```
