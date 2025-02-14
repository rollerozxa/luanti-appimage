# Luanti AppImage Linux builds
[Luanti forum topic](https://forum.luanti.org/viewtopic.php?t=31136)

For users on Linux distributions with outdated package repositories that do not get newer package updates, it can be difficult obtaining up to date builds of Luanti. The general advice is usually "build from source", linking to the compilation instructions in the Git repository, but even if building is not a lot of commands it can be difficult to ask for people who just want to play.

The AppImage format is a single self-contained executable that contains everything required for a program including any data files and depending libraries. To run an AppImage you simply download it, mark it as executable in your file manager, and run.

The AppImage builds should work on anything that is equivalent to Debian 11 Bullseye or newer, meaning any distro version released within the last three years or so. You also need to have functional OpenGL libraries on your system to run the AppImage.

If you experience any segfaults with Luanti when running these builds then there are debug symbols provided as separate downloads with each build. These can make segfault stacktraces more human readable when you are reporting engine crashes to the core developers.

## Download
See the [Releases](https://github.com/rollerozxa/luanti-appimage/releases) page.

## Technical details
The builds are made using some scripts in Github Actions, which are available in this repository.
