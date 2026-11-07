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
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3

/**
 * A video thumbnail with rounded corners. Without a thumbnail it shows a
 * neutral, theme-colored tile instead of a fixed light image, which stood
 * out as a bright box in the dark theme.
 */
Image {
    id: thumbnailImage

    property string thumbnailUrl: ""
    property real cornerRadius: units.gu(1)

    fillMode: Image.PreserveAspectCrop
    source: sourceFor(thumbnailUrl)

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Item {
            width: thumbnailImage.width
            height: thumbnailImage.height
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: thumbnailImage.cornerRadius
            }
        }
    }

    function sourceFor(url) {
        if (!url) {
            return "";
        }
        if (url.startsWith("/")) {
            return "file://" + url;
        }
        if (url.startsWith("file://") || url.startsWith("http://") || url.startsWith("https://")) {
            return url;
        }
        console.error("[ThumbnailImage] Invalid URL format:", url);
        return "";
    }

    // Shown until a thumbnail has loaded, and whenever there is none.
    Rectangle {
        anchors.fill: parent
        visible: thumbnailImage.status !== Image.Ready
        color: theme.palette.normal.base

        Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.4
            height: width
            name: "stock_video"
            color: theme.palette.normal.backgroundSecondaryText
        }
    }
}
