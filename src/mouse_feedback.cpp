#include "mouse_feedback.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QSaveFile>
#include <QUuid>

using namespace Qt::StringLiterals;

namespace {
constexpr int maxClients = 16;
constexpr int maxPendingOutput = 16 * 1024;

QString socketDirectoryTemplate()
{
#ifdef Q_OS_MACOS
    // Unix socket paths have a smaller limit than ordinary file paths.
    return u"/tmp/kb-XXXXXX"_s;
#else
    return QDir::temp().filePath(u"kb-XXXXXX"_s);
#endif
}

void sendFrame(QLocalSocket &socket, const QByteArray &frame)
{
    if (socket.bytesToWrite() + frame.size() > maxPendingOutput || socket.write(frame) != frame.size())
        socket.abort();
}

void sendError(QLocalSocket &socket, const QString &code)
{
    sendFrame(socket, MouseFeedbackProtocol::frame({{u"op"_s, u"error"_s}, {u"code"_s, code}}));
}
}

QString MouseFeedbackProtocol::eventName(MouseFeedback feedback)
{
    switch (feedback) {
    case MouseFeedback::Left: return u"mouse.left"_s;
    case MouseFeedback::Right: return u"mouse.right"_s;
    case MouseFeedback::Wheel: return u"mouse.wheel"_s;
    }
    return {};
}

std::optional<MouseFeedback> MouseFeedbackProtocol::eventFromName(QStringView name)
{
    for (const auto feedback : {MouseFeedback::Left, MouseFeedback::Right, MouseFeedback::Wheel}) {
        if (name == eventName(feedback))
            return feedback;
    }
    return std::nullopt;
}

QByteArray MouseFeedbackProtocol::frame(QJsonObject message)
{
    message.insert(u"version"_s, version);
    return QJsonDocument(message).toJson(QJsonDocument::Compact) + '\n';
}

MouseFeedbackServer::MouseFeedbackServer(const QString &discoveryDirectory)
    : discoveryDirectory_(discoveryDirectory),
      descriptorPath_(QDir(discoveryDirectory).filePath(u"mouse-feedback-v1.json"_s)),
      externalLock_(descriptorPath_ + u".lock"_s), socketDirectory_(socketDirectoryTemplate()),
      internalToken_(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    externalLock_.setStaleLockTime(0);
    for (auto *server : {&internal_, &external_})
        server->setSocketOptions(QLocalServer::UserAccessOption);

    connect(&internal_, &QLocalServer::newConnection, this, [this] { acceptConnections(internal_, false); });
    connect(&external_, &QLocalServer::newConnection, this, [this] { acceptConnections(external_, true); });
}

MouseFeedbackServer::~MouseFeedbackServer()
{
    const auto error = disableExternal();
    if (!error.isEmpty())
        qWarning().noquote() << error;
    internal_.close();
    for (auto *socket : clients_.keys())
        socket->abort();
}

QString MouseFeedbackServer::endpoint(const QString &name) const
{
#ifdef Q_OS_WIN
    return u"key-balloons-%1-%2-%3"_s.arg(QCoreApplication::applicationPid())
        .arg(QFileInfo(socketDirectory_.path()).fileName(), name);
#else
    return QDir(socketDirectory_.path()).filePath(name);
#endif
}

QString MouseFeedbackServer::start()
{
    if (!socketDirectory_.isValid())
        return tr("Could not create the mouse feedback socket directory: %1").arg(socketDirectory_.errorString());
    if (!internal_.listen(endpoint(u"overlay"_s)))
        return tr("Could not start the mouse feedback server: %1").arg(internal_.errorString());
    return {};
}

QString MouseFeedbackServer::internalEndpoint() const
{
    return internal_.fullServerName();
}

const QString &MouseFeedbackServer::internalToken() const
{
    return internalToken_;
}

QString MouseFeedbackServer::setExternalEnabled(bool enabled)
{
    return enabled ? enableExternal() : disableExternal();
}

QString MouseFeedbackServer::enableExternal()
{
    if (external_.isListening())
        return {};
    if (!internal_.isListening())
        return tr("The mouse feedback server is unavailable.");
    if (discoveryDirectory_.isEmpty() || !QDir().mkpath(discoveryDirectory_))
        return tr("Could not create the integration directory: %1").arg(discoveryDirectory_);
    if (!externalLock_.tryLock())
        return tr("Could not lock the integration endpoint. Close any other Key Balloons instance using it.");

    if (!external_.listen(endpoint(u"feedback"_s))) {
        externalLock_.unlock();
        return tr("Could not start local mouse integration: %1").arg(external_.errorString());
    }

    QSaveFile descriptor(descriptorPath_);
    const auto data = MouseFeedbackProtocol::frame({{u"endpoint"_s, external_.fullServerName()}});
    if (!descriptor.open(QIODevice::WriteOnly) || descriptor.write(data) != data.size() || !descriptor.commit()) {
        external_.close();
        externalLock_.unlock();
        return tr("Could not write the integration endpoint: %1").arg(descriptor.errorString());
    }
    return {};
}

QString MouseFeedbackServer::disableExternal()
{
    if (!externalLock_.isLocked())
        return {};

    external_.close();
    for (auto *socket : clients_.keys()) {
        if (clients_.value(socket).external)
            socket->abort();
    }
    QFile descriptor(descriptorPath_);
    const bool removed = !descriptor.exists() || descriptor.remove();
    externalLock_.unlock();
    return removed ? QString() : tr("Could not remove the integration endpoint: %1").arg(descriptor.errorString());
}

void MouseFeedbackServer::acceptConnections(QLocalServer &server, bool external)
{
    while (auto *socket = server.nextPendingConnection()) {
        if (clients_.size() >= maxClients) {
            socket->abort();
            socket->deleteLater();
            continue;
        }
        clients_.insert(socket, {external});
        socket->setReadBufferSize(MouseFeedbackProtocol::maxFrameSize + 1);
        connect(socket, &QLocalSocket::disconnected, this, [this, socket] {
            clients_.remove(socket);
            socket->deleteLater();
        });
        connect(socket, &QLocalSocket::readyRead, this, [this, socket] { readFrames(*socket); });
        readFrames(*socket);
    }
}

void MouseFeedbackServer::readFrames(QLocalSocket &socket)
{
    while (socket.canReadLine()) {
        const auto line = socket.readLine();
        if (line.size() > MouseFeedbackProtocol::maxFrameSize) {
            socket.abort();
            return;
        }
        handleMessage(socket, line);
        if (socket.state() != QLocalSocket::ConnectedState)
            return;
    }
    if (socket.bytesAvailable() >= MouseFeedbackProtocol::maxFrameSize)
        socket.abort();
}

void MouseFeedbackServer::handleMessage(QLocalSocket &socket, const QByteArray &line)
{
    const auto document = QJsonDocument::fromJson(line);
    if (!document.isObject()) {
        sendError(socket, u"invalid_message"_s);
        return;
    }
    const auto message = document.object();
    if (!clients_.value(&socket).external && message.value(u"token"_s).toString() != internalToken_) {
        socket.abort();
        return;
    }
    if (message.value(u"version"_s).toInt(-1) != MouseFeedbackProtocol::version) {
        sendError(socket, u"unsupported_version"_s);
        return;
    }

    const auto operation = message.value(u"op"_s).toString();
    const auto reply = MouseFeedbackProtocol::frame({{u"op"_s, u"ok"_s}, {u"request"_s, operation}});
    if (operation == u"subscribe") {
        clients_[&socket].subscribed = true;
        sendFrame(socket, reply);
    } else if (operation == u"publish") {
        const auto event = MouseFeedbackProtocol::eventFromName(message.value(u"event"_s).toString());
        if (!event) {
            sendError(socket, u"unsupported_event"_s);
            return;
        }
        sendFrame(socket, reply);
        publish(*event);
    } else {
        sendError(socket, u"unsupported_operation"_s);
    }
}

void MouseFeedbackServer::publish(MouseFeedback feedback)
{
    const auto notice = MouseFeedbackProtocol::frame({{u"op"_s, u"event"_s},
        {u"event"_s, MouseFeedbackProtocol::eventName(feedback)}});
    for (auto *socket : clients_.keys()) {
        if (clients_.value(socket).subscribed)
            sendFrame(*socket, notice);
    }
}
