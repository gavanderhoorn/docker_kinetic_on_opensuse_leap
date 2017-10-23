FROM opensuse:leap

# add repo for liblog4cxx10
RUN zypper addrepo http://download.opensuse.org/repositories/devel:libraries:c_c++/openSUSE_Leap_42.3/devel:libraries:c_c++.repo

# install python-yaml here to avoid pip installing it later
RUN zypper --gpg-auto-import-keys refresh \
 && zypper --non-interactive install python-pyOpenSSL cmake gcc gcc-c++ python-pip nano git mercurial liblog4cxx10 \
 && zypper clean -a

RUN pip install --upgrade pip

# build console_bridge
RUN git clone https://github.com/ros/console_bridge.git /tmp/console_bridge \
 && mkdir /tmp/console_bridge/build \
 && cd /tmp/console_bridge/build \
 && cmake /tmp/console_bridge -DCMAKE_BUILD_TYPE=Release \
 && make install

# base ros tools
RUN pip install wstool rosdep rosinstall rospkg catkin_pkg rosinstall_generator empy

# optional: add a non-root user here and change to it

RUN rosdep init \
 && rosdep update

WORKDIR /ros_ws

RUN rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall \
 && wstool init -j8 src kinetic-ros_comm-wet.rosinstall

# repo for python-imaging
RUN zypper addrepo https://download.opensuse.org/repositories/home:/ecsos/openSUSE_Leap_42.3/home:ecsos.repo

# install dependencies
RUN zypper --gpg-auto-import-keys refresh \
 && rosdep install -y --from-paths src -i --rosdistro kinetic \
      --skip-keys="\
        libconsole-bridge-dev \
        python-catkin-pkg \
        python-empy \
        python-rosdep \
        python-rospkg \
        python-yaml" \
 && zypper clean -a

# install anything missing
RUN zypper refresh \
 && zypper --non-interactive install liblz4-devel \
 && zypper clean -a

RUN pip install catkin_tools \
 && catkin config --install --install-space=/opt/ros/kinetic \
 && catkin b --summarize --no-status --make-args -j16 \
 && catkin clean --logs --build --devel -y
