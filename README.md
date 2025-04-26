# EBox (Work In Progress)

Embedded Box, containerized development environments for embedded and FPGA
designers

> ℹ️ This is a fresh project and currently includes only a limited number of
> tools, but it's actively under development—so stay tuned for more updates!

---

✅ [Docker](https://www.docker.com/) and [Podman](https://podman.io/) compatible

✅ Suitable for automated CI/CD run and interactive development environment (GUI)

✅ [MIT License](https://opensource.org/license/mit), feel free to use and
contribute ;)

---

## The Motivation

Containerizing software is a standard approach for creating standalone packages
where the correct dependencies are included to run the desired application. It
is a mature technology that has been developed over many years and is widely
used in production—both as a development and deployment environment—primarily
associated with Docker.

Tools used by embedded and FPGA developers are no exception. Many EDA tools
depend on a wide range of packages, and maintaining multiple versions on a
single workstation or Linux distribution can be challenging due to conflicting
dependencies. For example, each version of Xilinx's PetaLinux tool may require a
different version of Ubuntu and its corresponding `apt` packages. This makes it
difficult to install and use multiple versions of PetaLinux on the same
machine—some form of isolation or virtualization is needed.

Furthermore, installing the same tool on different machines can be problematic
due to minor configuration differences. Some tools require small system-specific
tweaks during installation, and if someone tries to install the same software on
a different machine—perhaps a year later—it’s easy to forget what was done
previously. As a result, **maintaining a reproducible development environment
becomes challenging**, especially when working on multiple projects and using a
variety of tools in different versions.

In recent years, **Continuous Integration and Delivery/Deployment (CI/CD)** has
become a popular concept in the embedded and FPGA world. In this model, code is
managed under a version control system like **Git**, and with each commit or
merge request, a set of predefined unit and integration tests are automatically
triggered. This allows developers to quickly see whether the proposed changes
introduce any test failures or if everything passes as expected.

Automation in CI/CD goes beyond testing—it can also be used to generate final
output artifacts, such as firmware or bitstreams, as part of Continuous Delivery
or Deployment. However, achieving this requires running project-specific tools
like cross-compilers or RTL synthesizers. One approach is to manually install
these tools on backend machines, much like setting up a local development
environment, and connect them to CI systems like **GitHub** or **GitLab**.

Unfortunately, this method suffers from the same reproducibility issues
mentioned earlier. Additionally, **scalability becomes a problem.** As project
demands grow, more backend machines may be required. Manually installing and
configuring tools on each new machine is not a scalable solution.

Containerizing the required software addresses both problems. With containerized
environments, it's much easier to **reproduce builds** and **scale the backend**
dynamically. Generic runners capable of executing any containerized application
can be added as needed, simplifying infrastructure management and improving
reliability.

**This is where the project EBox—short for Embedded Box or EDA Box, depending on
how you prefer to describe it—comes in. The goal of this project is to
demonstrate how various tools can be containerized and, where possible, to
provide ready-to-use containerized versions of those tools.**

I hope this project helps developers like myself streamline their workflows when
working with embedded and FPGA toolchains.

## Limitations

Although the EBox project aims to provide ready-to-use container images that
suit a wide range of developers and use cases, there are certain
limitations—both technical and legal—that need to be considered.

❗ Downloading Xilinx (now AMD) tools requires legal approval by the user, and as
such, it is not permitted to distribute containerized versions of these tools on
public platforms like Docker Hub. Instead, this repository provides the
necessary files and instructions to containerize the tools yourself—assuming you
have already obtained the official setup files from the vendor’s website. While
all supporting scripts and configurations are included in the repository, you
must manually download the setup files from the vendor to build the images.

❗ Some tools, such as Xilinx's Vivado, are extremely large—container images for
the latest versions can easily exceed 100 GB. Even if it were legally
permissible to distribute these images, hosting them in a private or public
manner would be technically challenging and potentially expensive due to their
size. Unfortunately, this limitation also applies to you: if you choose to build
these images yourself, you'll need sufficient storage infrastructure to host and
manage them.

❗ It's practically impossible to test every possible usage scenario for these
containers. While many have been tested with a variety of cases—for example,
MicroBlaze, Zynq, and ZynqMP projects using Xilinx Vivado—the test coverage is
still limited. As a result, you may encounter issues in certain use cases. If
you do, please don’t hesitate to open an issue.

❗ These container images are primarily intended for use on Linux hosts—that is,
systems where Docker or Podman runs natively on Linux. While they may also work
on other platforms, such as Docker Desktop on Windows or macOS, they have only
been tested on Linux. In particular, you may encounter issues when using GUI
applications on non-Linux systems.

## How?

Simply visit the directory for the corresponding tool. Each directory contains a
detailed README file with step-by-step instructions. If you have any questions
or encounter issues, feel free to open an issue or ask in the community tab.
You’re also welcome to contribute by creating pull requests.

## Todo

- Mock build and test (if possible)
- Docker linter
- Think about <https://github.com/mviereck/x11docker>

## Contributors

This work would not have been possible without the dedicated efforts and
valuable suggestions of all [AUTHORS](AUTHORS).

## License and Copyright

[MIT License](LICENSE), Copyright (c) 2025 The EBox [Authors](AUTHORS).
