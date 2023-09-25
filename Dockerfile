# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

RUN apt-get update -y 
RUN apt-get install -y ccache
RUN apt-get install -y cmake
RUN apt-get install -y pkg-config
RUN apt-get install -y build-essential
RUN apt-get install -y git 
RUN apt-get install -y python3
RUN apt-get install -y curl
RUN apt-get install -y wget

RUN ccache --version 
# ccache version 4.6.3

# Clone the depot_tools repository and add it to the PATH
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH="/usr/local/depot_tools:$PATH"

# Optionally, add this to your ~/.bashrc if you want to persist the PATH
# RUN echo 'export PATH="/usr/local/depot_tools:$PATH"' >> ~/.bashrc

# Create a directory for v8 and set it as the working directory
WORKDIR /usr/local/lib/v8

# Fetch the v8 source code using gclient
RUN gclient
RUN fetch v8

# Change to the v8 directory
WORKDIR /usr/local/lib/v8/v8

# Check out a specific version of v8
RUN git checkout 4ec5bb4f26

# List available build configurations
RUN tools/dev/v8gen.py list

# Generate the build configuration for x64 release
RUN tools/dev/v8gen.py x64.release.sample

# Modify the build configuration to use ccache
RUN echo 'cc_wrapper="ccache"' >> out.gn/x64.release.sample/args.gn 
RUN sed -i '/v8_enable_sandbox/d' out.gn/x64.release.sample/args.gn

# Set environment variables for ccache
ENV CCACHE_CPP2 yes
ENV CCACHE_SLOPPINESS time_macros

# Optionally, add these environment variables to ~/.zshrc or ~/.bashrc
# RUN echo "export CCACHE_CPP2=yes" >> ~/.zshrc
# RUN echo "export CCACHE_SLOPPINESS=time_macros" >> ~/.zshrc

# Build v8_monolith
RUN /bin/bash -c 'time ninja -C out.gn/x64.release.sample v8_monolith'
# Copy the built files to a destination directory
RUN cp out.gn/x64.release.sample/obj/libv8_monolith.a ../../../v8/
RUN cp out.gn/x64.release.sample/icudtl.dat ../../../v8/
RUN cp -r include ../../../v8/

# Clean up the v8 and depot_tools directories if needed
# RUN cd ../../
# RUN rm -rf v8
# RUN rm -rf /usr/local/depot_tools

# Set the working directory to /usr/local/lib/v8
WORKDIR /usr/local/lib/v8
