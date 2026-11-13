// JoeOS live wallpaper: plays a video, silently and on a loop, behind everything.
// Loaded by shell.qml only while a live wallpaper is chosen. It needs Qt's video support
// (sudo pacman -S qt6-multimedia-ffmpeg); without it, the still picture is shown instead.
import QtQuick
import QtMultimedia

Item {
    id: lw
    property url source
    property bool paused: false

    MediaPlayer {
        id: player
        source: lw.source
        loops: MediaPlayer.Infinite
        videoOutput: video
        // no audioOutput: wallpapers stay silent
        onSourceChanged: if (!lw.paused) play()
        Component.onCompleted: if (!lw.paused) play()
    }

    onPausedChanged: paused ? player.pause() : player.play()

    VideoOutput {
        id: video
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
