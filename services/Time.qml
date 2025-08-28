pragma Singleton

import QtQuick
import QtNetwork
import Quickshell

Singleton {
    property alias enabled: timer.running
    readonly property date date: _currentDate
    readonly property int hours: _currentDate.getHours()
    readonly property int minutes: _currentDate.getMinutes()
    readonly property int seconds: _currentDate.getSeconds()

    // Private properties
    property date _currentDate: new Date()
    property int _serverOffset: 0 // Offset between server time and local time in milliseconds
    property bool _syncInProgress: false

    // Update interval in milliseconds (sync every 5 minutes)
    property int syncInterval: 300000

    function format(fmt: string): string {
        return Qt.formatDateTime(_currentDate, fmt);
    }

    // Since we're using America/Chicago API, we get Central Time directly
    function toCentralTime(serverDate) {
        // The worldtimeapi.org/api/timezone/America/Chicago already returns Central Time
        // so we don't need to do any timezone conversion
        return serverDate;
    }

    // Sync with NTP server via world time API
    function syncTime() {
        if (_syncInProgress) return;

        _syncInProgress = true;

        var xhr = new XMLHttpRequest();
        xhr.timeout = 10000; // 10 second timeout

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                _syncInProgress = false;

                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        // The API returns datetime in the requested timezone (America/Chicago)
                        var serverTime = new Date(response.datetime);
                        var localTime = new Date();

                        // Calculate offset between server and local time
                        _serverOffset = serverTime.getTime() - localTime.getTime();

                        // Update current time
                        updateTime();

                        console.log("Time synced successfully with offset:", _serverOffset);
                    } catch (e) {
                        console.log("Failed to parse time server response:", e);
                        // Fallback to system time
                        _serverOffset = 0;
                        updateTime();
                    }
                } else {
                    console.log("Failed to sync time, status:", xhr.status);
                    // Fallback to system time
                    _serverOffset = 0;
                    updateTime();
                }
            }
        };

        xhr.onerror = function() {
            _syncInProgress = false;
            console.log("Network error while syncing time");
            // Fallback to system time
            _serverOffset = 0;
            updateTime();
        };

        xhr.ontimeout = function() {
            _syncInProgress = false;
            console.log("Time sync request timed out");
            // Fallback to system time
            _serverOffset = 0;
            updateTime();
        };

        // Use worldtimeapi.org for accurate time (alternative to Google NTP)
        // This provides JSON response with timezone info
        xhr.open("GET", "https://worldtimeapi.org/api/timezone/America/Chicago");
        xhr.send();
    }

    // Alternative sync method using a different time API
    function syncTimeAlternative() {
        if (_syncInProgress) return;

        _syncInProgress = true;

        var xhr = new XMLHttpRequest();
        xhr.timeout = 10000;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                _syncInProgress = false;

                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        // time.is API returns current_time in milliseconds
                        var serverTime = new Date(response.current_time * 1000);
                        var localTime = new Date();

                        _serverOffset = serverTime.getTime() - localTime.getTime();
                        updateTime();

                        console.log("Time synced successfully (alternative) with offset:", _serverOffset);
                    } catch (e) {
                        console.log("Failed to parse alternative time server response:", e);
                        // Try primary method
                        syncTime();
                    }
                } else {
                    // Try primary method
                    syncTime();
                }
            }
        };

        xhr.onerror = function() {
            _syncInProgress = false;
            // Try primary method
            syncTime();
        };

        // Alternative time API
        xhr.open("GET", "http://time.jsontest.com/");
        xhr.send();
    }

    function updateTime() {
        var now = new Date();
        var correctedTime = new Date(now.getTime() + _serverOffset);
        _currentDate = correctedTime; // No timezone conversion needed since offset is already in Central Time
    }

    // Timer for regular updates (every second)
    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateTime()
    }

    // Timer for periodic sync with server
    Timer {
        id: syncTimer
        interval: syncInterval
        running: timer.running
        repeat: true
        onTriggered: syncTime()
    }

    // Initialize - sync time immediately on startup
    Component.onCompleted: {
        syncTime();
    }
}
