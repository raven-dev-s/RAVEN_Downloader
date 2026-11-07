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
import QtQuick 2.7
import QtQuick.Layouts 1.3
import Lomiri.Components 1.3

import "../js/utils.js" as Utils

ListItem {
    id: mediaItem

    height: content.height + units.gu(3) + divider.height

    property alias  videoTitle          : titleBox.text
    property string thumbnail           : ""
    property string duration            : ""
    property string videoLink           : ""
    property int    indexID
    property string entryId             : ""
    property alias  filePath            : downloadButton.filePath

    property var    vcodec              : []
    property var    resolutionModel     : []
    property var    videoExts           : []
    property var    videoFormats        : []
    property var    sizeModel           : []
    // Position in videoFormats. videoFormats.length stands for "Audio only",
    // as saved by version 4.3.0, although the list shows that choice first.
    property int    videoIndex          : 0
    property string selectedVideoCodec  : ""

    property var    acodec              : []
    property var    audioExts           : []
    property var    audioFormats        : []
    property var    audioBitrate        : []
    property var    audioSizes          : []
    property alias  audioIndex          : audioPopup.index
    property string selectedAudioCodec  : ""

    property real   videoProgress       : 0
    property var    pythonInstance      : null

    readonly property bool hasVideoFormats: !!videoFormats && videoFormats.length > 0
    readonly property bool hasAudioFormats: !!audioFormats && audioFormats.length > 0
    readonly property bool audioOnly: hasVideoFormats && videoIndex >= videoFormats.length

    leadingActions: ListItemActions {
        actions: [
            Action {
                // Only the entry goes; its file stays in the Library.
                iconName: "delete"
                text: i18n.tr("Remove")
                enabled: !downloadButton.active
                onTriggered: downloadManager.removeEntry(mediaItem.entryId)
            }
        ]
    }

    Component.onCompleted: {
        downloadButton.progress = videoProgress;
        if (downloadManager.consumeAutoStart(videoLink)) {
            var options = getFormats();
            options["format"] = audioOnly ? "bestaudio/best" : "bestvideo+bestaudio/best";
            options["expectedSizes"] = [];
            downloadButton.start(options, true);
        }
    }

    // The video list starts with "Audio only", followed by the video formats.
    function videoLabels() {
        var labels = [i18n.tr("Audio only")];
        for (var i = 0; i < videoFormats.length; i++) {
            labels.push(Utils.shortResolution(resolutionModel[i]) + " · " + videoExts[i]);
        }
        return labels;
    }

    function videoDetails() {
        var details = [i18n.tr("No video, smaller file")];
        for (var i = 0; i < videoFormats.length; i++) {
            var size = Utils.formatBytes(sizeModel[i]);
            details.push((vcodec[i] || "") + (size ? " · " + size : ""));
        }
        return details;
    }

    function audioLabels() {
        var labels = [];
        for (var i = 0; i < audioFormats.length; i++) {
            labels.push((audioBitrate[i] ? i18n.tr("%1k").arg(audioBitrate[i]) + " · " : "") + audioExts[i]);
        }
        return labels;
    }

    function audioDetails() {
        var details = [];
        for (var i = 0; i < audioFormats.length; i++) {
            var size = Utils.formatBytes(audioSizes[i]);
            details.push((acodec[i] || "") + (size ? " · " + size : ""));
        }
        return details;
    }

    function saveEntryMetadata() {
        if (entryId === "") {
            console.log("[MediaItem] No entryId, skipping save");
            return;
        }

        var currentVideoCodec = (vcodec && videoIndex >= 0 && videoIndex < vcodec.length) ? vcodec[videoIndex] : '';
        var currentAudioCodec = (acodec && audioIndex >= 0 && audioIndex < acodec.length) ? acodec[audioIndex] : '';

        // The model is what gets written on exit, so it has to stay current too.
        downloadManager.updateEntry(entryId, {
            vVideoProgress: downloadButton.progress,
            vVideoIndex: videoIndex,
            vAudioIndex: audioIndex,
            selectedVideoCodec: currentVideoCodec,
            selectedAudioCodec: currentAudioCodec,
            vFilePath: filePath
        });

        var entryData = {
            entryId: entryId,
            vTitle: videoTitle,
            vThumbnail: thumbnail,
            vDuration: duration,
            vID: videoLink,
            vCodec: JSON.stringify(vcodec || []),
            vResolutions: JSON.stringify(resolutionModel || []),
            vVideoExts: JSON.stringify(videoExts || []),
            vVideoFormats: JSON.stringify(videoFormats || []),
            vVideoProgress: downloadButton.progress,
            aCodec: JSON.stringify(acodec || []),
            vAudioExts: JSON.stringify(audioExts || []),
            vAudioFormats: JSON.stringify(audioFormats || []),
            vABR: JSON.stringify(audioBitrate || []),
            vAudioSizes: JSON.stringify(audioSizes || []),
            vVideoIndex: parseInt(videoIndex) || 0,
            vAudioIndex: parseInt(audioIndex) || 0,
            selectedVideoCodec: currentVideoCodec,
            selectedAudioCodec: currentAudioCodec,
            vSizeModel: JSON.stringify(sizeModel || []),
            vIndex: parseInt(indexID) || 0,
            vFilePath: filePath,
            timestamp: Date.now()
        };

        if (pythonInstance) {
            pythonInstance.call('storage_manager.save_single_entry', [entryData], function(result) {
                console.log('[MediaItem] Entry saved:', entryId);
            });
        } else {
            console.log('[MediaItem] ERROR: Python instance not provided');
        }
    }

    // Sites such as SoundCloud offer audio only, and some report no codec
    // details at all. Ask for what exists and let yt-dlp pick when nothing does.
    function getFormats() {
        var parts = [];
        // Expected sizes in the same order, to combine the progress of the streams.
        var sizes = [];
        if (hasAudioFormats) {
            parts.push(audioFormats[audioPopup.index]);
            sizes.push(audioSizes[audioPopup.index] || 0);
        }
        if (hasVideoFormats && !audioOnly) {
            parts.push(videoFormats[videoIndex]);
            sizes.push(sizeModel[videoIndex] || 0);
        }

        var jsonObject = {
            "format": parts.length > 0 ? parts.join("+") : "best",
            "expectedSizes": sizes,
            "indexID": indexID
        };

        if (audioOnly) {
            // Store the audio in its own audio file type, such as .m4a or .opus.
            // Sites without a separate audio stream get it taken out of the
            // video. Subtitles have nothing to go with.
            jsonObject["extractAudio"] = true;
            if (!hasAudioFormats) {
                jsonObject["format"] = "best";
            }
            return jsonObject;
        }

        if (generalSettings.downloadSubtitle) {
            jsonObject["subtitle"] = true;
            if (videoExts && videoExts[videoIndex] == "mp4") {
                jsonObject["strConvert"] = true;
            }
            if (generalSettings.embeddedSubtitle) {
                jsonObject["embedded"] = true;
            }
        }

        if (generalSettings.downloadCaption) {
            jsonObject["caption"] = true;
        }

        return jsonObject;
    }

    function formatChosen() {
        // A saved file no longer matches the choice, so offer downloading again.
        filePath = "";
        downloadButton.progress = 0;
        downloadButton.downloadState = "idle";
        saveEntryMetadata();
    }

    function statusText() {
        switch (downloadButton.downloadState) {
        case "starting":
            return i18n.tr("Starting…");
        case "downloading":
            return i18n.tr("Downloading %1%").arg(Math.round(downloadButton.progress * 100));
        case "processing":
            return i18n.tr("Finishing up…");
        case "retrying":
            return i18n.tr("Connection lost, trying again (%1 of %2)…")
                       .arg(downloadButton.attempt).arg(downloadButton.attempts);
        case "failed":
            return i18n.tr("Download failed");
        }
        return filePath !== "" ? i18n.tr("Saved in Library") : i18n.tr("Ready to download");
    }

    Column {
        id: content
        anchors {
            top: parent.top
            topMargin: units.gu(1.5)
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }
        spacing: units.gu(1.25)

        Row {
            width: parent.width
            spacing: units.gu(1.5)

            ThumbnailImage {
                id: thumbnailContainer
                width: units.gu(14)
                height: units.gu(8)
                thumbnailUrl: mediaItem.thumbnail

                Rectangle {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        margins: units.gu(0.5)
                    }
                    visible: mediaItem.duration !== "" && mediaItem.duration !== "00:00"
                    width: durationLabel.width + units.gu(1)
                    height: durationLabel.height + units.gu(0.25)
                    radius: units.dp(3)
                    color: "#b0000000"

                    Label {
                        id: durationLabel
                        anchors.centerIn: parent
                        text: mediaItem.duration
                        textSize: Label.XSmall
                        color: "white"
                    }
                }
            }

            Column {
                width: parent.width - thumbnailContainer.width - parent.spacing
                spacing: units.gu(0.5)

                Label {
                    id: titleBox
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    textSize: Label.Small
                    text: mediaItem.statusText()
                    color: downloadButton.downloadState === "failed"
                           ? theme.palette.normal.negative
                           : theme.palette.normal.backgroundSecondaryText
                }
            }
        }

        ProgressBar {
            width: parent.width
            height: units.dp(3)
            visible: downloadButton.active
            showProgressPercentage: false
            indeterminate: downloadButton.downloadState !== "downloading"
            value: downloadButton.progress
        }

        GridLayout {
            width: parent.width
            // On narrow phones the button moves below, so format names stay readable.
            columns: width < units.gu(38) ? 2 : 3
            columnSpacing: units.gu(1)
            rowSpacing: units.gu(1)

            CustomComboPopup {
                id: resolutionPopup
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: units.gu(10)
                visible: mediaItem.hasVideoFormats
                enabled: !downloadButton.active
                heading: i18n.tr("Video quality")
                labels: mediaItem.videoLabels()
                details: mediaItem.videoDetails()
                index: mediaItem.audioOnly ? 0 : mediaItem.videoIndex + 1
                onActivated: {
                    mediaItem.videoIndex = choice === 0 ? mediaItem.videoFormats.length : choice - 1;
                    mediaItem.formatChosen();
                }
            }

            CustomComboPopup {
                id: audioPopup
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: units.gu(10)
                visible: mediaItem.hasAudioFormats
                enabled: !downloadButton.active
                heading: i18n.tr("Audio quality")
                labels: mediaItem.audioLabels()
                details: mediaItem.audioDetails()
                onActivated: mediaItem.formatChosen()
            }

            DownloadButton {
                id: downloadButton
                objectName: "downloadButton"
                Layout.preferredWidth: units.gu(11)
                Layout.columnSpan: parent.columns === 2 ? 2 : 1
                Layout.fillWidth: parent.columns === 2 || (!mediaItem.hasVideoFormats && !mediaItem.hasAudioFormats)
                pythonInstance: mediaItem.pythonInstance
                videoUrl: mediaItem.videoLink
                optionsProvider: function() { return mediaItem.getFormats(); }
                dialogs: mediaDialogs

                onActiveChanged: downloadManager.activeDownloads += active ? 1 : -1
                onDownloadStarted: mediaItem.saveEntryMetadata()
                onDownloadFinished: {
                    mediaItem.saveEntryMetadata();
                    downloadManager.libraryChanged();
                    root.recordDownload();
                    if (generalSettings.askWhereToSave && !downloadButton.quiet) {
                        root.openContentHubExport(filePath);
                    }
                }
                onDownloadError: mediaItem.saveEntryMetadata()
                onSaveRequested: root.openContentHubExport(filePath)
            }
        }
    }

    MediaItemDialogs {
        id: mediaDialogs
    }

    // A file deleted from the library can no longer be saved from here.
    Connections {
        target: downloadManager
        onFileRemoved: {
            if (path === mediaItem.filePath) {
                mediaItem.formatChosen();
            }
        }
    }
}
