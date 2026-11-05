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

/**
 * Starts a download and follows it. Once a file exists the button offers
 * saving it instead of downloading again.
 */
Button {
    id: downloadButton

    property var pythonInstance: null
    property string videoUrl: ""
    // Called when a download starts, returning the options for the backend.
    property var optionsProvider: null
    property var dialogs: null
    // Path of the finished file. An empty path means nothing is downloaded.
    property string filePath: ""

    // One of: idle, starting, downloading, processing, failed
    property string downloadState: "idle"
    property real progress: 0
    readonly property bool active: downloadState === "starting"
                                   || downloadState === "downloading"
                                   || downloadState === "processing"
    readonly property bool hasFile: filePath !== "" && !active

    property int pollDownloadId: -1
    property bool quiet: false

    signal downloadStarted()
    signal downloadFinished(string filePath, string fileName)
    signal downloadError(string error)
    signal saveRequested(string filePath)

    text: active ? "" : (hasFile ? i18n.tr("Save") : i18n.tr("Download"))
    color: hasFile ? theme.palette.normal.positive : theme.palette.normal.foreground
    enabled: !active

    onClicked: {
        if (hasFile) {
            saveRequested(filePath);
        } else {
            start(optionsProvider ? optionsProvider() : null, false);
        }
    }

    // quiet downloads report through the list only, without a dialog at the end.
    function start(options, isQuiet) {
        if (!pythonInstance || !videoUrl || !options || active) {
            console.error('[DownloadButton] Missing required properties');
            return;
        }

        quiet = isQuiet;
        filePath = "";
        progress = 0;
        downloadState = "starting";
        downloadStarted();

        pythonInstance.call('download_manager.action_download', [videoUrl, options], function(result) {
            handleDownloadResponse(result);
        });
    }

    function handleDownloadResponse(result) {
        if (result && result.success === false && result.error) {
            handleError(result);
        } else if (result && result.download_id !== undefined) {
            pollDownloadId = result.download_id;
            pollTimer.start();
        } else {
            console.error('[DownloadButton] Unexpected response:', result);
            handleError({});
        }
    }

    function handleDownloadStatus(status) {
        if (status.progress !== undefined) {
            progress = status.progress / 100.0;
        }

        if (status.status === 'finished') {
            handleFinished(status);
        } else if (status.status === 'error') {
            handleError(status);
        } else if (status.status === 'processing' || status.status === 'downloading') {
            downloadState = status.status;
        }
    }

    function handleFinished(status) {
        pollTimer.stop();
        progress = 1.0;
        downloadState = "idle";
        filePath = status.filename || "";

        var fileName = filePath;
        if (fileName.indexOf('/') !== -1) {
            fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
        }

        if (!quiet && dialogs && dialogs.downloadFinishedDialog) {
            PopupUtils.open(dialogs.downloadFinishedDialog, downloadButton, {
                fileName: fileName,
                filePath: filePath
            });
        }

        downloadFinished(filePath, fileName);
    }

    function handleError(status) {
        pollTimer.stop();
        progress = 0;
        downloadState = "failed";

        var errorMsg = status.error || i18n.tr("An error occurred while starting the download.");
        if (dialogs && dialogs.downloadErrorDialog) {
            PopupUtils.open(dialogs.downloadErrorDialog, downloadButton, {
                errorMessage: errorMsg
            });
        }

        downloadError(errorMsg);
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        onTriggered: {
            downloadButton.pythonInstance.call('download_manager.get_download_progress', [downloadButton.pollDownloadId], function(status) {
                // A reply can arrive after polling ended; it must not reopen a result.
                if (status && pollTimer.running) {
                    downloadButton.handleDownloadStatus(status);
                }
            });
        }
    }

    ActivityIndicator {
        anchors.centerIn: parent
        height: units.gu(2.5)
        width: height
        running: downloadButton.active
        visible: running
    }
}
