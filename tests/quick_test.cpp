#include <QtQuickTest/quicktest.h>
#include <QtEnvironmentVariables>

int main(int argc, char *argv[])
{
    qputenv("QSG_USE_SIMPLE_ANIMATION_DRIVER", "1");
    return quick_test_main(argc, argv, "key_balloons", nullptr);
}
