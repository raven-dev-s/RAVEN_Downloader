/*
 * Copyright (C) 2025  RAVEN Devs
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
import Lomiri.Content 1.3
import "../js/utils.js" as Utils

/**
 * Sends a downloaded file to another app, such as Music or the file manager.
 */
Page {
    id: sharePage

    property string downloadedFilePath: ""
    property var activeTransfer: null

    // The page cannot close itself; whoever opened it does.
    signal closeRequested()

    readonly property string extension: downloadedFilePath.substring(downloadedFilePath.lastIndexOf(".") + 1).toLowerCase()
    readonly property bool isAudio: ["m4a", "mp3", "opus", "ogg", "oga", "aac", "flac", "wav", "weba"].indexOf(extension) >= 0
    readonly property bool isVideo: ["mp4", "mkv", "webm", "mov", "avi", "flv", "3gp", "m4v", "ts"].indexOf(extension) >= 0

    function cancel() {
        if (activeTransfer) {
            activeTransfer.state = ContentTransfer.Aborted;
        }
        closeRequested();
    }

    header: PageHeader {
        id: shareHeader
        title: i18n.tr("Save as…")
        subtitle: Utils.extractFileName(sharePage.downloadedFilePath)

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.tr("Cancel")
                onTriggered: sharePage.cancel()
            }
        ]
    }

    ContentPeerPicker {
        id: peerPicker
        anchors {
            top: shareHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        showTitle: false
        // Offer the apps that take this kind of file.
        contentType: sharePage.isAudio ? ContentType.Music
                                       : sharePage.isVideo ? ContentType.Videos : ContentType.All
        handler: ContentHandler.Destination

        onPeerSelected: {
            sharePage.activeTransfer = peer.request();
            if (sharePage.activeTransfer) {
                sharePage.activeTransfer.items = [
                    Utils.createContentItem(contentItemComponent, sharePage.downloadedFilePath)
                ];
                // Charged hands the file over. The receiving app takes it from
                // here, so this page is done.
                sharePage.activeTransfer.state = ContentTransfer.Charged;
                console.log("[ContentHub] File handed over:", sharePage.downloadedFilePath);
            }
            sharePage.closeRequested();
        }

        onCancelPressed: sharePage.cancel()
    }

    ContentTransferHint {
        anchors.fill: parent
        activeTransfer: sharePage.activeTransfer
    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }
}
