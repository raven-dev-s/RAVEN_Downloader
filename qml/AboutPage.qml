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

import "Components"
import "version.js" as Version

Page {
    id: aboutPageRoot

    property var pythonInstance
    property string ytDlpVersion: ""

    header: PageHeader {
        title: i18n.tr("About")
    }

    Component.onCompleted: {
        if (pythonInstance) {
            pythonInstance.call('download_manager.get_yt_dlp_version', [], function(version) {
                ytDlpVersion = version || "";
            });
        }
    }

    Flickable {
        id: aboutScroll
        clip: true
        anchors {
            top: aboutPageRoot.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: aboutColumn.height + units.gu(2)

        Column {
            id: aboutColumn
            width: aboutScroll.width

            Column {
                width: parent.width
                topPadding: units.gu(3)
                bottomPadding: units.gu(1)
                spacing: units.gu(0.5)

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(14)
                    height: units.gu(14)
                    property color backgroundColor: theme.palette.normal.background
                    source: backgroundColor.r + backgroundColor.g + backgroundColor.b < 1.5
                            ? Qt.resolvedUrl("../assets/raven/logo_dark.png")
                            : Qt.resolvedUrl("../assets/raven/logo_light.png")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textSize: Label.Large
                    text: "RAVEN Downloader"
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textSize: Label.Small
                    color: theme.palette.normal.backgroundSecondaryText
                    text: i18n.tr("Version %1").arg(Version.BUILD_VERSION)
                }

                Item {
                    width: parent.width
                    height: units.gu(0.5)
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - units.gu(4)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: i18n.tr("Download videos from YouTube, Vimeo, Dailymotion, Twitch, Facebook, Instagram, X, TikTok, SoundCloud, Reddit, Bilibili and more.")
                }
            }

            SectionLabel {
                text: i18n.tr("Support")
            }

            LinkRow {
                title: "RAVEN Devs"
                subtitle: "support@raven-dev.tech"
                link: "mailto:support@raven-dev.tech"
                iconName: "email"
            }

            LinkRow {
                title: i18n.tr("Report a problem")
                subtitle: i18n.tr("Issue tracker on GitHub")
                link: "https://github.com/raven-dev-s/RAVEN_Downloader/issues"
                iconName: "dialog-warning-symbolic"
            }

            LinkRow {
                title: i18n.tr("Chat on Telegram")
                subtitle: "@HackerShohag"
                link: "https://t.me/HackerShohag"
                iconName: "message"
            }

            SectionLabel {
                text: i18n.tr("Project")
            }

            LinkRow {
                title: i18n.tr("Source code")
                subtitle: "github.com/raven-dev-s/RAVEN_Downloader"
                link: "https://github.com/raven-dev-s/RAVEN_Downloader"
                iconName: "note"
            }

            LinkRow {
                title: i18n.tr("License")
                subtitle: "GNU GPL v3.0"
                link: "https://www.gnu.org/licenses/gpl-3.0.html"
                iconName: "stock_document"
            }

            SectionLabel {
                text: i18n.tr("Built with")
            }

            LinkRow {
                title: "yt-dlp"
                subtitle: ytDlpVersion
                link: "https://github.com/yt-dlp/yt-dlp"
            }

            LinkRow {
                title: "FFmpeg"
                subtitle: "8.0.1"
                link: "https://ffmpeg.org"
            }
        }
    }

    Scrollbar {
        flickableItem: aboutScroll
        align: Qt.AlignTrailing
    }
}
