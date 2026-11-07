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
import Lomiri.Components.Popups 1.3

import "Components"
import "js/utils.js" as Utils

/**
 * Files the app has downloaded, opened from the bottom edge.
 */
Page {
    id: libraryPage

    property var pythonInstance
    property bool loading: false
    property real totalSize: 0

    signal closeRequested()
    signal saveRequested(string path)

    function refresh() {
        if (!pythonInstance) {
            return;
        }
        loading = true;
        pythonInstance.call('storage_manager.list_library', [], function(files) {
            filesModel.clear();
            var total = 0;
            for (var i = 0; i < files.length; i++) {
                filesModel.append(files[i]);
                total += files[i].size;
            }
            totalSize = total;
            loading = false;
        });
    }

    header: PageHeader {
        title: i18n.tr("Library")
        subtitle: filesModel.count > 0
                  ? i18n.tr("%1 files · %2").arg(filesModel.count).arg(Utils.formatBytes(libraryPage.totalSize))
                  : ""
        leadingActionBar.actions: [
            Action {
                iconName: "down"
                text: i18n.tr("Close")
                onTriggered: libraryPage.closeRequested()
            }
        ]
    }

    ListModel {
        id: filesModel
    }

    // A plain column of rows, like the main list. Rows a ListView creates get
    // the system theme instead of the app's, which left text unreadable when
    // the two differ.
    Flickable {
        id: filesView
        anchors {
            top: libraryPage.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: filesColumn.height

        Column {
            id: filesColumn
            width: filesView.width

            Repeater {
                model: filesModel

                delegate: ListItem {
                    width: filesColumn.width
                    height: fileLayout.height + divider.height
                    onClicked: libraryPage.saveRequested(model.path)

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                text: i18n.tr("Delete")
                                // Deleting erases the file itself, so ask first.
                                onTriggered: PopupUtils.open(deleteConfirmation, libraryPage, {
                                    path: model.path,
                                    fileName: model.name
                                })
                            }
                        ]
                    }

                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "share"
                                text: i18n.tr("Save as…")
                                onTriggered: libraryPage.saveRequested(model.path)
                            }
                        ]
                    }

                    ListItemLayout {
                        id: fileLayout
                        title.text: model.name
                        title.elide: Text.ElideMiddle
                        subtitle.text: Utils.formatBytes(model.size) + " · "
                                       + Qt.formatDate(new Date(model.mtime * 1000), Qt.DefaultLocaleShortDate)

                        Icon {
                            SlotsLayout.position: SlotsLayout.Leading
                            width: units.gu(3)
                            height: width
                            name: model.kind === "audio" ? "stock_music" : "stock_video"
                            color: theme.palette.normal.backgroundSecondaryText
                        }

                        ProgressionSlot {}
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: filesView
        align: Qt.AlignTrailing
    }

    Component {
        id: deleteConfirmation

        Dialog {
            id: deleteDialog
            property string path: ""
            property string fileName: ""

            title: i18n.tr("Delete this file?")
            text: i18n.tr("\"%1\" will be deleted from your phone. This cannot be undone.").arg(fileName)

            Button {
                text: i18n.tr("Delete")
                color: theme.palette.normal.negative
                onClicked: {
                    var path = deleteDialog.path;
                    PopupUtils.close(deleteDialog);
                    downloadManager.deleteLibraryFile(path, function(deleted) {
                        if (deleted) {
                            libraryPage.refresh();
                        }
                    });
                }
            }

            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(deleteDialog)
            }
        }
    }

    EmptyState {
        anchors.centerIn: filesView
        width: Math.min(filesView.width - units.gu(6), units.gu(40))
        visible: !libraryPage.loading && filesModel.count === 0
        iconName: "save"
        title: i18n.tr("Nothing here yet")
        description: i18n.tr("Every download is kept here. Tap a file to save it to Music, Videos or another app.")
    }
}
