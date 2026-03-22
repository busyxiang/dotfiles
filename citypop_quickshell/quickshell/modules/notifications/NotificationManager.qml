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

    function toggleHistory() {
        historyVisible = !historyVisible
    }

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
        if (actions && actions.length > actionIndex)
            actions[actionIndex].invoke()
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

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            if (root.dndEnabled) return
            notification.tracked = true

            var rawTimeout = notification.expireTimeout
            var hasTimeout = rawTimeout > 0
            var timeout = hasTimeout ? rawTimeout : 5000

            var notifId = Date.now()

            var notifData = {
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                urgency: notification.urgency,
                time: new Date(),
                id: notifId,
                timeout: timeout,
                hasTimeout: hasTimeout,
                image: notification.image || "",
                appIcon: notification.appIcon || "",
                notifObj: notification,
                actions: notification.actions || []
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
