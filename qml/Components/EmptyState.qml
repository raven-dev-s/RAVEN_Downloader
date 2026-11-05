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

Column {
    property string title: ""
    property string description: ""
    property string iconName: "save"

    spacing: units.gu(1.5)

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        width: units.gu(7)
        height: width
        name: iconName
        color: theme.palette.normal.base
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        textSize: Label.Large
        text: title
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: theme.palette.normal.backgroundSecondaryText
        text: description
    }
}
