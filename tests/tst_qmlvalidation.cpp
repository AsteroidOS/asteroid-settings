/*
 * Copyright (C) 2024 - AsteroidOS Contributors
 *
 * QML Validation Test — White Screen Guard
 *
 * This test loads each power-manager QML component using mock modules
 * that mirror the real Nemo.DBus and org.asteroid.controls APIs.
 * If a component fails to load (bad property handlers, missing types,
 * wrong import versions, etc.), the test fails with the exact error
 * string — the same error that would cause a WHITE SCREEN on-device
 * because AsteroidOS evaluates all Component{} declarations at startup.
 *
 * Catches:
 *   - "Cannot assign to non-existent property" (e.g. onServiceAvailableChanged)
 *   - "Type X unavailable" cascading failures
 *   - "module ... version ... is not installed"
 *   - Syntax errors in QML files
 *   - References to types that don't exist in the module
 *
 * Run standalone:
 *   cd asteroid-settings/tests && mkdir build && cd build
 *   cmake .. && make && QT_QPA_PLATFORM=offscreen ./tst_qmlvalidation -v2
 */

#include <QtTest/QtTest>
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlError>
#include <QQuickItem>
#include <QJSValue>
#include <QDir>
#include <QFileInfo>
#include <cstdlib>  // _Exit

// Defined via CMake add_definitions:
//   QML_SOURCE_DIR  — path to asteroid-settings/src/qml/
//   MOCK_QML_DIR    — path to asteroid-settings/tests/mock-qml/

// ── C++ Mock for Nemo.DBus 2.0 "DBus" singleton ──────────────────
// QML property declarations cannot start with uppercase letters, but
// the real Nemo.DBus exposes SystemBus/SessionBus as C++ Q_ENUM values.
// We mirror that here so `DBus.SystemBus` works in loaded QML files.
class MockDBus : public QObject
{
    Q_OBJECT
public:
    enum BusType { SystemBus = 0, SessionBus = 1 };
    Q_ENUM(BusType)
};

// ── C++ Mock for Nemo.DBus 2.0 "DBusInterface" ─────────────────────
// Must be a C++ QObject (matching the real DeclarativeDBusInterface),
// not a QML-defined type, because the QML engine only rejects unknown
// on<Signal> handlers for C++ types. This mock intentionally does NOT
// expose "serviceAvailable", so any QML file that uses
// onServiceAvailableChanged will be caught as an error.
class MockDBusInterface : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int bus READ bus WRITE setBus NOTIFY busChanged)
    Q_PROPERTY(QString service READ service WRITE setService NOTIFY serviceChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString iface READ iface WRITE setIface NOTIFY interfaceChanged)
    Q_PROPERTY(bool signalsEnabled READ signalsEnabled WRITE setSignalsEnabled NOTIFY signalsEnabledChanged)
    Q_PROPERTY(bool propertiesEnabled READ propertiesEnabled WRITE setPropertiesEnabled NOTIFY propertiesEnabledChanged)
    Q_PROPERTY(int status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool watchServiceStatus READ watchServiceStatus WRITE setWatchServiceStatus NOTIFY watchServiceStatusChanged)

public:
    explicit MockDBusInterface(QObject *parent = nullptr) : QObject(parent) {}

    int bus() const { return m_bus; }
    void setBus(int b) { if (m_bus != b) { m_bus = b; emit busChanged(); } }

    QString service() const { return m_service; }
    void setService(const QString &s) { if (m_service != s) { m_service = s; emit serviceChanged(); } }

    QString path() const { return m_path; }
    void setPath(const QString &p) { if (m_path != p) { m_path = p; emit pathChanged(); } }

    QString iface() const { return m_iface; }
    void setIface(const QString &i) { if (m_iface != i) { m_iface = i; emit interfaceChanged(); } }

    bool signalsEnabled() const { return m_signalsEnabled; }
    void setSignalsEnabled(bool e) { if (m_signalsEnabled != e) { m_signalsEnabled = e; emit signalsEnabledChanged(); } }

    bool propertiesEnabled() const { return m_propertiesEnabled; }
    void setPropertiesEnabled(bool e) { if (m_propertiesEnabled != e) { m_propertiesEnabled = e; emit propertiesEnabledChanged(); } }

    int status() const { return 0; }

    bool watchServiceStatus() const { return m_watchServiceStatus; }
    void setWatchServiceStatus(bool w) { if (m_watchServiceStatus != w) { m_watchServiceStatus = w; emit watchServiceStatusChanged(); } }

    // Stubs for methods used in QML
    Q_INVOKABLE void call(const QString &, const QVariantList & = {}) {}
    Q_INVOKABLE void typedCall(const QString &, const QVariantList & = {},
                                const QJSValue & = {}, const QJSValue & = {}) {}
    Q_INVOKABLE QVariant getProperty(const QString &) { return QVariant(); }
    Q_INVOKABLE void setProperty(const QString &, const QVariant &) {}

signals:
    void busChanged();
    void serviceChanged();
    void pathChanged();
    void interfaceChanged();
    void signalsEnabledChanged();
    void propertiesEnabledChanged();
    void statusChanged();
    void watchServiceStatusChanged();

private:
    int m_bus = 0;
    QString m_service;
    QString m_path;
    QString m_iface;
    bool m_signalsEnabled = false;
    bool m_propertiesEnabled = false;
    bool m_watchServiceStatus = false;
};

// ── Test class ──────────────────────────────────────────────────────

class TestQmlValidation : public QObject
{
    Q_OBJECT

private:
    QQmlEngine *m_engine = nullptr;

private slots:
    void initTestCase();
    void cleanupTestCase();

    // Data-driven: one row per power-manager QML file
    void loadPowerManagerPage_data();
    void loadPowerManagerPage();
};

// ── Setup / Teardown ────────────────────────────────────────────────

void TestQmlValidation::initTestCase()
{
    m_engine = new QQmlEngine(); // no parent — _Exit() handles cleanup

    // Add mock import path (takes priority for QML-defined mock types).
    // C++ registered types (MockDBusInterface, MockDBus) take priority
    // over any system-installed Nemo.DBus module, so we don't need to
    // isolate the import paths — addImportPath is sufficient.
    m_engine->addImportPath(QStringLiteral(MOCK_QML_DIR));

    // Register C++ mock for DBus singleton (QML can't declare uppercase enum values)
    qmlRegisterSingletonType<MockDBus>("Nemo.DBus", 2, 0, "DBus",
        [](QQmlEngine *, QJSEngine *) -> QObject * { return new MockDBus; });

    // Register C++ mock for DBusInterface (C++ types strictly reject unknown
    // on<Signal> handlers, unlike QML-defined types which silently accept them)
    qmlRegisterType<MockDBusInterface>("Nemo.DBus", 2, 0, "DBusInterface");

    // Verify the mock path is reachable
    QDir mockDir(QStringLiteral(MOCK_QML_DIR));
    QVERIFY2(mockDir.exists(),
        qPrintable(QString("Mock QML directory not found: %1").arg(mockDir.absolutePath())));

    // Verify we can find the QML source directory
    QDir qmlDir(QStringLiteral(QML_SOURCE_DIR));
    QVERIFY2(qmlDir.exists(),
        qPrintable(QString("QML source directory not found: %1").arg(qmlDir.absolutePath())));
}

void TestQmlValidation::cleanupTestCase()
{
    // Don't delete m_engine here — it crashes during Qt's QML type system
    // cleanup when C++ types were registered via qmlRegisterType.
    // The engine will be cleaned up by _Exit() in main().
    m_engine = nullptr;
}

// ── Main test: load each power-manager QML page ─────────────────────

void TestQmlValidation::loadPowerManagerPage_data()
{
    QTest::addColumn<QString>("qmlFile");
    QTest::addColumn<QString>("fileName");

    // These are the QML pages we added for the power manager feature.
    // If any of them fails to load, the ENTIRE settings app shows a white screen
    // because main.qml pre-evaluates Component{} blocks.
    static const QStringList powerManagerFiles = {
        QStringLiteral("PowerManagerPage.qml"),
        QStringLiteral("ProfileSelectorPage.qml"),
        QStringLiteral("ProfileListPage.qml"),
        QStringLiteral("ProfileEditPage.qml"),
        QStringLiteral("AutomationEditPage.qml"),
    };

    QDir qmlDir(QStringLiteral(QML_SOURCE_DIR));
    for (const QString &file : powerManagerFiles) {
        QString path = qmlDir.absoluteFilePath(file);
        QVERIFY2(QFile::exists(path),
            qPrintable(QString("QML file not found: %1").arg(path)));
        QTest::newRow(qPrintable(file)) << path << file;
    }
}

void TestQmlValidation::loadPowerManagerPage()
{
    QFETCH(QString, qmlFile);
    QFETCH(QString, fileName);

    QQmlComponent component(m_engine, QUrl::fromLocalFile(qmlFile));

    if (component.isError()) {
        QString errors;
        for (const QQmlError &e : component.errors())
            errors += QString("  %1:%2 — %3\n")
                .arg(e.url().fileName())
                .arg(e.line())
                .arg(e.description());

        QFAIL(qPrintable(
            QString("\n"
                    "╔══════════════════════════════════════════════════════════╗\n"
                    "║  WHITE SCREEN DETECTED — QML component failed to load  ║\n"
                    "╚══════════════════════════════════════════════════════════╝\n"
                    "\n"
                    "  File: %1\n"
                    "\n"
                    "  This error will make the ENTIRE settings app show a\n"
                    "  blank white screen on-device because AsteroidOS\n"
                    "  evaluates all Component{} declarations at startup.\n"
                    "\n"
                    "  Errors:\n%2")
                .arg(fileName, errors)));
    }

    QCOMPARE(component.status(), QQmlComponent::Ready);
}

// ── Main ────────────────────────────────────────────────────────────

int main(int argc, char *argv[])
{
    // QGuiApplication is required because QML visual types (Item, etc.)
    // need it even though we never render anything.
    QGuiApplication app(argc, argv);
    TestQmlValidation tc;
    int result = QTest::qExec(&tc, argc, argv);
    // Use _Exit() to bypass Qt's QML type system cleanup, which crashes
    // when C++ types registered via qmlRegisterType are cleaned up in
    // unit test processes.  All test assertions above have already run.
    _Exit(result);
}

#include "tst_qmlvalidation.moc"
