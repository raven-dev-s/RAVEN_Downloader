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

/**
 * Heading above a group of list rows.
 */
Item {
    property alias text: label.text

    anchors {
        left: parent.left
        right: parent.right
    }
    height: label.height + units.gu(3)

    Label {
        id: label
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
            bottomMargin: units.gu(0.75)
        }
        wrapMode: Text.WordWrap
        textSize: Label.Small
        font.weight: Font.Medium
        color: theme.palette.normal.backgroundSecondaryText
    }
}
