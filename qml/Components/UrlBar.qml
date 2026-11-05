/*
 * Copyright (C) 2026  RAVEN Devs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * raven.downloader is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3

/**
 * Link entry docked in the page header. It spans the whole header width
 * and draws no frame of its own, so it reads as part of the header.
 */
Item {
    id: urlBar

    property alias text: urlField.text
    property bool playlistMode: modeSections.selectedIndex === 1
    property bool busy: false

    signal submitted(string url, bool isPlaylist)

    function setPlaylistMode(enabled) {
        modeSections.selectedIndex = enabled ? 1 : 0;
    }

    function submit() {
        var url = urlField.text.trim();
        if (url.length === 0 || busy) {
            return;
        }
        urlField.focus = false;
        Qt.inputMethod.hide();
        submitted(url, playlistMode);
    }

    height: urlField.height + controls.height

    TextField {
        id: urlField
        objectName: "urlField"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(6)
        placeholderText: urlBar.playlistMode ? i18n.tr("Paste a playlist link") : i18n.tr("Paste a video link")
        inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        onAccepted: urlBar.submit()

        // Replaces the rounded field frame: the header itself is the field.
        style: Component {
            Item {
                anchors.fill: parent
                z: -1
                property color color: theme.palette.normal.backgroundText
                property color selectedTextColor: theme.palette.selected.selectionText
                property color selectionColor: theme.palette.selected.selection
                property real frameSpacing: units.gu(2)
            }
        }

        primaryItem: Icon {
            width: units.gu(2.5)
            height: width
            name: "stock_link"
            color: urlField.activeFocus ? theme.palette.normal.focus
                                        : theme.palette.normal.backgroundSecondaryText
        }

        secondaryItem: AbstractButton {
            width: visible ? units.gu(4) : 0
            height: units.gu(4)
            visible: urlField.text.length === 0
            action: Action {
                iconName: "edit-paste"
                text: i18n.tr("Paste")
                onTriggered: {
                    urlField.text = Clipboard.data.text ? Clipboard.data.text.trim() : "";
                    urlField.forceActiveFocus();
                }
            }

            Icon {
                anchors.centerIn: parent
                width: units.gu(2.5)
                height: width
                name: parent.iconName
                color: theme.palette.normal.backgroundSecondaryText
            }
        }
    }

    Rectangle {
        anchors {
            top: urlField.bottom
            left: parent.left
            right: parent.right
        }
        height: urlField.activeFocus ? units.dp(2) : units.dp(1)
        color: urlField.activeFocus ? theme.palette.normal.focus : theme.palette.normal.base
    }

    Item {
        id: controls
        anchors {
            top: urlField.bottom
            left: parent.left
            right: parent.right
        }
        height: units.gu(6)

        Sections {
            id: modeSections
            objectName: "modeSections"
            anchors {
                left: parent.left
                leftMargin: units.gu(1)
                right: fetchButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            model: [i18n.tr("Video"), i18n.tr("Playlist")]
        }

        Button {
            id: fetchButton
            objectName: "fetchButton"
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            width: units.gu(11)
            text: urlBar.busy ? "" : i18n.tr("Fetch")
            color: theme.palette.normal.positive
            enabled: !urlBar.busy && urlField.text.trim().length > 0
            onClicked: urlBar.submit()

            ActivityIndicator {
                anchors.centerIn: parent
                height: units.gu(2.5)
                width: height
                running: urlBar.busy
                visible: running
            }
        }
    }
}
