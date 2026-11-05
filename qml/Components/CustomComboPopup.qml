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
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3

/**
 * A button showing the current choice, opening a list of all choices.
 */
Button {
    id: dropdown

    // Short text per choice, shown on the button and in the list.
    property var    labels     : []
    // Optional second line per choice in the list.
    property var    details    : []
    property string heading
    property int    index      : 0

    // Emitted only when the user makes a choice, not when index is restored.
    signal activated(int choice)

    color: theme.palette.normal.foreground
    text: (labels && index >= 0 && index < labels.length) ? labels[index] : heading
    onClicked: PopupUtils.open(comboSelectorDialog)

    Component {
        id: comboSelectorDialog

        Dialog {
            id: dialogue
            title: dropdown.heading
            Keys.onEscapePressed: PopupUtils.close(dialogue)

            Flickable {
                width: parent.width
                height: Math.min(contentHeight, units.gu(40))
                contentHeight: column.height
                clip: true

                Column {
                    id: column
                    width: parent.width

                    Repeater {
                        model: dropdown.labels

                        delegate: ListItem {
                            width: parent.width
                            height: choiceLayout.height + divider.height
                            divider.colorFrom: theme.palette.normal.base
                            divider.colorTo: theme.palette.normal.base
                            color: "transparent"
                            onClicked: {
                                dropdown.index = model.index;
                                dropdown.activated(model.index);
                                PopupUtils.close(dialogue);
                            }

                            ListItemLayout {
                                id: choiceLayout
                                padding {
                                    leading: units.gu(1)
                                    trailing: units.gu(1)
                                }
                                title.text: modelData
                                title.font.weight: model.index === dropdown.index ? Font.Medium : Font.Normal
                                subtitle.text: (dropdown.details && dropdown.details[model.index]) || ""

                                Icon {
                                    SlotsLayout.position: SlotsLayout.Trailing
                                    width: units.gu(2.5)
                                    height: width
                                    name: "tick"
                                    color: theme.palette.normal.positive
                                    opacity: model.index === dropdown.index ? 1 : 0
                                }
                            }
                        }
                    }
                }
            }

            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }
        }
    }
}
