#pragma once

#include <QObject>
#include <QSettings>
#include <QVariantList>

#include <memory>

class MouseFeedbackServer;
class OverlayPlacement;
class QQmlEngine;
class QTranslator;

class AppPreferences final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool autoSnapToBottom READ autoSnapToBottom WRITE setAutoSnapToBottom NOTIFY autoSnapToBottomChanged)
    Q_PROPERTY(bool integrationsEnabled READ integrationsEnabled WRITE setIntegrationsEnabled NOTIFY integrationsEnabledChanged)
    Q_PROPERTY(bool integrationsAvailable READ integrationsAvailable CONSTANT)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QVariantList languages READ languages CONSTANT)

public:
    AppPreferences(QQmlEngine &engine, OverlayPlacement &placement, MouseFeedbackServer &feedback);
    ~AppPreferences() override;

    bool autoSnapToBottom() const;
    void setAutoSnapToBottom(bool enabled);
    bool integrationsAvailable() const;
    bool integrationsEnabled() const;
    void setIntegrationsEnabled(bool enabled);
    QString language() const;
    void setLanguage(const QString &code);
    QVariantList languages() const;

signals:
    void autoSnapToBottomChanged();
    void integrationsEnabledChanged();
    void languageChanged();

private:
    QQmlEngine &engine_;
    OverlayPlacement &placement_;
    MouseFeedbackServer &feedback_;
    QSettings storage_;
    std::unique_ptr<QTranslator> translator_;
    bool autoSnapToBottom_ = false;
    bool integrationsEnabled_ = false;
    QString language_ = QStringLiteral("en");
};
