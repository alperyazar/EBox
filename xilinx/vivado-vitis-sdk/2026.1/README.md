# Vivado, Vitis 2026.1

**❗ WIP (Work In Progress) ❗**

## Generating `install_config.txt`

The provided `Dockerfile-setup` is used to build a temporary container image for
generating `install_config.txt`.

To build this temporary image, run the following command:

```bash
sudo docker build --file Dockerfile-setup --tag vivado:2026.1-setup .
```
