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

import "Components"

Page {
    id: settingsPageRoot

    property var pythonInstance
    // The application's single settings object, so that changes apply at once.
    property var settings
    property int activeDownloads: 0
    property int historyCount: 0

    // Theme names by position in the selector. An empty name follows the system.
    readonly property var themeNames: [
        "",
        "Lomiri.Components.Themes.Ambiance",
        "Lomiri.Components.Themes.SuruDark"
    ]

    header: PageHeader {
        title: i18n.tr("Settings")
    }

    Flickable {
        id: settingsScroll
        clip: true
        anchors {
            top: settingsPageRoot.header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: settingsColumn.height + units.gu(2)

        Column {
            id: settingsColumn
            width: settingsScroll.width

            SectionLabel {
                text: i18n.tr("Downloads")
            }

            SettingsCheckbox {
                labelText: i18n.tr("Download automatically")
                descriptionText: i18n.tr("Start in the best quality as soon as a video is added")
                checked: settings.autoDownload
                onToggled: settings.autoDownload = checked
            }

            SettingsCheckbox {
                labelText: i18n.tr("Audio only by default")
                descriptionText: i18n.tr("New videos start with no video. You can still change this for each one.")
                checked: settings.audioOnlyDefault
                onToggled: settings.audioOnlyDefault = checked
            }

            SectionLabel {
                text: i18n.tr("Subtitles")
            }

            SettingsCheckbox {
                labelText: i18n.tr("Download subtitles")
                descriptionText: i18n.tr("When the video provides them")
                checked: settings.downloadSubtitle
                onToggled: {
                    settings.downloadSubtitle = checked;
                    settings.downloadCaption = checked;
                    settings.embeddedSubtitle = checked;
                }
            }

            SettingsCheckbox {
                labelText: i18n.tr("Use automatic captions")
                descriptionText: i18n.tr("When no subtitles are available")
                checked: settings.downloadCaption
                isEnabled: settings.downloadSubtitle
                onToggled: settings.downloadCaption = checked
            }

            SettingsCheckbox {
                labelText: i18n.tr("Embed subtitles in the file")
                checked: settings.embeddedSubtitle
                isEnabled: settings.downloadSubtitle
                onToggled: settings.embeddedSubtitle = checked
            }

            SectionLabel {
                text: i18n.tr("Appearance")
            }

            Repeater {
                model: [
                    i18n.tr("Follow system"),
                    i18n.tr("Light"),
                    i18n.tr("Dark")
                ]

                delegate: ListItem {
                    width: settingsColumn.width
                    height: themeLayout.height + divider.height
                    onClicked: settings.themeName = themeNames[model.index]

                    ListItemLayout {
                        id: themeLayout
                        title.text: modelData

                        Icon {
                            SlotsLayout.position: SlotsLayout.Trailing
                            width: units.gu(2.5)
                            height: width
                            name: "tick"
                            color: theme.palette.normal.positive
                            opacity: Math.max(0, themeNames.indexOf(settings.themeName)) === model.index ? 1 : 0
                        }
                    }
                }
            }

            SectionLabel {
                text: i18n.tr("Storage")
            }

            ListItem {
                width: parent.width
                height: clearLayout.height + divider.height
                enabled: settingsPageRoot.historyCount > 0 && settingsPageRoot.activeDownloads === 0
                onClicked: PopupUtils.open(clearConfirmation, settingsPageRoot)

                ListItemLayout {
                    id: clearLayout
                    title.text: i18n.tr("Clear all history")
                    title.color: enabled ? theme.palette.normal.negative : theme.palette.disabled.backgroundText
                    subtitle.text: settingsPageRoot.activeDownloads > 0
                                   ? i18n.tr("Available when downloads have finished")
                                   : i18n.tr("Removes the list and files you have not saved")

                    Icon {
                        SlotsLayout.position: SlotsLayout.Trailing
                        width: units.gu(2.5)
                        height: width
                        name: "delete"
                        color: clearLayout.title.color
                    }
                }
            }
        }
    }

    Component {
        id: clearConfirmation

        Dialog {
            id: clearDialog
            title: i18n.tr("Clear all history?")
            text: i18n.tr("This removes the whole list and any downloaded files you have not saved elsewhere. It cannot be undone.")

            Button {
                text: i18n.tr("Clear")
                color: theme.palette.normal.negative
                onClicked: {
                    pythonInstance.call('storage_manager.clear_download_history', [], function(result) {});
                    PopupUtils.close(clearDialog);
                }
            }

            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(clearDialog)
            }
        }
    }
}
