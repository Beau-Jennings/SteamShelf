import QtQuick

Item {
    id: gameCaseRoot

    property string gameTitle: ""
    property string coverSource: ""
    property string iconSource: ""
    property int shelfLayer: 0
    property string appId: ""

    signal hoverChanged(string title, bool hovered)
    signal launchRequested(string title)
    // The stationary footprint/hover target on the shelf.
    width: 21
    height: 180
    z: shelfLayer
    

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: {
            gameCaseRoot.launchRequested(gameCaseRoot.gameTitle)
            Qt.openUrlExternally("steam://run/" + gameCaseRoot.appId)
            console.log("clicked:", gameCaseRoot.gameTitle, "App ID:", gameCaseRoot.appId)
            
        }
    }

    Connections {
        target: hoverHandler

        function onHoveredChanged() {
            gameCaseRoot.hoverChanged(
                gameCaseRoot.gameTitle,
                hoverHandler.hovered
            )
        }
    }

    Item {
        id: caseVisual

        width: 143
        height: gameCaseRoot.height
        x: hoverHandler.hovered ? -15 : 0
        scale: hoverHandler.hovered ? 1.05 : 1.0

            Behavior on scale	{
                NumberAnimation {
                    duration: 200
                }
            }

        // Narrow spine visible while sitting on the shelf.
        Rectangle {
            id: caseBody

            width: 21
            height: parent.height
            clip: true
            color: hoverHandler.hovered ? "#4f9f63" : "#2f6f3e"
            radius: 3
            border.color: "#1c4526"
            border.width: 2

            Image {
                width: 63
                height: parent.height
                x: 0
                y: 0
                horizontalAlignment: Image.AlignLeft
                source: gameCaseRoot.coverSource
            }

            Image {
                id: gameIcon
                width: 15
                height: 15

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4

                source: gameCaseRoot.iconSource
                fillMode: Image.PreserveAspectFit
            }

            // Left shadow edge.
            Rectangle {
                width: 6
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                color: "#55000000"
                
            }

            // Top highlight.
            Rectangle {
                height: 3
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                color: "#88ffffff"
            }

            //Bottom Highlight
            Rectangle {
                height: 3
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: "#88ffffff"
            }

            // Right edge highlight.
            Rectangle {
                width: 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                color: "#000000"
            }

        }

        // Front artwork face.
        // Hidden while idle and revealed when the case is pulled out.
        Rectangle {
            id: frontCover

            width: hoverHandler.hovered ? 60 : 0
            height: parent.height            
            x: 18
            y: 0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 200
                }
            }
            color: "#3f784d"
            border.color: "#1c4526"
            border.width: 2

            Image {
                width: 81
                height: parent.height
                x: -21
                y: 0
                
                source: gameCaseRoot.coverSource
                horizontalAlignment: Image.AlignLeft
            }

            //Top edge highlight
            Rectangle {
                height: 3
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                color: "#88ffffff"
            }

            //Bottom edge highlight
            Rectangle {
                height: 3
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: "#88ffffff"
            }

            //Right edge highlight
            Rectangle {
                width: 2
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: "#88ffffff"
            }

            // Keep the cover oblique rather than facing us at 90 degrees.
            transform: Rotation {
                origin.x: 0
                origin.y: frontCover.height / 2
                angle: 45

                axis {
                    x: 0
                    y: 1
                    z: 0
                }

            }

        }

        Behavior on x {
            NumberAnimation {
                duration: 200
            }

        }

        // Rotate the visual case without moving the hover target.
        transform: Rotation {
            origin.x: 0
            origin.y: caseVisual.height / 2
            angle: hoverHandler.hovered ? -30 : 0

            axis {
                x: 0
                y: 1
                z: 0
            }

            Behavior on angle {
                NumberAnimation {
                    duration: 200
                }

            }

        }

    }

}
