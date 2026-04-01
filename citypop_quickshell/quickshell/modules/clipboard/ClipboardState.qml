pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property var screen: null
    property real panelX: 0

    property var entries: []  // [{ id, text, isImage, imagePath }]
    property string searchQuery: ""
    property bool loading: false

    readonly property int entryCount: entries.length

    readonly property var filtered: {
        if (searchQuery === "") return entries
        var q = searchQuery.toLowerCase()
        return entries.filter(function(e) {
            if (e.isImage) return "image".indexOf(q) >= 0
            return e.text.toLowerCase().indexOf(q) >= 0
        })
    }

    // --- Fetch clipboard history ---
    function refresh(): void {
        if (loading) return
        loading = true
        listProc.running = true
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        property string _buf: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { listProc._buf = data }
        }
        onExited: (exitCode, exitStatus) => {
            var items = []
            var imgIds = []
            if (exitCode === 0 && listProc._buf.length > 0) {
                var lines = listProc._buf.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.length === 0) continue
                    var tabIdx = line.indexOf("\t")
                    if (tabIdx < 0) continue
                    var id = line.substring(0, tabIdx)
                    var content = line.substring(tabIdx + 1)
                    var isImage = content.indexOf("[[ binary data ") >= 0
                    items.push({
                        id: id,
                        text: isImage ? "" : content,
                        isImage: isImage,
                        imagePath: ""
                    })
                    if (isImage) imgIds.push(id)
                }
            }
            root.entries = items
            listProc._buf = ""

            // Decode image previews to temp files
            if (imgIds.length > 0) {
                var cmds = []
                for (var j = 0; j < imgIds.length; j++) {
                    cmds.push("cliphist decode '" + imgIds[j] + "' > '/tmp/cliphist_preview_" + imgIds[j] + ".png'")
                }
                imgDecodeProc.command = ["bash", "-c", cmds.join(" && ")]
                imgDecodeProc.running = true
            } else {
                root.loading = false
            }
        }
    }

    Process {
        id: imgDecodeProc
        onExited: {
            // Now that files exist on disk, set imagePath on image entries
            var updated = root.entries.slice()
            for (var i = 0; i < updated.length; i++) {
                if (updated[i].isImage && updated[i].imagePath === "") {
                    updated[i].imagePath = "file:///tmp/cliphist_preview_" + updated[i].id + ".png"
                }
            }
            root.entries = updated
            root.loading = false
        }
    }

    // --- Copy entry back to clipboard ---
    function copyEntry(entryId: string): void {
        copyProc.command = ["bash", "-c", "cliphist decode '" + entryId + "' | wl-copy"]
        copyProc.running = true
    }

    Process {
        id: copyProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) console.warn("ClipboardState: copy failed, exit code", exitCode)
        }
    }

    // --- Delete single entry ---
    function deleteEntry(entryId: string): void {
        deleteProc.command = ["bash", "-c", "cliphist decode '" + entryId + "' | cliphist delete; rm -f '/tmp/cliphist_preview_" + entryId + ".png'"]
        deleteProc.running = true
        // Optimistically remove from list
        root.entries = root.entries.filter(function(e) { return e.id !== entryId })
    }

    Process {
        id: deleteProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("ClipboardState: delete failed, exit code", exitCode)
                root.refresh()
            }
        }
    }

    // --- Clear all history ---
    function clearAll(): void {
        clearProc.running = true
    }

    Process {
        id: clearProc
        command: ["bash", "-c", "cliphist wipe; rm -f /tmp/cliphist_preview_*.png"]
        onExited: {
            root.entries = []
        }
    }

    // Auto-refresh when panel opens
    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            refresh()
        }
    }

}
