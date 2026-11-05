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
 * A settings row. The whole row is the touch target and long labels wrap.
 */
ListItem {
    id: settingsRow

    property string labelText: ""
    property string descriptionText: ""
    property bool checked: false
    property bool isEnabled: true

    signal toggled(bool checked)

    anchors {
        left: parent.left
        right: parent.right
    }
    height: layout.height + divider.height
    enabled: isEnabled
    onClicked: toggled(!checked)

    ListItemLayout {
        id: layout
        title.text: settingsRow.labelText
        title.maximumLineCount: 2
        title.wrapMode: Text.WordWrap
        subtitle.text: settingsRow.descriptionText
        subtitle.maximumLineCount: 3
        subtitle.wrapMode: Text.WordWrap

        Switch {
            id: rowSwitch
            SlotsLayout.position: SlotsLayout.Trailing
            enabled: settingsRow.isEnabled
            onTriggered: settingsRow.toggled(!settingsRow.checked)
        }
    }

    // The switch flips itself when tapped, which would end a plain property
    // binding. Keep it following the stored setting either way.
    Binding {
        target: rowSwitch
        property: "checked"
        value: settingsRow.checked
    }
}
