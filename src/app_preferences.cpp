#include "app_preferences.h"

#include "mouse_feedback.h"
#include "overlay_placement.h"

#include <QCoreApplication>
#include <QLocale>
#include <QMessageBox>
#include <QQmlEngine>
#include <QTranslator>

#include <algorithm>
#include <array>

using namespace Qt::StringLiterals;

namespace {
struct Language {
    QLatin1StringView code;
    QStringView label;
};

constexpr std::array supportedLanguages{
    Language{"en"_L1, u"English"},
    Language{"zh_CN"_L1, u"简体中文"},
    Language{"zh_TW"_L1, u"繁體中文"},
    Language{"fr"_L1, u"Français"},
    Language{"ja"_L1, u"日本語"},
    Language{"ko"_L1, u"한국어"},
    Language{"es"_L1, u"Español"},
};
}

AppPreferences::AppPreferences(QQmlEngine &engine, OverlayPlacement &placement, MouseFeedbackServer &feedback)
    : engine_(engine), placement_(placement), feedback_(feedback), storage_(u"KeyBalloons"_s, u"KeyBalloons"_s),
      autoSnapToBottom_(storage_.value(u"autoSnapToBottom"_s, false).toBool())
{
    QLocale::setDefault(QLocale(QLocale::English));
    placement_.setSnapEnabled(autoSnapToBottom_);
    setLanguage(storage_.value(u"language"_s, language_).toString());
}

AppPreferences::~AppPreferences()
{
    if (translator_)
        QCoreApplication::removeTranslator(translator_.get());
}

bool AppPreferences::autoSnapToBottom() const
{
    return autoSnapToBottom_;
}

void AppPreferences::setAutoSnapToBottom(bool enabled)
{
    if (autoSnapToBottom_ == enabled)
        return;
    autoSnapToBottom_ = enabled;
    storage_.setValue(u"autoSnapToBottom"_s, enabled);
    emit autoSnapToBottomChanged();
    placement_.setSnapEnabled(enabled);
}

bool AppPreferences::integrationsAvailable() const
{
    return !feedback_.internalEndpoint().isEmpty();
}

bool AppPreferences::integrationsEnabled() const
{
    return integrationsEnabled_;
}

void AppPreferences::setIntegrationsEnabled(bool enabled)
{
    if (integrationsEnabled_ == enabled)
        return;
    const auto error = feedback_.setExternalEnabled(enabled);
    integrationsEnabled_ = enabled && error.isEmpty();
    emit integrationsEnabledChanged();
    if (!error.isEmpty())
        QMessageBox::warning(nullptr, tr("Local mouse integrations"), error);
}

QString AppPreferences::language() const
{
    return language_;
}

void AppPreferences::setLanguage(const QString &code)
{
    if (language_ == code || std::none_of(supportedLanguages.begin(), supportedLanguages.end(),
            [&code](const Language &entry) { return code == entry.code; }))
        return;

    std::unique_ptr<QTranslator> replacement;
    if (code != u"en") {
        replacement = std::make_unique<QTranslator>();
        if (!replacement->load(u":/translations/keyballoons_%1.qm"_s.arg(code))) {
            qWarning().noquote() << "Could not load Key Balloons translations for" << code;
            return;
        }
    }

    if (translator_)
        QCoreApplication::removeTranslator(translator_.get());
    translator_ = std::move(replacement);
    if (translator_)
        QCoreApplication::installTranslator(translator_.get());

    language_ = code;
    QLocale::setDefault(QLocale(code));
    storage_.setValue(u"language"_s, code);
    engine_.retranslate();
    emit languageChanged();
}

QVariantList AppPreferences::languages() const
{
    QVariantList entries;
    for (const auto &language : supportedLanguages)
        entries.append(QVariantMap{{u"code"_s, QString(language.code)}, {u"label"_s, language.label.toString()}});
    return entries;
}
