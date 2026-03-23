pragma Singleton
pragma ComponentBehavior: Bound

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

    function clearHistory() {
        // Dismiss all tracked notifications so they expire properly
        for (var i = 0; i < history.length; i++) {
            if (history[i].notifObj)
                history[i].notifObj.dismiss()
        }
        history = []
        popups = []
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
        if (hadInHistory && unreadCount > 0)
            unreadCount--
    }

    function dismissPopupById(id) {
        popups = popups.filter(n => n.id !== id)
    }

    function dismissGroup(appName) {
        var toRemove = history.filter(n => (n.appName || "Notification") === appName)
        for (var i = 0; i < toRemove.length; i++) {
            if (toRemove[i].notifObj)
                toRemove[i].notifObj.dismiss()
        }
        history = history.filter(n => (n.appName || "Notification") !== appName)
        popups = popups.filter(n => (n.appName || "Notification") !== appName)
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
            // Filter out "default" action (invoked by clicking the notification body)
            var rawActions = notification.actions || []
            var serializedActions = []
            for (var i = 0; i < rawActions.length; i++) {
                if (rawActions[i].identifier === "default") continue
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

            // Add to popups
            var popCopy = root.popups.slice()
            popCopy.unshift(notifData)
            if (popCopy.length > 3) popCopy.pop()
            root.popups = popCopy

            root.unreadCount++
        }
    }
}
