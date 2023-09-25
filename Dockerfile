FROM ubuntu:22.04

RUN sudo apt-get install -y ccache
RUN sudo apt-get install -y cmake
RUN sudo apt-get install -y pkg-config

RUN ccache --version 
# ccache version 4.6.3

RUN ccache g++ --version

RUN cmake --version
# cmake version 3.24.1

RUN pkg-config --version
# 0.29.2

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
RUN export PATH=`pwd`/depot_tools:$PATH

RUN echo "export PATH=`pwd`/depot_tools:\$PATH" >> ~/.bashrc

RUN cd depot_tools && git checkout 787e71ac && cd ..

# add patch
RUN mkdir -p lib/v8 && cd lib/v8
RUN gclient
RUN fetch v8

RUN cd v8
RUN git checkout 4ec5bb4f26

RUN tools/dev/v8gen.py list

RUN tools/dev/v8gen.py x64.release.sample

# echo 'v8_target_cpu = "arm64"' >> out.gn/x64.release.sample/args.gn 
RUN echo 'cc_wrapper="ccache"' >> out.gn/x64.release.sample/args.gn 
RUN sed -ie '/v8_enable_sandbox/d' out.gn/x64.release.sample/args.gn

RUN export CCACHE_CPP2=yes
RUN export CCACHE_SLOPPINESS=time_macros

# Optionally, add this to your ~/.zshrc if you are using zsh, or any
# other equivalents
RUN echo "export CCACHE_CPP2=yes" >> ~/.zshrc
RUN echo "export CCACHE_SLOPPINESS=time_macros" >> ~/.zshrc

RUN time ninja -C out.gn/x64.release.sample v8_monolith

RUN cp out.gn/x64.release.sample/obj/libv8_monolith.a ../../../v8/
RUN cp out.gn/x64.release.sample/icudtl.dat ../../../v8/
RUN cp -r include ../../../v8/

# clean up
RUN cd ../../
RUN rm -rf v8
RUN rm -rf depot_tools