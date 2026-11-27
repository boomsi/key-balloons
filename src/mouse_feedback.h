#pragma once

#include <QHash>
#include <QCoreApplication>
#include <QLocalServer>
#include <QLockFile>
#include <QMetaType>
#include <QTemporaryDir>

#include <optional>

class QJsonObject;
class QLocalSocket;

enum class MouseFeedback { Left, Right, Wheel };
Q_DECLARE_METATYPE(MouseFeedback)

namespace MouseFeedbackProtocol {
constexpr int version = 1;
constexpr int maxFrameSize = 512;

QString eventName(MouseFeedback feedback);
std::optional<MouseFeedback> eventFromName(QStringView name);
QByteArray frame(QJsonObject message);
}

class MouseFeedbackServer final : public QObject
{
    Q_DECLARE_TR_FUNCTIONS(MouseFeedbackServer)

public:
    explicit MouseFeedbackServer(const QString &discoveryDirectory);
    ~MouseFeedbackServer() override;

    QString start();
    QString internalEndpoint() const;
    const QString &internalToken() const;
    QString setExternalEnabled(bool enabled);
    void publish(MouseFeedback feedback);

private:
    struct Client {
        bool external = false;
        bool subscribed = false;
    };

    QString endpoint(const QString &name) const;
    QString enableExternal();
    QString disableExternal();
    void acceptConnections(QLocalServer &server, bool external);
    void readFrames(QLocalSocket &socket);
    void handleMessage(QLocalSocket &socket, const QByteArray &line);

    QString discoveryDirectory_;
    QString descriptorPath_;
    QLockFile externalLock_;
    QTemporaryDir socketDirectory_;
    QString internalToken_;
    QHash<QLocalSocket *, Client> clients_;
    QLocalServer internal_;
    QLocalServer external_;
};
