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
import io.thp.pyotherside 1.4

/**
 * DownloadItemManager - Manages download items model and operations
 * Handles adding, removing, and persisting download history
 */
Item {
    id: root
    
    property alias model: downloadItemsModel
    readonly property alias count: downloadItemsModel.count
    property var pythonInstance
    // Downloads currently running in list items.
    property int activeDownloads: 0
    // New videos start downloading as soon as they are added.
    property bool autoStartNewItems: false
    // New videos start out with "Audio only" chosen instead of a video quality.
    property bool audioOnlyNewItems: false
    
    // Download ids stay unique for the session even after entries are deleted.
    property int _nextIndex: 0
    // Links of videos just added that still have to start downloading. History
    // entries load through the same list items and must never start by themselves.
    property var _pendingAutoStart: ({})
    
    ListModel {
        id: downloadItemsModel
    }
    
    /**
     * Add video format data to model
     */
    function addVideo(formats) {
        console.log("[DownloadItemManager] Adding video: " + formats.title);
        
        // Fetching the same video again brings its existing entry back to the top.
        for (var i = 0; i < downloadItemsModel.count; i++) {
            if (formats.videoUrl && downloadItemsModel.get(i).vID === formats.videoUrl) {
                if (i > 0) {
                    downloadItemsModel.move(i, 0, 1);
                }
                return;
            }
        }
        
        if (autoStartNewItems && formats.videoUrl) {
            _pendingAutoStart[formats.videoUrl] = true;
        }
        
        var videoFormatIds = formats.videoFormatIds || [];
        var audioFormatIds = formats.audioFormatIds || [];
        
        downloadItemsModel.append({
            entryId: formats.entryId || '',
            vTitle: formats.title || '',
            vThumbnail: formats.thumbnail || '',
            vDuration: formats.duration || '',
            vID: formats.videoUrl || '',

            vCodec: JSON.stringify(formats.vcodeces || []),
            vResolutions: JSON.stringify(formats.notes || []),
            vVideoExts: JSON.stringify(formats.videoExtensions || []),
            vVideoFormats: JSON.stringify(formats.videoFormatIds || []),
            vVideoProgress: 0,

            aCodec: JSON.stringify(formats.acodeces || []),
            vAudioExts: JSON.stringify(formats.audioExtensions || []),
            vAudioFormats: JSON.stringify(formats.audioFormatIds || []),
            vABR: JSON.stringify(formats.audioBitrates || []),
            vAudioSizes: JSON.stringify(formats.audioSizes || []),

            // yt-dlp lists formats from worst to best. Start with the best.
            // The position after the last video format means "Audio only".
            vVideoIndex: audioOnlyNewItems ? videoFormatIds.length : Math.max(0, videoFormatIds.length - 1),
            vAudioIndex: Math.max(0, audioFormatIds.length - 1),
            selectedVideoCodec: '',
            selectedAudioCodec: '',

            vSizeModel: JSON.stringify(formats.filesizes || []),
            vIndex: _nextIndex++,
            vFilePath: '',
            timestamp: Date.now()
        });
        
        if (downloadItemsModel.count > 1) {
            downloadItemsModel.move(0, 1, downloadItemsModel.count - 1);
        }
        
        saveHistory();
    }
    
    /**
     * Tell a new list item whether it has to start downloading right away
     */
    function consumeAutoStart(videoUrl) {
        var pending = _pendingAutoStart[videoUrl] === true;
        delete _pendingAutoStart[videoUrl];
        return pending;
    }
    
    /**
     * Update properties of one entry
     */
    function updateEntry(entryId, properties) {
        for (var i = 0; i < downloadItemsModel.count; i++) {
            if (downloadItemsModel.get(i).entryId === entryId) {
                downloadItemsModel.set(i, properties);
                return;
            }
        }
    }
    
    /**
     * Delete one entry and its downloaded file
     */
    function removeEntry(entryId) {
        for (var i = 0; i < downloadItemsModel.count; i++) {
            if (downloadItemsModel.get(i).entryId === entryId) {
                downloadItemsModel.remove(i);
                break;
            }
        }
        pythonInstance.call('storage_manager.delete_entry', [entryId], function() {});
    }
    
    /**
     * Save history to storage
     */
    function saveHistory() {
        var datamodel = [];
        for (var i = 0; i < downloadItemsModel.count; ++i) {
            datamodel.push(downloadItemsModel.get(i));
        }
        
        console.log('[DownloadItemManager] Saving ' + datamodel.length + ' items to storage');
        
        pythonInstance.call('download_manager.save_list_model_data', [datamodel], function(result) {
            console.log('[DownloadItemManager] History saved: ' + result);
        });
    }
    
    /**
     * Load history from storage
     */
    function loadHistory(callback) {
        pythonInstance.call('download_manager.load_list_model_data', [], function(history) {
            console.log('[DownloadItemManager] Loaded ' + history.length + ' items from history');
            
            if (history && history.length > 0) {
                for (var i = 0; i < history.length; i++) {
                    var item = history[i];
                    downloadItemsModel.append(item);
                    _nextIndex = Math.max(_nextIndex, (item.vIndex || 0) + 1);
                }
            }
            
            if (callback) {
                callback(history.length > 0);
            }
        });
    }
    
    /**
     * Reload history from storage (for pull-to-refresh)
     */
    function reloadHistory(callback) {
        // Clear current model
        downloadItemsModel.clear();
        
        // Load fresh data from storage
        loadHistory(function(hasHistory) {
            if (callback) {
                callback(hasHistory);
            }
        });
    }
    
    /**
     * Clear all items
     */
    function clear() {
        downloadItemsModel.clear();
        saveHistory();
    }
}
