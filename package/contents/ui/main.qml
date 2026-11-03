import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property var games: []
    property string launchingGameTitle: ""
    property string hoveredGameTitle: ""
    property string scannerCommand: "python3 " + Qt.resolvedUrl("../scripts/steam_library.py").toString().substring(7)
    property int caseWidth: 21
    property int shelfCapacity: Math.max (1, Math.floor((width - 38) / caseWidth))
    property int shelfCount: Math.max(1, Math.ceil(games.length / shelfCapacity))
    property int shelfRowHeight: 224

    onShelfCapacityChanged: {
        console.log("Shelf capacity:", shelfCapacity)
    }

    onShelfCountChanged: {
        console.log ("Shelf count:", shelfCount)
    }

    onHoveredGameTitleChanged: {
        titleFadeAnimation.restart()
    }

    onLaunchingGameTitleChanged: {
        titleFadeAnimation.restart()
    }

    function refreshLibrary(){
        steamLibrarySource.disconnectSource(root.scannerCommand)
        steamLibrarySource.connectSource(root.scannerCommand)
    }	

    Timer {
        id: launchMessageTimer
        interval: 3000
        repeat: false

        onTriggered: {
            root.launchingGameTitle = ""
        }
    }

    Plasma5Support.DataSource {
        id: steamLibrarySource

        engine: "executable"
        interval: 10000

        connectedSources: [
            root.scannerCommand
        ]

        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) {
                root.games = JSON.parse(data.stdout)
            }
        }
    }

    width: 500
    height: 300

        Rectangle {
            id: shelfTop

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 24
            color: "#6b4423"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                anchors.leftMargin: 24
                anchors.rightMargin: 24

                height: 5
                color: "#3f2815"
            }
            
            Text {
                id: refreshIcon

                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.verticalCenter: parent.verticalCenter

                text: "↻"
                color: refreshMouseArea.containsMouse ? "#d6b080" : "#3f2815"
                font.pixelSize: 20
                font.bold: true

                MouseArea {
                    id: refreshMouseArea

                    anchors.centerIn: parent
                    width: 28
                    height: 24
                    hoverEnabled: true

                    onClicked: {
                        root.refreshLibrary()
                    }
                }
            }
        }

        Rectangle {
            id: shelfBack
            z: 1

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: shelfTop.bottom

            height: 200
            color: "transparent"

            Rectangle {
                id: leftShelfSide
                z: 0

                anchors.left: parent.left
                anchors.top: parent.top

                width: 24
                height: 200
                color: "#6b4423"
            }

            Repeater {
                model: root.games

                GameCase {
                    required property var modelData
                    required property int index
                    property int shelfRow: Math.floor(index / root.shelfCapacity)

                    onShelfRowChanged: {
                        console.log(gameTitle, "Moved to shelf row", shelfRow)
                    }

                    gameTitle: modelData.name
                    coverSource: modelData.cover ? "file://" + modelData.cover : ""
                    iconSource: modelData.icon ? "file://" + modelData.icon : ""
                    appId: modelData.appid
                    shelfLayer: index

                    onHoverChanged: function(title, hovered) {
                        if (hovered) {
                            root.hoveredGameTitle = title
                        } else if (root.hoveredGameTitle === title) {
                            root.hoveredGameTitle = ""
                        }
                    }

                    onLaunchRequested: function(title) {
                        root.launchingGameTitle = title
                        launchMessageTimer.restart()
                        console.log("Launch requested for:", title)
                    }

                    x: 25 + ((index % root.shelfCapacity) * root.caseWidth)
                    y: shelfBack.height - height + (shelfRow * root.shelfRowHeight)
                }
            }
        }

        Rectangle {
            id: rightShelfSide
            z: 1

            anchors.right: parent.right
            anchors.top: shelfTop.bottom

            width: 24
            height: (root.shelfCount * root.shelfRowHeight) -24
            color: "#6b4423"
        }

        Rectangle {
            id: shelf

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: shelfBack.bottom
            
            height: 24
            color: "#6b4423"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                anchors.leftMargin: root.shelfCount > 1 ? 24 : 0
                anchors.rightMargin: root.shelfCount > 1 ? 24 : 0

                height: 5
                color: "#3f2815"
            }
        }

        Repeater {
            model: Math.max(0, root.shelfCount - 1)

            Rectangle {
                required property int index

                anchors.left: parent.left
                anchors.right: parent.right

                y: shelf.y + ((index + 1) * root.shelfRowHeight)

                height: 24
                color: "#6b4423"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    anchors.leftMargin: index < root.shelfCount - 2 ? 24 : 0
                    anchors.rightMargin: index < root.shelfCount - 2 ? 24 : 0

                    height: 5
                    color: "#3f2815"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.top

                    width: 24
                    height: 200
                    color: "#6b4423"

                    z: -1
                }
            }
        }

        Text {
            id: gameTitleText
            
            
            y: shelf.y
                + ((root.shelfCount - 1) * root.shelfRowHeight)
                + shelf.height
                + 8
            anchors.horizontalCenter: parent.horizontalCenter

            text: ""
            color: "white"
            font.pixelSize: 16
            font.bold: true
            opacity: 0
        }

        SequentialAnimation {
            id: titleFadeAnimation

            NumberAnimation {
                target: gameTitleText
                property: "opacity"
                to: 0
                duration: 100
            }

            ScriptAction {
                script: {
                    if (root.launchingGameTitle !== "") {
                        gameTitleText.text = "Launching " + root.launchingGameTitle + "..."
                    } else {
                        gameTitleText.text = root.hoveredGameTitle
                    }
                }
            }

            NumberAnimation {
                target: gameTitleText
                property: "opacity"
                to: (root.hoveredGameTitle !== "" || root.hoveredGameTitle !== "") ? 1 : 0
                duration: 200
            }
        }
    }
