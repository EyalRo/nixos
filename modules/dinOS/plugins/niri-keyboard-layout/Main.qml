import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  IpcHandler {
    target: "plugin:niri-keyboard-layout"
    function toggle() {
      root.toggleLayout()
    }
  }

  property int currentLayoutIndex: 0
  property string currentLayoutName: "English (US)"
  property string currentLayoutCode: "EN"
  property int layoutCount: 2

  readonly property var layoutCodes: pluginApi?.pluginSettings?.layoutCodes || pluginApi?.manifest?.metadata?.defaultSettings?.layoutCodes || {
    "English (US)": "EN",
    "Hebrew": "HE"
  }

  function getLayoutCode(name) {
    return root.layoutCodes[name] || name.substring(0, 2).toUpperCase()
  }

  Process {
    id: layoutQuery
    running: false

    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (trimmed.startsWith("*")) {
          var match = trimmed.match(/^\*\s*(\d+)\s+(.+)$/)
          if (match) {
            root.currentLayoutIndex = parseInt(match[1])
            root.currentLayoutName = match[2].trim()
            root.currentLayoutCode = root.getLayoutCode(root.currentLayoutName)
          }
        }
      }
    }
  }

  Process {
    id: layoutListQuery
    running: false

    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (trimmed.match(/^\d+/)) {
          root.layoutCount++
        }
      }
    }

    onExited: {
      if (root.layoutCount < 1) root.layoutCount = 2
    }
  }

  Timer {
    id: pollTimer
    interval: 500
    running: true
    repeat: true
    onTriggered: {
      layoutQuery.running = true
    }
  }

  function toggleLayout() {
    var nextIndex = (root.currentLayoutIndex + 1) % root.layoutCount
    Quickshell.execDetached(["niri", "msg", "action", "switch-layout", nextIndex.toString()])
    root.currentLayoutIndex = nextIndex
    layoutQuery.running = true
  }

  function refresh() {
    root.layoutCount = 0
    layoutListQuery.running = true
    layoutQuery.running = true
  }

  Component.onCompleted: {
    layoutListQuery.command = ["niri", "msg", "keyboard-layouts"]
    layoutQuery.command = ["niri", "msg", "keyboard-layouts"]
    root.refresh()
  }
}
