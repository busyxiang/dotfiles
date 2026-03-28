pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<var> history: []
    property list<var> popups: []
    property int unreadCount: 0
    property bool historyVisible: false
    property var historyScreen: null
    property bool dndEnabled: false
    property var exitingIds: []
    property var dismissedIds: []

    function startDismiss(id) {
        if (exitingIds.indexOf(id) >= 0) return
        exitingIds = exitingIds.concat([id])
    }

    function finishDismiss(id, shouldRemove) {
        exitingIds = exitingIds.filter(eid => eid !== id)
        dismissedIds = dismissedIds.concat([id])
        if (shouldRemove) {
            history = history.filter(n => n.id !== id)
            if (unreadCount > 0) unreadCount--
        }
        // Clean up array only when ALL popups are dismissed
        if (popups.every(p => dismissedIds.indexOf(p.id) >= 0)) {
            popups = []
            dismissedIds = []
            exitingIds = []
        }
    }

    // Safety: clean up stuck popups where all are exiting/dismissed but finishDismiss was never called
    Timer {
        interval: 1000
        running: root.popups.length > 0
        repeat: true
        onTriggered: {
            if (root.popups.length === 0) return
            var allHandled = root.popups.every(function(p) {
                return root.exitingIds.indexOf(p.id) >= 0 || root.dismissedIds.indexOf(p.id) >= 0
            })
            if (allHandled) {
                root.popups = []
                root.exitingIds = []
                root.dismissedIds = []
            }
        }
    }

    // Auto-remove hasTimeout notifications from history after they expire
    Timer {
        interval: 100
        running: root.history.length > 0
        repeat: true
        onTriggered: {
            var now = Date.now()
            var removed = 0
            var newHistory = root.history.filter(function(n) {
                if (n.hasTimeout && !n.persistent) {
                    var elapsed = now - n.time.getTime()
                    if (elapsed >= n.timeout) {
                        removed++
                        return false
                    }
                }
                return true
            })
            if (removed > 0) {
                root.history = newHistory
                root.unreadCount = Math.max(0, root.unreadCount - removed)
            }
        }
    }

    function clearHistory() {
        // Dismiss all tracked notifications so they expire properly
        for (var i = 0; i < history.length; i++) {
            if (history[i].notifObj)
                history[i].notifObj.dismiss()
        }
        history = []
        popups = []
        exitingIds = []
        dismissedIds = []
        unreadCount = 0
    }

    function invokeAction(notifData, actionIndex) {
        var actions = notifData.actions
        if (actions && actions.length > actionIndex) {
            var action = actions[actionIndex]
            if (action.actionObj && action.actionObj.invoke)
                action.actionObj.invoke()
        }
    }

    function invokeDefault(notifData) {
        if (notifData.defaultAction && notifData.defaultAction.invoke)
            notifData.defaultAction.invoke()
    }

    function dismissNotification(index) {
        var copy = history.slice()
        var removed = copy.splice(index, 1)
        if (removed.length > 0 && removed[0].notifObj)
            removed[0].notifObj.dismiss()
        history = copy
    }

    function dismissPopup(index) {
        var copy = popups.slice()
        copy.splice(index, 1)
        popups = copy
    }

    function removeById(id) {
        var hadInHistory = history.some(n => n.id === id)
        history = history.filter(n => n.id !== id)
        popups = popups.filter(n => n.id !== id)
        exitingIds = exitingIds.filter(eid => eid !== id)
        dismissedIds = dismissedIds.filter(did => did !== id)
        if (hadInHistory && unreadCount > 0)
            unreadCount--
    }

    function dismissPopupById(id) {
        popups = popups.filter(n => n.id !== id)
        exitingIds = exitingIds.filter(eid => eid !== id)
        dismissedIds = dismissedIds.filter(did => did !== id)
    }

    function dismissGroup(appName) {
        var toRemove = history.filter(n => (n.appName || "Notification") === appName)
        var removeIds = toRemove.map(n => n.id)
        for (var i = 0; i < toRemove.length; i++) {
            if (toRemove[i].notifObj)
                toRemove[i].notifObj.dismiss()
        }
        history = history.filter(n => (n.appName || "Notification") !== appName)
        popups = popups.filter(n => (n.appName || "Notification") !== appName)
        exitingIds = exitingIds.filter(eid => removeIds.indexOf(eid) < 0)
        dismissedIds = dismissedIds.filter(did => removeIds.indexOf(did) < 0)
        if (unreadCount > 0)
            unreadCount = Math.max(0, unreadCount - toRemove.length)
    }

    // Build grouped history: array of { appName, notifications: [...], collapsed: bool }
    function getGroupedHistory() {
        var groups = []
        var groupMap = {}
        for (var i = 0; i < history.length; i++) {
            var n = history[i]
            var app = n.appName || "Notification"
            if (!(app in groupMap)) {
                var group = { appName: app, notifications: [], collapsed: false }
                groupMap[app] = group
                groups.push(group)
            }
            groupMap[app].notifications.push(n)
        }
        return groups
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true

            var isCritical = (notification.urgency === NotificationUrgency.Critical)
            var isResident = notification.resident || false

            // DND blocks non-critical notifications
            if (root.dndEnabled && !isCritical) return

            var rawTimeout = notification.expireTimeout
            var hasTimeout = rawTimeout > 0
            var timeout = hasTimeout ? rawTimeout : 5000

            // Persistent: resident notifications stay in history, but popups always auto-dismiss
            var persistent = isResident

            var notifId = Date.now()

            // Serialize actions to plain objects so properties survive storage
            // Separate "default" action (invoked by clicking notification body)
            var rawActions = notification.actions || []
            var serializedActions = []
            var defaultAction = null
            for (var i = 0; i < rawActions.length; i++) {
                if (rawActions[i].identifier === "default") {
                    defaultAction = rawActions[i]
                    continue
                }
                serializedActions.push({
                    text: rawActions[i].text || rawActions[i].identifier || "",
                    actionObj: rawActions[i]
                })
            }

            var notifData = {
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                urgency: notification.urgency,
                isCritical: isCritical,
                time: new Date(),
                id: notifId,
                timeout: timeout,
                hasTimeout: hasTimeout,
                persistent: persistent,
                resident: isResident,
                image: notification.image || "",
                appIcon: notification.appIcon || "",
                notifObj: notification,
                defaultAction: defaultAction,
                actions: serializedActions
            }

            // Listen for the notification's closed signal
            notification.closed.connect(reason => {
                root.removeById(notifId)
            })

            // Add to history
            var histCopy = root.history.slice()
            histCopy.unshift(notifData)
            if (histCopy.length > 50) histCopy.pop()
            root.history = histCopy

            // Add to popups (filter out dismissed items first)
            var popCopy = root.popups.filter(p => root.dismissedIds.indexOf(p.id) < 0)
            root.dismissedIds = []
            popCopy.unshift(notifData)
            if (popCopy.length > 3) popCopy.pop()
            root.popups = popCopy

            root.unreadCount++
        }
    }
}
