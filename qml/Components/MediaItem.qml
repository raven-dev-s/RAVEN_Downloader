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
    property alias  videoIndex          : resolutionPopup.index
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
    // "Audio only" is listed after the last video format, so that the positions
    // of real formats stay the same in entries saved by earlier versions.
    readonly property bool audioOnly: hasVideoFormats && resolutionPopup.index >= videoFormats.length

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                enabled: !downloadButton.active
                onTriggered: downloadManager.removeEntry(mediaItem.entryId)
            }
        ]
    }

    Component.onCompleted: {
        downloadButton.progress = videoProgress;
        if (downloadManager.consumeAutoStart(videoLink)) {
            var options = getFormats();
            if (audioOnly) {
                options["format"] = "bestaudio/best";
                options["extractAudio"] = true;
            } else {
                options["format"] = "bestvideo+bestaudio/best";
            }
            downloadButton.start(options, true);
        }
    }

    function videoLabels() {
        var labels = [];
        for (var i = 0; i < videoFormats.length; i++) {
            labels.push(Utils.shortResolution(resolutionModel[i]) + " · " + videoExts[i]);
        }
        if (labels.length > 0) {
            labels.push(i18n.tr("Audio only"));
        }
        return labels;
    }

    function videoDetails() {
        var details = [];
        for (var i = 0; i < videoFormats.length; i++) {
            var size = Utils.formatBytes(sizeModel[i]);
            details.push((vcodec[i] || "") + (size ? " · " + size : ""));
        }
        if (details.length > 0) {
            details.push(i18n.tr("No video, smaller file"));
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
        if (hasAudioFormats) {
            parts.push(audioFormats[audioPopup.index]);
        }
        if (hasVideoFormats && !audioOnly) {
            parts.push(videoFormats[resolutionPopup.index]);
        }

        var jsonObject = {
            "format": parts.length > 0 ? parts.join("+") : "best",
            "indexID": indexID
        };

        if (audioOnly) {
            // Some sites have no separate audio stream. Take the audio out of
            // whatever they offer. Subtitles have nothing to go with either.
            if (!hasAudioFormats) {
                jsonObject["format"] = "best";
                jsonObject["extractAudio"] = true;
            }
            return jsonObject;
        }

        if (generalSettings.downloadSubtitle) {
            jsonObject["subtitle"] = true;
            if (videoExts && videoExts[resolutionPopup.index] == "mp4") {
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
        case "failed":
            return i18n.tr("Download failed");
        }
        return filePath !== "" ? i18n.tr("Downloaded") : i18n.tr("Ready to download");
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
                onActivated: mediaItem.formatChosen()
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
                onDownloadFinished: mediaItem.saveEntryMetadata()
                onDownloadError: mediaItem.saveEntryMetadata()
                onSaveRequested: root.openContentHubExport(filePath)
            }
        }
    }

    MediaItemDialogs {
        id: mediaDialogs
    }
}
