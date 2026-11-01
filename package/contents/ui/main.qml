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
    property string scannerCommand: "python " + Qt.resolvedUrl("../scripts/steam_library.py").toString().substring(7)
    property int caseWidth: 21
    property int shelfCapacity: Math.max (1, Math.floor((width - 30) / caseWidth))

    onShelfCapacityChanged: {
        console.log("Shelf capacity:", shelfCapacity)
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
                console.log("Steam Shelf Loaded", root.games.length, "games")
            }
        }
    }

    width: 500
    height: 300

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            id: shelfBack
            z: 1

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: shelf.top

            height: 200
            color: "transparent"

            Repeater {
                model: root.games

                GameCase {
                    required property var modelData
                    required property int index

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

                    x: 30 + ((index % root.shelfCapacity) * root.caseWidth)
                    anchors.bottom: shelfBack.bottom
                }
            }
        }

        Rectangle {
            id: shelf

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50

            height: 24
            color: "#6b4423"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: 5
                color: "#3f2815"
            }

            Text {
                id: refreshIcon

                anchors.right: parent.right
                anchors.rightMargin: 10
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

        Text {
            id: gameTitleText
            
            anchors.top: shelf.bottom
            anchors.topMargin: 8
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
}
