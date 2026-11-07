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
import Qt.labs.settings 1.0
import Lomiri.Components 1.3
import UserMetrics 0.1

/**
 * Shows how many downloads finished today in the lock screen's infographic,
 * for example "5 videos downloaded today". The infographic keeps one value
 * per day, so the count starts again each day.
 */
Item {
    id: downloadMetric

    Settings {
        id: stored
        category: "UserMetrics"

        // The day the count belongs to, as yyyy-MM-dd.
        property string day: ""
        property int count: 0
    }

    function today() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function countToday() {
        return stored.day === today() ? stored.count : 0;
    }

    // The infographic puts the number in place of %1.
    function formatFor(count) {
        return i18n.tr("%1 video downloaded today", "%1 videos downloaded today", count);
    }

    function recordDownload() {
        var count = countToday() + 1;
        stored.day = today();
        stored.count = count;
        metric.format = formatFor(count);
        metric.update(count);
    }

    Metric {
        id: metric
        name: "downloads"
        domain: "raven.downloader.shohag"
        format: downloadMetric.formatFor(downloadMetric.countToday())
        emptyFormat: i18n.tr("No videos downloaded today")
    }
}
