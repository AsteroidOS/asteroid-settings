// Mock DBusInterface for QML validation tests.
// Mirrors the real Nemo.DBus 2.0 DBusInterface properties.
// Intentionally does NOT expose "serviceAvailable" — if any QML file
// uses onServiceAvailableChanged inside this element, the test will
// fail with "Cannot assign to non-existent property", exactly as it
// does on the real device.
import QtQuick 2.9

Item {
    property int bus: 0
    property string service: ""
    property string path: ""
    property string iface: ""
    property bool signalsEnabled: false
    property bool propertiesEnabled: false

    // Real Nemo.DBus exposes these:
    property int status: 0  // DeclarativeDBusInterface::Unknown
    property bool watchServiceStatus: false

    function call(method, args) {}
    function typedCall(method, args, successCallback, errorCallback) {}
    function getProperty(name) { return undefined }
    function setProperty(name, value) {}
}
