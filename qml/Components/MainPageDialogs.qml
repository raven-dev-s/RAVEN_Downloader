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
import Lomiri.Components.Popups 1.3

import "../js/utils.js" as Utils

QtObject {
    id: dialogRoot

    readonly property Component processError: Component {
        WarningDialog {
            title: i18n.tr("Could not fetch this link")
            text: i18n.tr("An unknown error occurred.")
        }
    }

    readonly property Component invalidPlaylistURL: Component {
        WarningDialog {
            title: i18n.tr("Not a playlist link")
            text: i18n.tr("This doesn't look like a playlist from a supported site. Check the link, or choose Video if it's a single video.")
        }
    }

    readonly property Component playlistAsVideo: Component {
        Dialog {
            id: playlistDialog
            property string url: ""

            title: i18n.tr("This link is part of a playlist")
            text: i18n.tr("Do you want the whole playlist, or only this video?")

            Button {
                text: i18n.tr("Whole playlist")
                color: theme.palette.normal.positive
                onClicked: {
                    root.playlistModeRequested();
                    root.urlHandler(playlistDialog.url, true);
                    PopupUtils.close(playlistDialog);
                }
            }

            Button {
                text: i18n.tr("Only this video")
                onClicked: {
                    root.urlHandler(Utils.stripPlaylistParams(playlistDialog.url), false);
                    PopupUtils.close(playlistDialog);
                }
            }

            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(playlistDialog)
            }
        }
    }

    readonly property Component invalidURL: Component {
        WarningDialog {
            title: i18n.tr("Link not recognized")
            text: i18n.tr("This doesn't look like a video from a supported site. Check the link and try again.")
        }
    }

    readonly property Component playlistFinished: Component {
        WarningDialog {
            property string playlistTitle: ""
            property int addedCount: 0
            property int totalCount: 0

            title: i18n.tr("Playlist added")
            text: i18n.tr("Added %1 of %2 videos from \"%3\". Choose a quality and download the ones you want.")
                      .arg(addedCount).arg(totalCount).arg(playlistTitle)
        }
    }
}
