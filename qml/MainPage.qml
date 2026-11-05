/*
 * Copyright (C) 2022  RAVEN Devs
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
import QtQml 2.2
import QtQuick 2.7
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4

import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

import "Components"
import "js/utils.js" as Utils

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'raven.downloader.shohag'
    automaticOrientation: true
    anchorToKeyboard: true

    width: units.gu(50)
    height: units.gu(75)

    // A video or playlist link is being looked up.
    property bool fetching: false

    signal fetchSucceeded()
    signal playlistModeRequested()

    theme: ThemeSettings {
        // An empty name follows the system theme.
        name: generalSettings.themeName
    }

    MainPageDialogs {
        id: mainDialogs
    }

    DownloadItemManager {
        id: downloadManager
        pythonInstance: python
        autoStartNewItems: generalSettings.autoDownload
        audioOnlyNewItems: generalSettings.audioOnlyDefault
    }

    PlaylistProcessor {
        id: playlistProcessor
        pythonInstance: python

        onVideoFormatsReady: function(formats) {
            downloadManager.addVideo(formats);
        }

        onProcessingComplete: function(title, added, total) {
            PopupUtils.open(mainDialogs.playlistFinished, root, {
                playlistTitle: title,
                addedCount: added,
                totalCount: total
            });
        }

        onError: function(error) {
            console.log("[MainPage] Playlist processing error:", error);
        }
    }

    Settings {
        id: generalSettings
        category: "GeneralSettings"

        property string themeName: ""
        property bool downloadSubtitle: false
        property bool downloadCaption: false
        property bool embeddedSubtitle: false
        property bool autoDownload: false
        property bool audioOnlyDefault: false
    }

    Component {
        id: contentSharePage
        ContentHubDialog {
            downloadedFilePath: ""
            pageStack: root.pageStack
        }
    }

    Component {
        id: settingsPage
        SettingsPage {
            pythonInstance: python
            settings: generalSettings
            activeDownloads: downloadManager.activeDownloads
            historyCount: downloadManager.count
        }
    }

    Component {
        id: aboutPage
        AboutPage {
            pythonInstance: python
        }
    }

    function openContentHubExport(filePath) {
        pageStack.push(contentSharePage, {
            downloadedFilePath: filePath
        });
    }

    function urlHandler(url, isPlaylist) {
        fetching = true;

        var validationFunc = isPlaylist ? 'is_valid_playlist' : 'is_valid_video_url';
        var invalidWarning = isPlaylist ? mainDialogs.invalidPlaylistURL : mainDialogs.invalidURL;

        python.call('download_manager.' + validationFunc, [url], function(isValid) {
            if (!isValid) {
                fetching = false;
                PopupUtils.open(invalidWarning, root);
                return;
            }

            python.call('download_manager.action_submit', [url, isPlaylist ? 1 : 0], function(result) {
                fetching = false;

                if (result && result.error) {
                    handleSubmitError(result.error, url);
                } else if (result && result.type === 'playlist') {
                    fetchSucceeded();
                    playlistProcessor.processPlaylist(result.data);
                } else if (result && result.type === 'video') {
                    fetchSucceeded();
                    downloadManager.addVideo(result.data);
                }
            });
        });
    }

    function handleSubmitError(error, url) {
        if (error === 'playlist_as_video') {
            PopupUtils.open(mainDialogs.playlistAsVideo, root, { url: url });
        } else {
            PopupUtils.open(mainDialogs.processError, root, { text: Utils.friendlyError(error) });
        }
    }

    // Connections below use the older "onSignal:" form on purpose. Qt 5.12 on
    // Ubuntu Touch 20.04 silently ignores the newer "function onSignal()" form.
    Connections {
        target: Qt.application
        onAboutToQuit: downloadManager.saveHistory()
    }

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: {
            push(mainPageComponent);
        }
    }

    Component {
        id: mainPageComponent

        Page {
            id: mainPage
            objectName: 'mainPageItem'
            anchors.fill: parent

            property bool historyLoading: true

            header: PageHeader {
                title: i18n.tr("RAVEN Downloader")

                trailingActionBar.actions: [
                    Action {
                        iconName: "info"
                        text: i18n.tr("About")
                        onTriggered: pageStack.push(aboutPage)
                    },
                    Action {
                        iconName: "settings"
                        text: i18n.tr("Settings")
                        onTriggered: pageStack.push(settingsPage)
                    }
                ]

                extension: UrlBar {
                    id: urlBar
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    busy: root.fetching || playlistProcessor.isProcessing
                    onSubmitted: root.urlHandler(url, isPlaylist)
                }
            }

            Connections {
                target: root
                onFetchSucceeded: urlBar.text = ""
                onPlaylistModeRequested: urlBar.setPlaylistMode(true)
            }

            Component.onCompleted: {
                downloadManager.loadHistory(function() {
                    historyLoading = false;
                });
            }

            function reloadHistoryUI() {
                historyLoading = true;
                downloadManager.reloadHistory(function() {
                    historyLoading = false;
                });
            }

            Flickable {
                id: mainScroll
                objectName: "mainScroll"
                anchors {
                    top: mainPage.header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                clip: true
                // Fills the view at least, so that the empty state centers in it.
                contentHeight: Math.max(listColumn.height, height)

                PullToRefresh {
                    parent: mainScroll
                    // Reloading rebuilds the list, which would orphan running downloads.
                    enabled: downloadManager.activeDownloads === 0
                    refreshing: mainPage.historyLoading
                    onRefresh: mainPage.reloadHistoryUI()
                }

                Column {
                    id: listColumn
                    width: mainScroll.width

                    // Shown while the videos of a playlist are being looked up.
                    ListItem {
                        width: parent.width
                        height: visible ? playlistLayout.height + divider.height : 0
                        visible: playlistProcessor.isProcessing

                        ListItemLayout {
                            id: playlistLayout
                            title.text: i18n.tr("Adding playlist: %1 of %2")
                                            .arg(playlistProcessor.processedVideos)
                                            .arg(playlistProcessor.totalVideos)
                            subtitle.text: playlistProcessor.playlistTitle

                            ActivityIndicator {
                                SlotsLayout.position: SlotsLayout.Leading
                                height: units.gu(3)
                                width: height
                                running: playlistProcessor.isProcessing
                            }

                            Button {
                                SlotsLayout.position: SlotsLayout.Trailing
                                text: i18n.tr("Stop")
                                width: units.gu(8)
                                onClicked: playlistProcessor.cancel()
                            }
                        }
                    }

                    SectionLabel {
                        visible: downloadManager.count > 0
                        text: i18n.tr("Downloads (%1)").arg(downloadManager.count)
                    }

                    Repeater {
                        id: downloadItems
                        model: downloadManager.model

                        delegate: MediaItem {
                            width: listColumn.width

                            videoTitle: vTitle
                            thumbnail: vThumbnail
                            duration: vDuration
                            videoLink: vID

                            entryId: model.entryId || ''
                            filePath: model.vFilePath || ''
                            pythonInstance: python

                            vcodec: Utils.safeParseJSON(vCodec)
                            resolutionModel: Utils.safeParseJSON(vResolutions)
                            videoExts: Utils.safeParseJSON(vVideoExts)
                            videoFormats: Utils.safeParseJSON(vVideoFormats)
                            videoProgress: vVideoProgress
                            videoIndex: vVideoIndex
                            audioIndex: vAudioIndex
                            selectedVideoCodec: model.selectedVideoCodec || ''
                            selectedAudioCodec: model.selectedAudioCodec || ''

                            acodec: Utils.safeParseJSON(aCodec)
                            audioExts: Utils.safeParseJSON(vAudioExts)
                            audioFormats: Utils.safeParseJSON(vAudioFormats)
                            audioBitrate: Utils.safeParseJSON(vABR)
                            audioSizes: Utils.safeParseJSON(vAudioSizes)

                            sizeModel: Utils.safeParseJSON(vSizeModel)
                            indexID: vIndex
                        }
                    }
                }

                ActivityIndicator {
                    anchors.centerIn: parent
                    running: mainPage.historyLoading && downloadManager.count === 0
                    visible: running
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - units.gu(6), units.gu(40))
                    visible: !mainPage.historyLoading && downloadManager.count === 0
                             && !playlistProcessor.isProcessing
                    title: i18n.tr("No downloads yet")
                    description: i18n.tr("Paste a link from YouTube, Vimeo, TikTok and more above, then tap Fetch to choose a quality.")
                }
            }

            Scrollbar {
                flickableItem: mainScroll
                align: Qt.AlignTrailing
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('download_manager', function() {});
            importModule('storage_manager', function() {});

            setHandler('historyCleared', function() {
                downloadManager.reloadHistory();
            });
        }

        onError: {
            console.log('[MainPage] Python error:', traceback);
        }
    }
}
