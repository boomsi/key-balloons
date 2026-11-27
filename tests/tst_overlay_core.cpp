#include "mouse_feedback.h"
#include "overlay_mouse_client.h"
#include "overlay_placement.h"
#include "process_memory.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <QTranslator>

namespace {
QJsonObject readMessage(QLocalSocket &socket)
{
    return QJsonDocument::fromJson(socket.readLine()).object();
}

QString readEndpoint(QFile &descriptor)
{
    if (!descriptor.open(QIODevice::ReadOnly))
        return {};
    const auto endpoint = QJsonDocument::fromJson(descriptor.readAll()).object().value("endpoint").toString();
    descriptor.close();
    return endpoint;
}
}

class ExampleOverlay : public QObject
{
    Q_OBJECT

public slots:
    void showMouseFeedback(const QString &event) { emit displayed(event); }

signals:
    void displayed(const QString &event);
};

class OverlayCoreTest : public QObject
{
    Q_OBJECT

private slots:
    void reportsMemoryOfThisProcess()
    {
        const auto memory = currentProcessMemoryBytes();
        QVERIFY(memory.has_value());
        QVERIFY(*memory > 0);
    }

    void loadsAllNonEnglishCatalogs()
    {
        for (const auto *locale : {"zh_CN", "zh_TW", "fr", "ja", "ko", "es"}) {
            QTranslator translator;
            QVERIFY2(translator.load(QStringLiteral(":/translations/keyballoons_%1.qm").arg(QString::fromLatin1(locale))), locale);
            QVERIFY(QCoreApplication::installTranslator(&translator));
            const auto settings = QCoreApplication::translate("TrayControls", "Settings…");
            const auto guidance = QCoreApplication::translate("InputMonitoringGuide", "Drag into Input Monitoring");
            QCoreApplication::removeTranslator(&translator);
            QVERIFY(settings != QStringLiteral("Settings…"));
            QVERIFY(guidance != QStringLiteral("Drag into Input Monitoring"));
            QVERIFY(!translator.translate("Main", "Appearance").isEmpty());
            QVERIFY(!translator.translate("WindowsKeyboardMonitor", "Could not start global input monitoring").isEmpty());
        }
        QCOMPARE(QCoreApplication::translate("TrayControls", "Settings…"), QStringLiteral("Settings…"));
    }

    void snapsToNearestWorkArea()
    {
        const QList<QRect> screens{QRect(-1600, 100, 1600, 900), QRect(100, 0, 1920, 1080)};
        QCOMPARE(nearestScreenIndex(QPoint(-30, 400), screens), 0);
        QCOMPARE(nearestScreenIndex(QPoint(85, 400), screens), 1);
        QCOMPARE(nearestScreenIndex(QPoint(100, 100), {}), -1);
        const QRect workArea(100, 24, 1840, 996);
        QCOMPARE(bottomSnapPosition(QRect(500, 180, 142, 35), workArea), QPoint(500, 985));
        QCOMPARE(bottomSnapPosition(QRect(1910, 180, 142, 35), workArea), QPoint(1798, 985));
    }

    void internalAndExternalClientsShareTheProtocol()
    {
        QTemporaryDir directory;
        MouseFeedbackServer server(directory.path());
        QCOMPARE(server.start(), QString());
        QFile descriptor(QDir(directory.path()).filePath(QStringLiteral("mouse-feedback-v1.json")));
        QVERIFY(!descriptor.exists());

        ExampleOverlay overlay;
        QSignalSpy displayed(&overlay, &ExampleOverlay::displayed);
        connectOverlayMouseFeedback(overlay, server.internalEndpoint(), server.internalToken());

        QCOMPARE(server.setExternalEnabled(true), QString());
        const auto endpoint = readEndpoint(descriptor);
        QVERIFY(!endpoint.isEmpty());
        QLocalSocket external;
        external.connectToServer(endpoint);
        QTRY_COMPARE(external.state(), QLocalSocket::ConnectedState);
        external.write("{\"version\":1,\"op\":\"subscribe\"}\n");
        QTRY_VERIFY(external.canReadLine());
        QCOMPARE(readMessage(external).value("op").toString(), QStringLiteral("ok"));

        external.write("{\"version\":1,\"op\":\"publish\",\"event\":\"mouse.right\"}");
        QTest::qWait(10);
        QVERIFY(!external.canReadLine());
        external.write("\n");
        QTRY_VERIFY(external.canReadLine());
        QCOMPARE(readMessage(external).value("op").toString(), QStringLiteral("ok"));
        QTRY_VERIFY(external.canReadLine());
        QCOMPARE(readMessage(external).value("event").toString(), QStringLiteral("mouse.right"));
        QTRY_COMPARE(displayed.size(), 1);
        QCOMPARE(displayed.takeFirst().constFirst().toString(), QStringLiteral("mouse.right"));

        server.publish(MouseFeedback::Wheel);
        QTRY_VERIFY(external.canReadLine());
        QCOMPARE(readMessage(external).value("event").toString(), QStringLiteral("mouse.wheel"));
        QTRY_COMPARE(displayed.size(), 1);
        QCOMPARE(displayed.takeFirst().constFirst().toString(), QStringLiteral("mouse.wheel"));

        QCOMPARE(server.setExternalEnabled(false), QString());
        QVERIFY(!descriptor.exists());
        QTRY_COMPARE(external.state(), QLocalSocket::UnconnectedState);
        server.publish(MouseFeedback::Left);
        QTRY_COMPARE(displayed.size(), 1);
        QCOMPARE(displayed.takeFirst().constFirst().toString(), QStringLiteral("mouse.left"));
        QCOMPARE(server.setExternalEnabled(true), QString());
        QVERIFY(descriptor.exists());
    }

    void rejectsInvalidFrames()
    {
        QTemporaryDir directory;
        MouseFeedbackServer server(directory.path());
        QCOMPARE(server.start(), QString());

        QCOMPARE(server.setExternalEnabled(true), QString());
        QFile descriptor(QDir(directory.path()).filePath(QStringLiteral("mouse-feedback-v1.json")));
        QLocalSocket client;
        client.connectToServer(readEndpoint(descriptor));
        QTRY_COMPARE(client.state(), QLocalSocket::ConnectedState);
        client.write("[]\n{\"version\":3,\"op\":\"subscribe\"}\n"
                     "{\"version\":1,\"op\":\"publish\",\"event\":\"keyboard.a\"}\n");
        for (const auto *code : {"invalid_message", "unsupported_version", "unsupported_event"}) {
            QTRY_VERIFY(client.canReadLine());
            QCOMPARE(readMessage(client).value("code").toString(), QString::fromLatin1(code));
        }
        client.write(QByteArray(513, 'x'));
        QTRY_COMPARE(client.state(), QLocalSocket::UnconnectedState);
    }

    void rejectsUnauthenticatedConnectionsToThePrivateEndpoint()
    {
        QTemporaryDir directory;
        MouseFeedbackServer server(directory.path());
        QCOMPARE(server.start(), QString());

        QLocalSocket client;
        client.connectToServer(server.internalEndpoint());
        QTRY_COMPARE(client.state(), QLocalSocket::ConnectedState);
        client.write("{\"version\":1,\"op\":\"subscribe\"}\n");
        QTRY_COMPARE(client.state(), QLocalSocket::UnconnectedState);
    }
};

QTEST_GUILESS_MAIN(OverlayCoreTest)
#include "tst_overlay_core.moc"
