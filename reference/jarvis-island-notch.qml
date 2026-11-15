// Jarvis glass notch, centered at the top edge. Expands while Jarvis speaks,
// listens, thinks, or when the current track changes.
// Speech uses italic serif text (New York); system information uses sans serif (SF Pro).
// The bottom line shows a voice waveform or media progress.
// Run: qs -c jarvis-island     Control: qs -c jarvis-island ipc call island <function> ...
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    // ---- Caelestia palette colors follow the wallpaper ----
    property var c: ({})
    function col(name, alpha) {
        const hex = c[name] ?? "888888";
        return Qt.rgba(parseInt(hex.substr(0, 2), 16) / 255, parseInt(hex.substr(2, 2), 16) / 255,
                       parseInt(hex.substr(4, 2), 16) / 255, alpha ?? 1);
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.c = JSON.parse(text()).colours; } catch (e) {}
        }
    }

    // Orange dot: microphone listening, set by jarvis listen through the mic IPC method.
    property bool micOn: false

    // ---- status: idle | media | speak | listen | think ----
    property string mode: "idle"
    property string caption: ""
    property var envelope: []
    property int envIndex: 0
    property real level: 0
    readonly property bool voice: ["speak", "listen", "think"].includes(mode)

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.identity === "Spotify")
        ?? Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing) ?? null
    readonly property real progress: player && player.lengthSupported && player.length > 0
        ? Math.min(1, player.position / player.length) : 0

    function show(m, ms) {
        mode = m;
        hideTimer.interval = ms;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        onTriggered: root.mode = "idle"
    }

    Connections {
        target: root.player
        function onTrackTitleChanged() {
            if (root.mode === "idle" || root.mode === "media")
                root.show("media", 4000);
        }
    }

    // Mpris does not update track position automatically; request it every second while visible.
    Timer {
        interval: 1000
        repeat: true
        running: root.mode === "media" && root.player !== null
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    // Audio amplitude: a 50 ms envelope from the Jarvis script.
    Timer {
        id: envTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (root.envIndex < root.envelope.length)
                root.level = root.envelope[root.envIndex++];
            else
                root.level = 0;
        }
    }
    // Slow pulse while listening or thinking.
    property real breath: 0
    SequentialAnimation on breath {
        running: root.mode === "listen" || root.mode === "think"
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
    }

    IpcHandler {
        target: "island"
        function speak(text: string, env: string, ms: int): void {
            root.caption = text;
            root.envelope = env.split(",").map(Number);
            root.envIndex = 0;
            envTimer.restart();
            root.show("speak", ms + 600);
        }
        function hear(): void { root.caption = "Listening"; root.show("listen", 10000); }
        function think(): void { root.caption = "Thinking"; root.show("think", 30000); }
        function idle(): void { root.mode = "idle"; }
        function mic(on: bool): void { root.micOn = on; }
    }

    PanelWindow {
        anchors.top: true
        implicitWidth: 760
        implicitHeight: 140
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "jarvis-island"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: notch }

        Rectangle {  // Microphone dot while the notch is hidden.
            width: 6; height: 6; radius: 3
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4
            color: "#ff9f0a"
            opacity: root.micOn && !notch.open ? 0.9 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Item {
            id: notch

            readonly property bool open: root.mode !== "idle"
            readonly property real ear: 14      // Concave join connecting the notch to the screen edge.
            readonly property real pad: 22
            // Body width, excluding the concave joins, follows the content.
            readonly property real bodyW: root.mode === "media" ? 440
                : root.mode === "speak" ? Math.max(300, Math.min(620, speech.implicitWidth + pad * 2))
                : 220
            readonly property real bodyH: root.mode === "media" ? 80
                : root.mode === "speak" ? speech.height + 50
                : 56

            anchors.horizontalCenter: parent.horizontalCenter
            width: bodyW + ear * 2
            height: bodyH
            // Idle: hidden above the screen.
            y: open ? 0 : -height - 6

            Behavior on width { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.5 } }
            Behavior on height { SpringAnimation { spring: 4; damping: 0.34; epsilon: 0.5 } }
            Behavior on y { SpringAnimation { spring: 3.5; damping: 0.38; epsilon: 0.5 } }

            // SVG outline: concave upper joins and rounded lower corners.
            readonly property real r: Math.min(26, height / 2)
            readonly property string outline: {
                const e = ear, w = width, h = height, r = notch.r;
                return `M0,0 A${e},${e} 0 0 1 ${e},${e} L${e},${h - r} A${r},${r} 0 0 0 ${e + r},${h} `
                     + `L${w - e - r},${h} A${r},${r} 0 0 0 ${w - e},${h - r} L${w - e},${e} A${e},${e} 0 0 1 ${w},0`;
            }

            // Hyprland blurs the background through the jarvis-island layer rule.
            // Tint, bottom glow, corner highlights, and a bright rim are layered above it.
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {  // Glass tint.
                    fillColor: root.col("surface", 0.38)
                    strokeWidth: -1
                    PathSvg { path: notch.outline + " Z" }
                }
                ShapePath {  // Soft light gathering at the bottom of the glass.
                    strokeWidth: -1
                    fillGradient: LinearGradient {
                        y1: notch.height * 0.35; y2: notch.height
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.07) }
                    }
                    PathSvg { path: notch.outline + " Z" }
                }
                ShapePath {  // Highlights at the two lower corners.
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: notch.ear + notch.r * 0.7; centerY: notch.height - notch.r * 0.7
                        focalX: centerX; focalY: centerY
                        centerRadius: 46
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.13) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                    }
                    PathSvg { path: notch.outline + " Z" }
                }
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: notch.width - notch.ear - notch.r * 0.7; centerY: notch.height - notch.r * 0.7
                        focalX: centerX; focalY: centerY
                        centerRadius: 46
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.09) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                    }
                    PathSvg { path: notch.outline + " Z" }
                }
                ShapePath {  // Glass rim: brightest near the corners, dimmer in the center.
                    fillColor: "transparent"
                    strokeWidth: 1.2
                    capStyle: ShapePath.RoundCap
                    strokeGradient: LinearGradient {
                        x1: 0; x2: notch.width
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                        GradientStop { position: 0.07; color: Qt.rgba(1, 1, 1, 0.55) }
                        GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.10) }
                        GradientStop { position: 0.93; color: Qt.rgba(1, 1, 1, 0.40) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.08) }
                    }
                    PathSvg { path: notch.outline }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (root.player) root.show("media", 5000)
            }

            // Content inside the body, excluding the concave joins.
            Item {
                id: body
                anchors { fill: parent; leftMargin: notch.ear + notch.pad; rightMargin: notch.ear + notch.pad }
                clip: true

                Rectangle {  // Active microphone.
                    width: 6; height: 6; radius: 3
                    anchors { right: parent.right; rightMargin: -10; top: parent.top; topMargin: 12 }
                    color: "#ff9f0a"
                    opacity: root.micOn && notch.open ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }

                // ---- Jarvis speech: italic serif, at most two lines ----
                Text {
                    id: speech
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
                    width: Math.min(implicitWidth, 576)
                    text: root.caption
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    horizontalAlignment: lineCount > 1 ? Text.AlignLeft : Text.AlignHCenter
                    lineHeight: 1.12
                    color: root.col("onSurface")
                    font { family: "New York Medium"; italic: true; pixelSize: 17 }
                    opacity: root.mode === "speak" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                // ---- System status: small sans serif ----
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 11 }
                    text: root.caption
                    color: root.col("onSurfaceVariant")
                    font { family: "SF Pro Text"; pixelSize: 13; weight: Font.Medium; letterSpacing: 0.2 }
                    opacity: root.mode === "listen" || root.mode === "think" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                // ---- Current track ----
                Row {
                    anchors { left: parent.left; leftMargin: -8; top: parent.top; topMargin: 10 }
                    spacing: 12
                    opacity: root.mode === "media" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Rectangle {
                        width: 40; height: 40; radius: 8; clip: true
                        color: root.col("secondaryContainer")
                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize { width: 80; height: 80 }
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: body.width - 44
                        spacing: 1
                        Text {
                            width: parent.width
                            text: root.player?.trackTitle ?? ""
                            elide: Text.ElideRight
                            color: root.col("onSurface")
                            font { family: "SF Pro Display"; pixelSize: 15; weight: Font.DemiBold }
                        }
                        Text {
                            width: parent.width
                            text: root.player?.trackArtist ?? ""
                            elide: Text.ElideRight
                            color: root.col("onSurfaceVariant")
                            font { family: "SF Pro Text"; pixelSize: 13 }
                        }
                    }
                }

                // ---- Voice waveform or track progress ----
                Canvas {
                    id: line
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 6 }
                    height: 20
                    opacity: notch.open ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    property real phase: 0
                    // Wave height follows speech, or a slow pulse while listening/thinking.
                    property real amp: root.mode === "speak" ? root.level
                        : root.mode === "listen" ? 0.45 + root.breath * 0.35
                        : root.mode === "think" ? 0.12 + root.breath * 0.12 : 0
                    Behavior on amp { NumberAnimation { duration: 90 } }

                    FrameAnimation {
                        running: root.voice && notch.open
                        onTriggered: {
                            line.phase += frameTime * (root.mode === "think" ? 2.2 : 7);
                            line.requestPaint();
                        }
                    }
                    Connections {
                        target: root
                        function onProgressChanged() { line.requestPaint(); }
                        function onModeChanged() { line.requestPaint(); }
                        function onCChanged() { line.requestPaint(); }
                    }

                    onPaint: {
                        const g = getContext("2d");
                        g.reset();
                        const w = width, mid = height / 2;
                        g.lineCap = "round";
                        g.lineWidth = 2;
                        if (root.mode === "media") {
                            g.strokeStyle = root.col("outlineVariant");
                            g.beginPath(); g.moveTo(1, mid); g.lineTo(w - 1, mid); g.stroke();
                            g.strokeStyle = root.col("primary");
                            g.beginPath(); g.moveTo(1, mid); g.lineTo(1 + (w - 2) * root.progress, mid); g.stroke();
                            return;
                        }
                        g.strokeStyle = root.mode === "listen" ? root.col("tertiary")
                            : root.mode === "think" ? root.col("outline") : root.col("primary");
                        g.beginPath();
                        for (let x = 0; x <= w; x += 2) {
                            const taper = Math.sin(Math.PI * x / w);  // Keep the ends of the line still.
                            const y = mid + Math.sin(x * 0.05 + phase) * (0.55 + 0.45 * Math.sin(x * 0.013 - phase * 0.4))
                                * amp * (mid - 2) * taper;
                            x === 0 ? g.moveTo(x, y) : g.lineTo(x, y);
                        }
                        g.stroke();
                    }
                }
            }
        }
    }
}
