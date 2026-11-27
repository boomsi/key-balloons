#include "overlay_mouse_client.h"

#include "mouse_feedback.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>

using namespace Qt::StringLiterals;

void connectOverlayMouseFeedback(QObject &overlay, const QString &endpoint, const QString &token)
{
    auto *socket = new QLocalSocket(&overlay);
    QObject::connect(socket, &QLocalSocket::connected, socket, [socket, token] {
        const auto request = MouseFeedbackProtocol::frame({{u"op"_s, u"subscribe"_s}, {u"token"_s, token}});
        if (socket->write(request) != request.size())
            qWarning().noquote() << "Could not subscribe the overlay to mouse feedback:" << socket->errorString();
    });
    QObject::connect(socket, &QLocalSocket::readyRead, &overlay, [&overlay, socket] {
        while (socket->canReadLine()) {
            const auto message = QJsonDocument::fromJson(socket->readLine()).object();
            if (message.value(u"version"_s).toInt() != MouseFeedbackProtocol::version
                || message.value(u"op"_s).toString() != u"event") {
                continue;
            }
            const auto event = message.value(u"event"_s).toString();
            if (MouseFeedbackProtocol::eventFromName(event))
                QMetaObject::invokeMethod(&overlay, "showMouseFeedback", Q_ARG(QString, event));
        }
    });
    QObject::connect(socket, &QLocalSocket::errorOccurred, socket, [socket](QLocalSocket::LocalSocketError error) {
        if (error != QLocalSocket::PeerClosedError)
            qWarning().noquote() << "The overlay mouse feedback connection failed:" << socket->errorString();
    });
    socket->connectToServer(endpoint);
}
