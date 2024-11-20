# Use a lightweight Alpine Linux image
# FROM alpine:latest
FROM ubuntu:22.04 AS base

# Update the package lists
RUN apt-get update -y

FROM base AS build

# Install dependencies
# Install required packages, including Mono
RUN apt-get install -y \
    # mono-devel \
    wget \
    unzip
RUN apt-get install -y dotnet-sdk-8.0

RUN apt-get install -y libfontconfig1
# RUN apt-get install -y mono-devel

# RUN apt-get install -y Xlib
# RUN apk add --no-cache \
#     wget unzip \
#     freetype fontconfig libpng libjpeg-turbo

# RUN apk add dotnet8-sdk

# RUN apk add --no-cache godot --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

# RUN apk add libX11-dev libxcb1-dev libXcursor-dev libXrandr-dev libXi-dev libXinerama-dev libXext-dev
# RUN apk add mesa-libgl mesa-libglu

# Download and extract Godot
WORKDIR /opt/godot

# USER root

RUN wget https://downloads.tuxfamily.org/godotengine/4.3/mono/Godot_v4.3-stable_mono_linux_x86_64.zip \
    && unzip Godot_v4.3-stable_mono_linux_x86_64.zip \
    && rm Godot_v4.3-stable_mono_linux_x86_64.zip

#download templates
RUN wget https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_mono_export_templates.tpz
RUN mkdir -p /root/.local/share/godot/export_templates/
RUN unzip Godot_v4.3-stable_mono_export_templates.tpz -d /root/.local/share/godot/export_templates/
RUN rm Godot_v4.3-stable_mono_export_templates.tpz
RUN mv /root/.local/share/godot/export_templates/templates/ /root/.local/share/godot/export_templates/4.3.stable.mono/
# COPY ./linux-server-export-template/ /root/.local/share/godot/export_templates/4.3.stable.mono/

# Copy your Godot project
COPY . /app/

RUN chmod +x ./Godot_v4.3-stable_mono_linux_x86_64/Godot_v4.3-stable_mono_linux.x86_64

WORKDIR /app

RUN echo $(ls -1 /app)

RUN mkdir -p /app/export/linux-server

# Build the release export
RUN /opt/godot/Godot_v4.3-stable_mono_linux_x86_64/Godot_v4.3-stable_mono_linux.x86_64 --headless --export-release "linux-server"  -v 

RUN echo $(ls -1 /app/export/linux-server)

FROM base AS deploy

RUN apt-get install -y libicu-dev

RUN groupadd -g 1234 godot
RUN useradd -m -u 1234 -g godot godot

# USER godot

WORKDIR /app

EXPOSE 9999
EXPOSE 9999/udp

ENV PORT 9999

COPY --from=build /app/export/linux-server /app
RUN echo $(ls -1 /app)

# COPY project.godot /app/

# COPY server.cfg /app/
# RUN mv /app/server.cfg /app/config.cfg

# COPY server.cfg /app/
# RUN mkdir -p /home/godot/.local/share/godot/app_userdata/MarbleGame/
# RUN mv /app/server.cfg /home/godot/.local/share/godot/app_userdata/MarbleGame/config.cfg


# Command to run the release export
# CMD ["./your_project.x86_64"]
# CMD ["sleep", "infinity"]
CMD ["/app/MarbleGame.sh","--","--server=true"]