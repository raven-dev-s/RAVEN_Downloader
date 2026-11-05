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
import QtQuick 2.7
import Lomiri.Components 1.3

/**
 * A row that opens an external link.
 */
ListItem {
    id: linkRow

    property string title: ""
    property string subtitle: ""
    property string link: ""
    property string iconName: ""

    anchors {
        left: parent.left
        right: parent.right
    }
    height: rowLayout.height + divider.height
    onClicked: Qt.openUrlExternally(link)

    ListItemLayout {
        id: rowLayout
        title.text: linkRow.title
        subtitle.text: linkRow.subtitle

        Icon {
            SlotsLayout.position: SlotsLayout.Leading
            width: units.gu(2.5)
            height: width
            visible: iconName !== ""
            name: iconName
            color: theme.palette.normal.backgroundSecondaryText
        }

        ProgressionSlot {}
    }
}
