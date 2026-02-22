import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property string layoutCode: mainInstance?.currentLayoutCode || "EN"
  readonly property string layoutName: mainInstance?.currentLayoutName || "English (US)"
  readonly property bool showIcon: pluginApi?.pluginSettings?.showIcon ?? pluginApi?.manifest?.metadata?.defaultSettings?.showIcon ?? true

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property real contentWidth: layout.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        visible: root.showIcon
        icon: "keyboard"
        color: Color.mPrimary
        applyUiScale: true
      }

      NText {
        text: root.layoutCode
        color: Color.mOnSurface
        pointSize: root.barFontSize
        font.weight: Font.Medium
        applyUiScale: false
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      TooltipService.show(root, root.layoutName, BarService.getTooltipDirection(root.screenName))
    }

    onExited: {
      TooltipService.hide()
    }

    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (root.mainInstance) {
          root.mainInstance.toggleLayout()
        }
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.toggleLayout") || "Toggle Layout",
        "action": "toggle",
        "icon": "switch-horizontal"
      },
      {
        "label": pluginApi?.tr("menu.settings") || "Widget Settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: function(action) {
      contextMenu.close()
      PanelService.closeContextMenu(screen)

      if (action === "toggle") {
        if (root.mainInstance) {
          root.mainInstance.toggleLayout()
        }
      } else if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest)
      }
    }
  }
}
