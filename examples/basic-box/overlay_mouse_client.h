#pragma once

class QObject;
class QString;

void connectOverlayMouseFeedback(QObject &overlay, const QString &endpoint, const QString &token);
